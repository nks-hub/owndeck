"""Render the launcher SVG with the Pillow version in icon_requirements.txt."""

import json
from pathlib import Path
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "apps/mobile/assets/brand"
ANDROID = ROOT / "apps/mobile/android/app/src/main/res"
IOS = ROOT / "apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"
MACOS = ROOT / "apps/mobile/macos/Runner/Assets.xcassets/AppIcon.appiconset"
WINDOWS_ICON = ROOT / "apps/mobile/windows/runner/resources/app_icon.ico"
SVG = "{http://www.w3.org/2000/svg}"


def geometry():
    document = ET.parse(BRAND / "owndeck.svg").getroot()
    if document.get("viewBox") != "0 0 1024 1024":
        raise ValueError("The icon uses a 1024 x 1024 coordinate system")
    rectangles = []
    for node in document:
        if node.tag == SVG + "title":
            continue
        if node.tag != SVG + "rect":
            raise ValueError("Only rectangles are supported by this icon generator")
        rectangles.append({
            "id": node.attrib["id"],
            "fill": node.attrib["fill"],
            **{key: float(node.get(key, "0")) for key in ("x", "y", "width", "height", "rx")},
        })
    background, board, *columns = rectangles
    if background["id"] != "background" or board["id"] != "board":
        raise ValueError("The background and board must be the first two rectangles")
    if board["fill"] != "#ffffff" or any(column["fill"] != background["fill"] for column in columns):
        raise ValueError("The monochrome mark needs white artwork and background-colored cutouts")
    return rectangles


def raster(rectangles, size):
    # Four samples per output pixel keep the smallest 20 px iOS icon legible.
    scale = size * 4 / 1024
    image = Image.new("RGB", (size * 4, size * 4), rectangles[0]["fill"])
    draw = ImageDraw.Draw(image)
    for rect in rectangles[1:]:
        x, y = rect["x"] * scale, rect["y"] * scale
        box = (x, y, x + rect["width"] * scale, y + rect["height"] * scale)
        draw.rounded_rectangle(box, radius=rect["rx"] * scale, fill=rect["fill"])
    return image.resize((size, size), Image.Resampling.LANCZOS)


def rectangle_path(rect):
    x, y, width, height, radius = (rect[key] for key in ("x", "y", "width", "height", "rx"))
    right, bottom = x + width, y + height
    return (
        f"M{x + radius:g},{y:g} H{right - radius:g} "
        f"A{radius:g},{radius:g} 0,0 1 {right:g},{y + radius:g} V{bottom - radius:g} "
        f"A{radius:g},{radius:g} 0,0 1 {right - radius:g},{bottom:g} H{x + radius:g} "
        f"A{radius:g},{radius:g} 0,0 1 {x:g},{bottom - radius:g} V{y + radius:g} "
        f"A{radius:g},{radius:g} 0,0 1 {x + radius:g},{y:g} Z"
    )


def write_xml(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('<?xml version="1.0" encoding="utf-8"?>\n' + content + "\n", encoding="utf-8")


def adaptive(rectangles):
    board = rectangles[1]
    # The foreground is 48 dp inside the adaptive icon's 108 dp viewport.
    scale = 48 / (108 * board["width"] / 1024)
    paths = " ".join(rectangle_path(rect) for rect in rectangles[1:])
    write_xml(ANDROID / "drawable/ic_launcher_foreground.xml", f'''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="1024" android:viewportHeight="1024">
    <group android:pivotX="512" android:pivotY="512"
        android:scaleX="{scale:.9f}" android:scaleY="{scale:.9f}">
        <path android:fillColor="#FFFFFFFF" android:fillType="evenOdd"
            android:pathData="{paths}"/>
    </group>
</vector>''')
    write_xml(ANDROID / "values/ic_launcher_colors.xml", f'''<resources>
    <color name="ic_launcher_background">{rectangles[0]["fill"]}</color>
</resources>''')
    for version in (26, 33):
        monochrome = '\n    <monochrome android:drawable="@drawable/ic_launcher_foreground"/>' if version >= 33 else ""
        write_xml(ANDROID / f"mipmap-anydpi-v{version}/ic_launcher.xml", f'''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>{monochrome}
</adaptive-icon>''')


def main():
    rectangles = geometry()
    sizes = {}
    for entry in json.loads((IOS / "Contents.json").read_text(encoding="utf-8"))["images"]:
        width, height = map(float, entry["size"].split("x"))
        pixels = width * float(entry["scale"].removesuffix("x"))
        if width != height or pixels != int(pixels):
            raise ValueError("Each app icon must have a square integer pixel size")
        filename = entry["filename"]
        if filename in sizes and sizes[filename] != int(pixels):
            raise ValueError("Conflicting iOS icon dimensions")
        sizes[filename] = int(pixels)
    for filename, size in sizes.items():
        raster(rectangles, size).save(IOS / filename, optimize=True)
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        raster(rectangles, size).save(ANDROID / f"mipmap-{density}/ic_launcher.png", optimize=True)
    raster(rectangles, 512).save(BRAND / "play-store-icon.png", optimize=True)
    for size in (16, 32, 64, 128, 256, 512, 1024):
        raster(rectangles, size).save(MACOS / f"app_icon_{size}.png", optimize=True)
    raster(rectangles, 256).save(
        WINDOWS_ICON, sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
    adaptive(rectangles)
    print(f"Generated {len(sizes)} iOS icons, 5 Android bitmaps, macOS and Windows icons and adaptive resources.")


if __name__ == "__main__":
    main()
