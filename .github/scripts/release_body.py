"""Generate GitHub release body markdown."""

import os


def build_release_body(version, repo, changelog, prev):
    version = version.removeprefix("v")
    previous_ref = prev.split(" ", 1)[0]
    body = f"""## 下载
- HarmonyOS: [无签名 HAP]({repo}/releases/download/v{version}/bugaoshan_{version}_ohos_unsigned.hap)

> 此 HAP 未签名，安装前需要自行签名。

{changelog}

**Full diff:** {repo}/compare/{previous_ref}...v{version}"""
    return body


def main():
    body = build_release_body(
        os.environ.get("VERSION", ""),
        os.environ.get("REPO", ""),
        os.environ.get("CHANGELOG", ""),
        os.environ.get("PREV", ""),
    )

    output = os.environ.get("GITHUB_OUTPUT", "")
    if output:
        with open(output, "a", encoding="utf-8") as f:
            f.write(f"body<<BODY_EOF\n")
            f.write(body + "\n")
            f.write("BODY_EOF\n")
    else:
        print(body)

if __name__ == "__main__":
    main()
