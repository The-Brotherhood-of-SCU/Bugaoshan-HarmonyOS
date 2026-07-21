"""Write deterministic version metadata for the CPF Flutter SDK."""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path


EXPECTED_REVISION = "aa33b6e2a6ed5e2672e45eef43d1221310a96878"
FLUTTER_VERSION = "3.41.9"
DART_VERSION = "3.11.5"
DEVTOOLS_VERSION = "2.54.1"
REPOSITORY_URL = "https://gitcode.com/CPF-Flutter/flutter_flutter.git"


def git_output(root: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(root), *args],
        text=True,
    ).strip()


def bootstrap_flutter(root: Path) -> None:
    """Build the Flutter tool before writing metadata it would invalidate."""
    subprocess.run(
        [str(root / "bin/flutter"), "--version"],
        cwd=root,
        check=True,
        env=os.environ.copy(),
    )


def main() -> None:
    root = Path(
        os.environ.get("FLUTTER_OH_ROOT", Path.home() / "Developer/flutter-ohos")
    ).expanduser().resolve()
    revision = git_output(root, "rev-parse", "HEAD")
    if revision != EXPECTED_REVISION:
        raise SystemExit(
            f"Expected CPF Flutter {EXPECTED_REVISION}, found {revision} at {root}"
        )

    bootstrap_flutter(root)
    commit_date = git_output(root, "log", "-1", "--format=%cI")
    engine_revision = (root / "bin/internal/engine.version").read_text().strip()
    cache = root / "bin/cache"
    cache.mkdir(parents=True, exist_ok=True)

    data = {
        "frameworkVersion": FLUTTER_VERSION,
        "channel": "[user-branch]",
        "repositoryUrl": REPOSITORY_URL,
        "frameworkRevision": revision,
        "frameworkCommitDate": commit_date,
        "engineRevision": engine_revision,
        "engineCommitDate": None,
        "engineContentHash": None,
        "engineBuildDate": None,
        "dartSdkVersion": DART_VERSION,
        "devToolsVersion": DEVTOOLS_VERSION,
        "flutterVersion": FLUTTER_VERSION,
    }
    (cache / "flutter.version.json").write_text(
        json.dumps(data, indent=2) + "\n",
        encoding="utf-8",
    )
    (root / "version").write_text(f"{FLUTTER_VERSION}\n", encoding="utf-8")
    print(f"Configured CPF Flutter {FLUTTER_VERSION} at {root}")


if __name__ == "__main__":
    main()
