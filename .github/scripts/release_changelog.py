"""Extract changelog section for a given version."""

import os
import re
import sys

def main():
    version = os.environ.get("VERSION", "").lstrip("v")
    is_prerelease = "-" in version

    with open("CHANGELOG.md", "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.split("\n")
    start_idx = -1
    end_idx = len(lines)

    if is_prerelease:
        # Prerelease: use the latest (first) changelog section
        for i, line in enumerate(lines):
            if re.match(r"^##\s", line.strip()):
                start_idx = i
                break
    else:
        pattern = rf"^##\s*\[?{re.escape(version)}\]?(?:\s*-\s*\d{{4}}-\d{{2}}-\d{{2}})?\s*$"
        for i, line in enumerate(lines):
            if re.match(pattern, line.strip(), re.IGNORECASE):
                start_idx = i
                break

    if start_idx == -1:
        if is_prerelease:
            changelog = "*No changelog entry for this version.*"
        else:
            print(f"::error::No changelog entry found for release version {version}. "
                  "Please add a changelog entry before releasing.", file=sys.stderr)
            sys.exit(1)
    else:
        for i in range(start_idx + 1, len(lines)):
            if re.match(r"^##\s", lines[i].strip()):
                end_idx = i
                break

        changelog_lines = lines[start_idx + 1:end_idx]
        while changelog_lines and changelog_lines[0].strip() == "":
            changelog_lines.pop(0)
        while changelog_lines and changelog_lines[-1].strip() == "":
            changelog_lines.pop()

        changelog = "\n".join(changelog_lines) if changelog_lines else "*No changelog entry for this version.*"
        if not is_prerelease and changelog.startswith("*No changelog"):
            print(f"::error::Changelog entry for {version} is empty. "
                  "Please add content before releasing.", file=sys.stderr)
            sys.exit(1)

    output = os.environ.get("GITHUB_OUTPUT", "")
    if output:
        with open(output, "a", encoding="utf-8") as f:
            f.write("changelog<<CHANGELOG_EOF\n")
            f.write(changelog + "\n")
            f.write("CHANGELOG_EOF\n")
    else:
        print(changelog)

if __name__ == "__main__":
    main()
