"""Prepare native app icons from the generated Tasbeeh logo (requires Pillow).

Run from any directory: python3 apps/mobile/tool/generate_app_icons.py
The transparent source stays unchanged; iOS icons are saved as opaque RGB.
"""

import json
from pathlib import Path

from PIL import Image


MOBILE = Path(__file__).resolve().parents[1]
BRANDING = MOBILE / "assets/branding"
ANDROID = MOBILE / "android/app/src/main/res"
IOS = MOBILE / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
BACKGROUND = "#233B32"
SIZE = 1024


def centered(image, side, scale):
    edge = round(side * scale)
    resized = image.resize((edge, edge), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (side, side))
    inset = (side - edge) // 2
    canvas.alpha_composite(resized, (inset, inset))
    return canvas


def main():
    with Image.open(BRANDING / "tasbeeh-logo.png") as source:
        if source.width != source.height:
            raise ValueError("The source logo must be square")
        mark = centered(source.convert("RGBA"), SIZE, 0.86)

    icon = Image.new("RGBA", (SIZE, SIZE), BACKGROUND)
    icon.alpha_composite(mark)
    icon = icon.convert("RGB")
    icon.save(BRANDING / "tasbeeh-icon.png", optimize=True)

    # The foreground includes Android's extra inset for parallax and masks.
    foreground = centered(mark, SIZE, 0.74)
    monochrome = Image.new("RGBA", foreground.size, "white")
    monochrome.putalpha(foreground.getchannel("A"))
    densities = {
        "mdpi": (48, 108),
        "hdpi": (72, 162),
        "xhdpi": (96, 216),
        "xxhdpi": (144, 324),
        "xxxhdpi": (192, 432),
    }
    for density, (legacy_size, adaptive_size) in densities.items():
        folder = ANDROID / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        for name, image, side in (
            ("ic_launcher", icon, legacy_size),
            ("ic_launcher_foreground", foreground, adaptive_size),
            ("ic_launcher_monochrome", monochrome, adaptive_size),
        ):
            image.resize((side, side), Image.Resampling.LANCZOS).save(
                folder / f"{name}.png", optimize=True
            )

    catalog = json.loads((IOS / "Contents.json").read_text())
    outputs = {}
    for entry in catalog["images"]:
        side = round(float(entry["size"].split("x")[0]) * float(entry["scale"][:-1]))
        outputs[entry["filename"]] = side
    for filename, side in outputs.items():
        icon.resize((side, side), Image.Resampling.LANCZOS).save(
            IOS / filename, optimize=True
        )

    print(f"Generated the brand icon, {len(densities) * 3} Android icons, "
          f"and {len(outputs)} iOS icons.")


if __name__ == "__main__":
    main()
