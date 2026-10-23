"""Extract versioned routes and controller signatures from a pinned Deck release."""

import concurrent.futures
import pathlib
import re
import urllib.request

REVISION = "28efc84c108807cf0821d83e52f45b43cac27412"
BASE = f"https://raw.githubusercontent.com/nextcloud/deck/{REVISION}/"
ROOT = pathlib.Path(__file__).resolve().parents[1]
CACHE = ROOT / ".artifacts" / "upstream"


def source(path):
    target = CACHE / pathlib.PurePosixPath(path).name
    # Cache belongs to this pinned revision; arbitrary older files are not used.
    with urllib.request.urlopen(BASE + path, timeout=30) as response:
        data = response.read().decode("utf-8")
    target.write_text(data, encoding="utf-8")
    return data


def controller_name(route_name):
    name = route_name.split("#")[0]
    return "".join(part[:1].upper() + part[1:] for part in name.split("_")) + "Controller"


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    routes = source("appinfo/routes.php")
    entries = []
    family = "REST"
    for line in routes.splitlines():
        if "'ocs' =>" in line:
            family = "OCS"
        match = re.search(r"'name'\s*=>\s*'([^']+)'.*?'url'\s*=>\s*'([^']+)'.*?'verb'\s*=>\s*'([^']+)'", line)
        if not match or not match[2].startswith("/api/v"):
            continue
        restriction = re.search(r"'apiVersion'\s*=>\s*'([^']+)'", line)
        entries.append((family, *match.groups(), restriction[1] if restriction else "dle capabilities"))
    names = sorted({controller_name(row[1]) for row in entries})
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        contents = dict(zip(names, pool.map(lambda name: source(f"lib/Controller/{name}.php"), names)))
    signatures = {}
    for name, code in contents.items():
        signatures[name] = {
            method.lower(): " ".join(arguments.split())
            for method, arguments in re.findall(r"public function (\w+)\((.*?)\)", code, re.S)
        }
    lines = [
        "# Soupis verzovaných Deck endpointů",
        "",
        f"Zdroj: [Deck v1.19.1, {REVISION[:7]}](https://github.com/nextcloud/deck/tree/{REVISION}).",
        "Generováno pomocí `python tool/inventory_deck_api.py`. Jde o analýzu zdrojového kódu, ne o důkaz dostupnosti na serveru.",
        "",
        "REST prefix: `/index.php/apps/deck`. OCS prefix: `/ocs/v2.php/apps/deck`.",
        "Parametry v tabulce jsou podpis metody PHP; parametry cesty jsou navíc v URL a některá pole metoda čte přímo z požadavku. `done` a `color` při aktualizaci karty jsou popsány v [analýze](nextcloud-api.md).",
        "",
        "| Rodina | Metoda a cesta | Verze | Parametry metody | Zdroj / omezení |",
        "|---|---|---|---|---|",
    ]
    missing = []
    for family, name, url, verb, version in entries:
        controller = controller_name(name)
        method = name.split("#")[1].replace("_", "").lower()
        methods = {key.replace("_", ""): value for key, value in signatures[controller].items()}
        if controller == "AttachmentApiV11Controller":
            methods = signatures["AttachmentApiController"]
        arguments = methods.get(method)
        status = f"[{controller}](https://github.com/nextcloud/deck/blob/{REVISION}/lib/Controller/{controller}.php)"
        if arguments is None:
            status += " / zděděná framework metoda" if verb == "OPTIONS" else " / CHYBÍ METODA"
            if verb != "OPTIONS":
                missing.append(name)
        safe_arguments = (arguments or "").replace("|", "\\|")
        lines.append(f"| {family} | `{verb} {url}` | {version} | `{safe_arguments}` | {status} |")
    lines += ["", f"Celkem {len(entries)} verzovaných rout, z toho {sum(row[0] == 'REST' for row in entries)} REST a {sum(row[0] == 'OCS' for row in entries)} OCS.", "", "Routy bez nalezené metody: " + ", ".join(f"`{name}`" for name in missing) + "."]
    (ROOT / "docs" / "api-inventory.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {len(entries)} routes; missing methods: {', '.join(missing)}")


if __name__ == "__main__":
    main()
