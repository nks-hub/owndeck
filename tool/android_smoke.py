"""Run candidate-app smoke checks on one explicit ADB device."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import msvcrt
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET


class Blocked(Exception):
    pass


def checksum(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


class Device:
    def __init__(self, config):
        self.config = config
        self.package = "com.nkshub.nextclouddeck.candidate"
        self.output = Path(config["outputRoot"])

    def adb(self, *args, timeout=20, check=True):
        result = subprocess.run(
            [self.config["adbPath"], "-s", self.config["serial"], *args],
            capture_output=True, timeout=timeout,
        )
        if check and result.returncode:
            raise RuntimeError(f"adb_{args[0]}_failed")
        return result

    def text(self, *args, **kwargs):
        return self.adb(*args, **kwargs).stdout.decode("utf-8", errors="replace").strip()

    def focused(self):
        activities = self.text("shell", "dumpsys", "activity", "activities")
        return any(
            self.package + "/" in line
            for line in activities.splitlines()
            if "mResumedActivity" in line or "topResumedActivity" in line
        )

    def launch(self):
        self.adb("shell", "input", "keyevent", "KEYCODE_WAKEUP")
        self.adb("shell", "wm", "dismiss-keyguard", check=False)
        self.adb("shell", "am", "start", "-W", "-n", f"{self.package}/com.nkshub.nextclouddeck.MainActivity", timeout=40)
        time.sleep(3)
        if not self.focused():
            raise Blocked("candidate_not_foreground_or_device_locked")

    def hierarchy(self, name):
        if not self.focused():
            raise Blocked("candidate_lost_foreground")
        self.adb("shell", "uiautomator", "dump", "/sdcard/owndeck-smoke.xml", timeout=30)
        raw = self.adb("exec-out", "cat", "/sdcard/owndeck-smoke.xml").stdout
        root = ET.fromstring(raw)
        (self.output / f"{name}.xml").write_bytes(raw)
        return root

    def screenshot(self, name):
        if self.focused():
            (self.output / f"{name}.png").write_bytes(self.adb("exec-out", "screencap", "-p").stdout)

    @staticmethod
    def labels(root):
        return "\n".join(node.get(key, "") for node in root.iter("node") for key in ("text", "content-desc"))

    def tap(self, node):
        if not self.focused():
            raise Blocked("candidate_lost_foreground")
        bounds = [int(value) for value in re.findall(r"\d+", node.get("bounds", ""))]
        if len(bounds) != 4 or bounds[2] <= bounds[0] or bounds[3] <= bounds[1]:
            raise RuntimeError("invalid_touch_bounds")
        self.adb("shell", "input", "tap", str((bounds[0] + bounds[2]) // 2), str((bounds[1] + bounds[3]) // 2))

    def logs(self):
        pid = self.text("shell", "pidof", self.package, check=False).split()
        if not pid:
            raise RuntimeError("candidate_process_exited")
        logs = self.text("logcat", "-d", f"--pid={pid[0]}", "-v", "brief", "flutter:V", "AndroidRuntime:E", "*:S")
        (self.output / "app-logcat.txt").write_text(logs, encoding="utf-8")
        if re.search(r"FATAL EXCEPTION|Unhandled Exception|EXCEPTION CAUGHT BY|A RenderFlex overflowed", logs):
            raise RuntimeError("runtime_error_in_logcat")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    config = json.loads(Path(parser.parse_args().config).read_text(encoding="utf-8-sig"))
    output = Path(config["outputRoot"])
    output.mkdir(parents=True, exist_ok=True)
    result = {
        "pid": os.getpid(), "device": config["deviceName"], "revision": config["revision"],
        "harnessRevision": config.get("harnessRevision"),
        "harnessSha256": checksum(Path(__file__)), "startedUtc": datetime.now(timezone.utc).isoformat(),
        "status": "running", "phase": "waiting_build", "checks": [],
    }

    def save():
        temporary = output / "result.tmp"
        temporary.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        temporary.replace(output / "result.json")

    save()
    lock = None
    locked = False
    device = Device(config)
    exit_code = 1
    try:
        deadline = time.monotonic() + 1200
        build_path = Path(config["buildResult"])
        while not build_path.exists() and time.monotonic() < deadline:
            time.sleep(2)
        if not build_path.exists():
            raise Blocked("build_wait_timeout")
        build = json.loads(build_path.read_text(encoding="utf-8-sig"))
        if build["exitCode"] != 0:
            raise Blocked("build_failed")
        if build["revision"] != config["revision"] or build["applicationId"] != device.package:
            raise RuntimeError("unexpected_build_identity")
        apk = Path(build["apk"])
        if checksum(apk) != build["sha256"]:
            raise RuntimeError("apk_checksum_changed")
        result["apkSha256"] = build["sha256"]
        result["buildMode"] = build["buildMode"]
        lock_root = Path(config["lockRoot"])
        lock_root.mkdir(parents=True, exist_ok=True)
        lock = (lock_root / f"{config['deviceName']}.lock").open("a+b")
        lock.seek(0)
        try:
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
            locked = True
        except OSError as error:
            raise Blocked("device_busy") from error
        result["phase"] = "device"
        save()
        if device.text("get-state", check=False) != "device":
            raise Blocked("device_not_authorized_or_offline")
        result["model"] = device.text("shell", "getprop", "ro.product.model")
        result["android"] = device.text("shell", "getprop", "ro.build.version.release")
        if result["model"] != config["expectedModel"]:
            raise Blocked("unexpected_device_model")
        install = device.adb("install", "-r", "-t", str(apk), timeout=180, check=False)
        (output / "install.txt").write_bytes(install.stdout + install.stderr)
        if install.returncode != 0 or b"Success" not in install.stdout:
            raise Blocked("install_failed_without_removing_existing_data")
        result["checks"].append({"name": "candidate_install", "status": "passed"})
        device.adb("shell", "am", "force-stop", device.package)
        device.launch()
        tree = device.hierarchy("launch")
        labels = device.labels(tree)
        device.screenshot("launch")
        if "Připojit Nextcloud" not in labels and "Connect Nextcloud" not in labels:
            raise RuntimeError("expected_login_screen_missing")
        result["checks"].append({"name": "cold_start_login_screen", "status": "passed"})
        field = next((node for node in tree.iter("node") if node.get("class") == "android.widget.EditText"), None)
        if field is None:
            raise RuntimeError("server_input_missing")
        device.tap(field)
        time.sleep(1)
        device.adb("shell", "input", "text", "http://invalid.example")
        time.sleep(0.3)
        entered = device.hierarchy("entered-input")
        value = next((node.get("text", "") for node in entered.iter("node") if node.get("class") == "android.widget.EditText"), None)
        if value != "http://invalid.example":
            raise Blocked("test_input_not_delivered_exactly")
        device.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        tree = device.hierarchy("invalid-input")
        button = next((node for node in tree.iter("node") if node.get("text") in ("Připojit", "Connect") or node.get("content-desc") in ("Připojit", "Connect")), None)
        if button is None:
            raise RuntimeError("connect_button_missing")
        device.tap(button)
        time.sleep(1)
        labels = device.labels(device.hierarchy("validation"))
        device.screenshot("validation")
        if "Zadejte platnou HTTPS" not in labels and "Enter a valid Nextcloud HTTPS" not in labels:
            raise RuntimeError("invalid_http_url_not_rejected_in_ui")
        result["checks"].append({"name": "invalid_http_url_validation", "status": "passed"})
        device.logs()
        result["checks"].append({"name": "no_startup_runtime_errors", "status": "passed"})
        result["status"] = "passed"
        exit_code = 0
    except Blocked as error:
        result["status"] = "blocked"
        result["reason"] = str(error)
        exit_code = 2
    except (RuntimeError, subprocess.TimeoutExpired, ET.ParseError, OSError, ValueError) as error:
        result["status"] = "failed"
        result["reason"] = str(error) if isinstance(error, RuntimeError) else type(error).__name__
        try:
            device.screenshot("failure")
            device.logs()
        except (RuntimeError, subprocess.TimeoutExpired, OSError):
            # Diagnostics must not replace the original failure.
            pass
    finally:
        if lock is not None:
            if locked:
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
            lock.close()
        result["finishedUtc"] = datetime.now(timezone.utc).isoformat()
        save()
    print(json.dumps({key: result.get(key) for key in ("device", "revision", "status", "reason", "checks")}, ensure_ascii=False))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
