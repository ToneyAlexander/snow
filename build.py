import argparse
import subprocess
from dialog.tools.convo_parser import build_dialog_trees
from docs.serve import serve


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-b",
        "--browser",
        help="don't open default web browser automatically",
        dest="browser",
        action="store_true",
    )
    parser.set_defaults(browser=False)
    args = parser.parse_args()

    # Build dialog trees (calls godot to create .tres)
    print("Building dialog trees")
    build_dialog_trees()

    print("Running web export")
    # godot4 is alias for /Applications/Godot4.4.app/Contents/MacOS/Godot
    # godot4 --headless --export-release "Web" docs/index.html
    subprocess.run(
        [
            "/Applications/Godot4.4.app/Contents/MacOS/Godot",
            "--headless",
            "--export-release",
            "Web",
            "docs/index.html",
        ]
    )

    # Serve
    print("Serving")
    serve(root="./docs", port=443, run_browser=args.browser)
