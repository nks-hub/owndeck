#!/usr/bin/env python3
"""Run the pinned Nextcloud fixture on a GitHub-hosted Linux runner."""

import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import ssl
import subprocess
import sys
import tarfile
import time
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET


IMAGE = "nextcloud:35.0.2-apache@sha256:89af7ee7a96ff5e9668280566209268ae6b2d02327f6ef6d56f6d68228cf9431"
NEXTCLOUD_VERSION = "35.0.2"
DECK_VERSION = "1.19.1"
DECK_URL = "https://github.com/nextcloud-releases/deck/releases/download/v1.19.1/deck-v1.19.1.tar.gz"
DECK_SHA256 = "382e11139ee399444bdfa17f018aa9109376928f9bd36090ead8ea340b4d3f0e"
LABEL = "org.owndeck.compatibility-run"


class CommandFailed(Exception):
    def __init__(self, phase, code):
        self.phase = phase
        self.code = code


def command(arguments, phase, *, stdin=None, timeout=120):
    result = subprocess.run(arguments, input=stdin, capture_output=True,
                            text=True, encoding="utf-8", timeout=timeout)
    if result.returncode:
        raise CommandFailed(phase, result.returncode)
    return result.stdout


def paths():
    if (os.name != "posix" or os.environ.get("GITHUB_ACTIONS") != "true"
            or os.environ.get("COMPAT_RUNNER_ENV") != "github-hosted"
            or os.environ.get("GITHUB_EVENT_NAME") != "workflow_dispatch"
            or os.environ.get("GITHUB_REPOSITORY") != "nks-hub/owndeck"):
        raise RuntimeError("github_hosted_manual_project_run_required")
    run = os.environ["GITHUB_RUN_ID"] + "-" + os.environ["GITHUB_RUN_ATTEMPT"]
    if not re.fullmatch(r"\d+-\d+", run):
        raise RuntimeError("invalid_run_identity")
    temporary = Path(os.environ["RUNNER_TEMP"]).resolve()
    private = temporary / ("owndeck-compat-" + run)
    report = temporary / ("owndeck-compat-report-" + run)
    return run, private, report


def save(path, data):
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def mask(value):
    print("::add-mask::" + value, flush=True)
    return value


def occ(container, arguments, *, password=None):
    base = ["docker", "exec", "-i", "--user", "www-data", container]
    if password is None:
        return command(base + ["php", "occ", *arguments], "occ_" + arguments[0])
    return command(base + ["sh", "-c",
        'IFS= read -r OC_PASS; export OC_PASS; exec php occ "$@"',
        "occ", *arguments], "occ_" + arguments[0], stdin=password + "\n")


def inspect_owned(container, run):
    raw = command(["docker", "inspect", "--format", "{{json .Config.Labels}}", container],
                  "inspect_container")
    if json.loads(raw).get(LABEL) != run:
        raise RuntimeError("container_ownership_mismatch")


def prepare(run, private, report):
    if private.exists():
        raise RuntimeError("fixture_directory_already_exists")
    private.mkdir(mode=0o700)
    report.mkdir(mode=0o700)
    container = "owndeck-compat-" + run
    save(private / "owner.json", {"run": run, "container": container})
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env:
        env.write(f"COMPAT_CONFIG={private / 'credentials.json'}\n")
        env.write(f"COMPAT_REPORT={report}\n")

    print("Downloading pinned Deck release", flush=True)
    archive = private / "deck.tar.gz"
    digest = hashlib.sha256()
    with urllib.request.urlopen(DECK_URL, timeout=60) as response, archive.open("wb") as output:
        total = 0
        while chunk := response.read(1024 * 1024):
            total += len(chunk)
            if total > 100 * 1024 * 1024:
                raise RuntimeError("deck_archive_too_large")
            digest.update(chunk)
            output.write(chunk)
    if digest.hexdigest() != DECK_SHA256:
        raise RuntimeError("deck_archive_digest_mismatch")
    app = private / "app"
    app.mkdir()
    with tarfile.open(archive) as package:
        if any(Path(item.name).parts[0] != "deck" for item in package.getmembers()):
            raise RuntimeError("unexpected_archive_root")
        package.extractall(app, filter="data")
    info = ET.parse(app / "deck/appinfo/info.xml").getroot()
    dependency = info.find("dependencies/nextcloud")
    if (info.findtext("id") != "deck" or info.findtext("version") != DECK_VERSION
            or dependency is None or dependency.get("min-version") != "35"
            or dependency.get("max-version") != "35"):
        raise RuntimeError("deck_version_or_dependency_mismatch")

    print("Starting isolated Nextcloud with SQLite", flush=True)
    admin_password = mask(secrets.token_urlsafe(36))
    env_file = private / "container.env"
    env_file.write_text("\n".join([
        "SQLITE_DATABASE=compatibility", "NEXTCLOUD_ADMIN_USER=qa-admin",
        "NEXTCLOUD_ADMIN_PASSWORD=" + admin_password,
        "NEXTCLOUD_TRUSTED_DOMAINS=localhost 127.0.0.1", "PHP_MEMORY_LIMIT=512M",
        "PHP_UPLOAD_LIMIT=10M", "NEXTCLOUD_INIT_HTACCESS=true", "",
    ]), encoding="utf-8")
    env_file.chmod(0o600)
    html = private / "html"
    html.mkdir()
    command(["docker", "pull", "--platform", "linux/amd64", IMAGE], "pull_image", timeout=600)
    digests = json.loads(command(["docker", "image", "inspect", "--format", "{{json .RepoDigests}}", IMAGE], "inspect_image"))
    if not any(value.endswith("@" + IMAGE.split("@", 1)[1]) for value in digests):
        raise RuntimeError("image_digest_mismatch")
    command(["docker", "run", "--detach", "--name", container,
             "--label", LABEL + "=" + run, "--cpus", "2", "--memory", "3g",
             "--memory-swap", "3g", "--pids-limit", "1024",
             "--publish", "127.0.0.1::443", "--env-file", str(env_file),
             "--mount", f"type=bind,src={html},dst=/var/www/html",
             "--platform", "linux/amd64", IMAGE], "start_container")
    inspect_owned(container, run)
    deadline = time.monotonic() + 300
    status = None
    while time.monotonic() < deadline:
        try:
            candidate = json.loads(occ(container, ["status", "--output=json"]))
            if candidate.get("installed") and not candidate.get("maintenance"):
                status = candidate
                break
        except (CommandFailed, ValueError):
            pass
        time.sleep(2)
    if status is None or status.get("versionstring") != NEXTCLOUD_VERSION:
        raise RuntimeError("nextcloud_installation_not_ready")

    command(["docker", "cp", str(app / "deck"), container + ":/var/www/html/custom_apps/deck"], "copy_deck")
    command(["docker", "exec", "--user", "root", container, "chown", "-R",
             "www-data:www-data", "/var/www/html/custom_apps/deck"], "own_deck_files")
    occ(container, ["app:enable", "deck"])
    installed_deck = occ(container, ["config:app:get", "deck", "installed_version"]).strip()
    if installed_deck != DECK_VERSION:
        raise RuntimeError("installed_deck_version_mismatch")
    occ(container, ["integrity:check-app", "deck"])

    certificate, key = private / "certificate.pem", private / "key.pem"
    command(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-sha256", "-nodes",
             "-days", "1", "-subj", "/CN=localhost",
             "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1",
             "-keyout", str(key), "-out", str(certificate)], "create_certificate")
    site = private / "compat-ssl.conf"
    site.write_text("""<VirtualHost *:443>
  ServerName localhost
  DocumentRoot /var/www/html
  SSLEngine on
  SSLCertificateFile /tmp/compat-certificate.pem
  SSLCertificateKeyFile /tmp/compat-key.pem
  <Directory /var/www/html>
    Require all granted
    AllowOverride All
    Options FollowSymLinks
  </Directory>
</VirtualHost>
""", encoding="utf-8")
    for source, destination in [(certificate, "/tmp/compat-certificate.pem"),
                                (key, "/tmp/compat-key.pem"),
                                (site, "/etc/apache2/sites-available/compat-ssl.conf")]:
        command(["docker", "cp", str(source), container + ":" + destination], "copy_tls_config")
    for arguments in [["a2enmod", "ssl"], ["a2ensite", "compat-ssl"],
                      ["apache2ctl", "-t"], ["apache2ctl", "graceful"]]:
        command(["docker", "exec", "--user", "root", container, *arguments], "configure_tls")
    bindings = json.loads(command(["docker", "inspect", "--format",
        '{{json (index .NetworkSettings.Ports "443/tcp")}}', container], "inspect_https_port"))
    if len(bindings) != 1 or bindings[0]["HostIp"] != "127.0.0.1":
        raise RuntimeError("non_loopback_binding")
    server = "https://127.0.0.1:" + bindings[0]["HostPort"]
    fingerprint = hashlib.sha256(ssl.PEM_cert_to_DER_cert(certificate.read_text())).hexdigest()
    context = ssl.create_default_context(cafile=certificate)
    deadline = time.monotonic() + 30
    while True:
        try:
            with urllib.request.urlopen(server + "/status.php", context=context, timeout=5) as response:
                if json.load(response).get("versionstring") != NEXTCLOUD_VERSION:
                    raise RuntimeError("https_version_mismatch")
            break
        except urllib.error.URLError as error:
            if (isinstance(error.reason, ssl.SSLCertVerificationError)
                    or time.monotonic() >= deadline):
                raise
            time.sleep(1)

    actors = {}
    for role in ["owner", "reader"]:
        uid = "qa-" + role
        password = mask(secrets.token_urlsafe(36))
        occ(container, ["user:add", "--no-interaction", "--password-from-env",
                        "--display-name=Compatibility " + role, uid], password=password)
        occ(container, ["user:setting", uid, "files", "quota", "200 MB"])
        user_info = json.loads(occ(container, ["user:info", uid, "--output=json"]))
        if "admin" in user_info["groups"]:
            raise RuntimeError("test_actor_is_admin")
        output = occ(container, ["user:auth-tokens:add", "--no-interaction", "--password-from-env",
                                 "--name=OwnDeck compatibility", uid], password=password)
        token = output.strip().splitlines()[-1]
        if not re.fullmatch(r"[A-Za-z0-9]{72}", token):
            raise RuntimeError("unexpected_app_password_shape")
        mask(token)
        actors[role] = {"uid": uid, "appPassword": token}
    config = private / "credentials.json"
    save(config, {"server": server, "fingerprint": fingerprint, "actors": actors,
                  "deckVersion": DECK_VERSION, "runId": run})
    config.chmod(0o600)
    save(report / "versions.json", {"sourceRevision": os.environ["GITHUB_SHA"],
         "image": IMAGE, "nextcloudVersion": status["versionstring"],
         "deckVersion": installed_deck, "deckArchiveSha256": DECK_SHA256,
         "tlsPinned": True, "loopbackOnly": True, "database": "sqlite",
         "containerCpuLimit": 2, "containerMemoryGiB": 3, "actorsAreNonAdmin": True})
    print("Fixture ready; no repository credentials used", flush=True)


def restrict_creation(run, private):
    state = json.loads((private / "owner.json").read_text(encoding="utf-8"))
    inspect_owned(state["container"], run)
    occ(state["container"], ["group:add", "qa-creators"])
    occ(state["container"], ["group:adduser", "qa-creators", "qa-owner"])
    occ(state["container"], ["config:app:set", "deck", "groupLimit", "--value=qa-creators"])
    if occ(state["container"], ["config:app:get", "deck", "groupLimit"]).strip() != "qa-creators":
        raise RuntimeError("creation_policy_not_stored")
    for uid, expected in [("qa-owner", True), ("qa-reader", False)]:
        user = json.loads(occ(state["container"], ["user:info", uid, "--output=json"]))
        if ("qa-creators" in user["groups"]) != expected:
            raise RuntimeError("creation_group_membership_mismatch")


def cleanup(run, private, report):
    report.mkdir(exist_ok=True)
    result = {"containerRemoved": False, "privateFilesRemoved": False}
    if not private.exists():
        result.update(containerRemoved=True, privateFilesRemoved=True)
        save(report / "cleanup.json", result)
        return
    marker = private / "owner.json"
    if (private.parent != Path(os.environ["RUNNER_TEMP"]).resolve()
            or private.name != "owndeck-compat-" + run or not marker.is_file()):
        raise RuntimeError("cleanup_path_not_owned")
    state = json.loads(marker.read_text(encoding="utf-8"))
    if state["run"] != run or state["container"] != "owndeck-compat-" + run:
        raise RuntimeError("cleanup_marker_mismatch")
    containers = command(["docker", "ps", "-aq", "--filter", "name=^/" + state["container"] + "$"], "find_owned_container").strip()
    if containers:
        inspect_owned(state["container"], run)
        command(["docker", "rm", "--force", "--volumes", state["container"]], "remove_owned_container")
    result["containerRemoved"] = not command(["docker", "ps", "-aq", "--filter",
        "name=^/" + state["container"] + "$"], "verify_container_removed").strip()
    command(["sudo", "chown", "-R", "-h", "--", f"{os.getuid()}:{os.getgid()}", str(private)], "restore_temp_owner")
    shutil.rmtree(private)
    result["privateFilesRemoved"] = not private.exists()
    save(report / "cleanup.json", result)
    if not all(result.values()):
        raise RuntimeError("cleanup_incomplete")


def main():
    run, private, report = paths()
    try:
        mode = sys.argv[1]
        if mode == "prepare":
            prepare(run, private, report)
        elif mode == "restrict-creation":
            restrict_creation(run, private)
        elif mode == "cleanup":
            cleanup(run, private, report)
        else:
            raise RuntimeError("unknown_mode")
    except (OSError, ValueError, RuntimeError, CommandFailed,
            subprocess.TimeoutExpired, tarfile.TarError, ET.ParseError) as error:
        report.mkdir(exist_ok=True)
        failure = {"status": "failed", "errorType": type(error).__name__}
        if isinstance(error, RuntimeError):
            failure["code"] = str(error)
        if isinstance(error, CommandFailed):
            failure.update(phase=error.phase, exitCode=error.code)
        if isinstance(error, urllib.error.URLError):
            failure["reasonType"] = type(error.reason).__name__
            if isinstance(error.reason, OSError):
                failure["reasonErrno"] = error.reason.errno
            if isinstance(error.reason, ssl.SSLCertVerificationError):
                failure["tlsVerifyCode"] = error.reason.verify_code
            if isinstance(error, urllib.error.HTTPError):
                failure["httpStatus"] = error.code
        save(report / "setup-error.json", failure)
        print(json.dumps(failure), flush=True)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
