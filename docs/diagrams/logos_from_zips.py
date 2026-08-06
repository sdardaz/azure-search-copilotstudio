"""Extract the product icons used by the architecture deck from Microsoft's official icon sets.

The icons themselves are deliberately not committed: Microsoft's terms allow using them
in architecture diagrams but not redistributing the sets, so `docs/diagrams/logos/` is
gitignored and rebuilt locally from the official downloads.

Usage:

    python docs/diagrams/logos_from_zips.py ~/Downloads

`zip_dir` must contain the official archives (matched by name fragment, so the exact
version suffix does not matter):

  * Azure_Public_Service_Icons_V*.zip      https://learn.microsoft.com/azure/architecture/icons/
  * PowerPlatformiconsscalable.zip         https://learn.microsoft.com/power-platform/guidance/icons
  * Microsoft_Entra_architecture_icons*.zip
  * *microsoft365contenticons.zip

Writes 512 px transparent PNGs into docs/diagrams/logos/, then run:

    node docs/diagrams/architecture_pptx.js
"""

import argparse
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

# Archive name fragment -> the key each source path below is written against.
ARCHIVES = {
    "azure": "Azure_Public_Service_Icons",
    "powerplatform": "PowerPlatformicons",
    "entra": "Entra_architecture_icons",
    "m365": "microsoft365contenticons",
}

# Slot name (as referenced by architecture_pptx.js) -> (archive key, path suffix within it).
# Paths are matched by suffix so an extra top-level folder in the zip does not matter.
ICONS = {
    "sharepoint": ("m365", "SharePoint Teal/48x48 SVG Icon/Organization_Light.svg"),
    "local-files": ("azure", "Icons/general/10801-icon-service-Files.svg"),
    "logic-apps": ("azure", "Icons/integration/02631-icon-service-Logic-Apps.svg"),
    "blob-storage": ("azure", "Icons/storage/10086-icon-service-Storage-Accounts.svg"),
    "ai-search": ("azure", "Icons/ai + machine learning/10044-icon-service-Cognitive-Search.svg"),
    "functions": ("azure", "Icons/compute/10029-icon-service-Function-Apps.svg"),
    "document-intelligence": ("azure", "Icons/ai + machine learning/00819-icon-service-Form-Recognizers.svg"),
    "ai-vision": ("azure", "Icons/ai + machine learning/00792-icon-service-Computer-Vision.svg"),
    "content-understanding": ("azure", "Icons/ai + machine learning/10162-icon-service-Cognitive-Services.svg"),
    "foundry": ("azure", "Icons/ai + machine learning/035746832-icon-service-AI-Foundry.svg"),
    "monitor": ("azure", "Icons/monitor/00001-icon-service-Monitor.svg"),
    "virtual-network": ("azure", "Icons/networking/10061-icon-service-Virtual-Networks.svg"),
    "user": ("azure", "Icons/identity/10230-icon-service-Users.svg"),
    "copilot-studio": ("powerplatform", "CopilotStudio_scalable.svg"),
    "entra-id": ("entra", "Microsoft Entra color icons SVG/Microsoft Entra ID color icon.svg"),
}

OUT_DIR = Path(__file__).resolve().parent / "logos"


def find_archives(zip_dir: Path) -> dict[str, Path]:
    found = {}
    for zip_path in sorted(zip_dir.glob("*.zip")):
        for key, fragment in ARCHIVES.items():
            if fragment.lower() in zip_path.name.lower() and key not in found:
                found[key] = zip_path
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("zip_dir", type=Path, help="directory holding the official icon archives")
    args = parser.parse_args()

    if not shutil.which("cairosvg"):
        print("cairosvg is required: pip install cairosvg", file=sys.stderr)
        return 1

    archives = find_archives(args.zip_dir)
    for key, fragment in ARCHIVES.items():
        if key not in archives:
            print(f"missing archive for '{key}' (looked for a name containing {fragment!r})", file=sys.stderr)
            return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    failures = []

    with tempfile.TemporaryDirectory() as tmp:
        roots = {}
        for key, zip_path in archives.items():
            root = Path(tmp) / key
            with zipfile.ZipFile(zip_path) as zf:
                zf.extractall(root)
            roots[key] = root

        for slot, (key, suffix) in ICONS.items():
            matches = [p for p in roots[key].rglob("*.svg") if str(p).endswith(suffix)]
            if not matches:
                failures.append(f"{slot}: no file ending in {suffix!r} inside {archives[key].name}")
                continue
            out = OUT_DIR / f"{slot}.png"
            subprocess.run(
                ["cairosvg", str(matches[0]), "-o", str(out), "--output-width", "512"],
                check=True,
            )

    print(f"wrote {len(ICONS) - len(failures)}/{len(ICONS)} icons to {OUT_DIR}")
    for line in failures:
        print("FAILED:", line, file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
