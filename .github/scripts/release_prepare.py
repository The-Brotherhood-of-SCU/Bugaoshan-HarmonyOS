"""Prepare the HarmonyOS release HAP for upload."""

import os
import shutil
from pathlib import Path


def prepare_release_files(version, root=Path(".")):
    root = Path(root)
    version = version.removeprefix("v")
    haps = sorted((root / "ohos-hap").glob("*-unsigned.hap"))
    if len(haps) != 1:
        raise FileNotFoundError(f"Expected one unsigned HarmonyOS HAP, found {len(haps)}")

    dst = root / f"bugaoshan_{version}_ohos_unsigned.hap"
    shutil.copy2(haps[0], dst)
    print(f"Copied {haps[0]} -> {dst}")
    return dst


def main():
    version = os.environ.get("VERSION", "")
    prepare_release_files(version)


if __name__ == "__main__":
    main()
