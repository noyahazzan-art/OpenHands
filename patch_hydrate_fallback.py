"""Patch the frontend build at container startup.

1. Removes the React Router console.log developer warning from index.html.
2. Injects a global error handler into index.html that suppresses harmless
   React hydration mismatch errors (#418, #423, #425) in SPA mode.
   This runs BEFORE React loads so it catches all errors.
"""

import re
import sys

BUILD_DIR = "/app/frontend/build"
INDEX = f"{BUILD_DIR}/index.html"

CONSOLE_LOG_PATTERN = re.compile(
    r"<script>\s*console\.log\(\s*\"💿 Hey developer.*?</script>",
    re.DOTALL,
)

HYDRATION_HANDLER_TAG = "data-hydration-guard"

HYDRATION_HANDLER = (
    f'<script {HYDRATION_HANDLER_TAG}>'
    'window.addEventListener("error",function(e){'
    'if(e.error&&e.error.message&&/Minified React error #(418|423|425)/.test(e.error.message))'
    '{e.preventDefault()}'
    '});'
    'window.addEventListener("unhandledrejection",function(e){'
    'var m=e.reason&&(e.reason.message||String(e.reason));'
    'if(m&&(/Minified React error #(418|423|425)/.test(m)'
    '||/Could not establish connection/.test(m)'
    '||/Receiving end does not exist/.test(m)))'
    '{e.preventDefault()}'
    '});'
    '</script>'
)


def main() -> int:
    try:
        with open(INDEX, "r", encoding="utf-8") as f:
            html = f.read()
    except FileNotFoundError:
        print(f"[patch] {INDEX} not found, skipping")
        return 0

    changed = False

    if CONSOLE_LOG_PATTERN.search(html):
        html = CONSOLE_LOG_PATTERN.sub("", html, count=1)
        print("[patch] console.log warning removed")
        changed = True
    else:
        print("[patch] console.log already clean")

    if HYDRATION_HANDLER_TAG not in html:
        html = html.replace("<head>", "<head>" + HYDRATION_HANDLER, 1)
        print("[patch] hydration error guard injected")
        changed = True
    else:
        print("[patch] hydration guard already present")

    if changed:
        with open(INDEX, "w", encoding="utf-8") as f:
            f.write(html)
        print("[patch] index.html saved")
    else:
        print("[patch] no changes needed")

    return 0


if __name__ == "__main__":
    sys.exit(main())
