#!/usr/bin/env python3

import argparse
import contextlib
import os
import socket
import subprocess
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import ssl
import http.server


"""
To configure a static hostname:
Go to router settings, advanced
IPv4 Address Distribution > Connection List
Edit the machine entry to be static

DNS Server
Add entry, where hostname will be URL (toney.net)
"""


# See cpython GH-17851 and GH-17864.
class DualStackServer(HTTPServer):
    def server_bind(self):
        # Suppress exception when protocol is IPv4.
        with contextlib.suppress(Exception):
            self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        return super().server_bind()


class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()


def shell_open(url):
    if sys.platform == "win32":
        os.startfile(url)
    else:
        opener = "open" if sys.platform == "darwin" else "xdg-open"
        subprocess.call([opener, url])


def serve(root, port, run_browser):
    os.chdir(root)

    server_address = ("0.0.0.0", port)
    handler = http.server.SimpleHTTPRequestHandler

    httpd = http.server.HTTPServer(server_address, handler)

    # Create an SSL context
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    cert_path = os.path.expanduser("~/certs/cert.pem")
    key_path = os.path.expanduser("~/certs/key.pem")

    context.load_cert_chain(certfile=cert_path, keyfile=key_path)

    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

    url = f"https://{socket.gethostbyname(socket.gethostname())}:{port}"
    if run_browser:
        print(
            f"Opening {url} in the browser. Use `--no-browser` or `-n` to disable this"
        )
        shell_open(url)
    else:
        print(f"Serving at: {url}")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received, stopping server.")
    finally:
        httpd.server_close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", help="port to listen on", default=443, type=int)
    parser.add_argument(
        "-r",
        "--root",
        help="path to serve as root (relative to `platform/web/`)",
        default="../../bin",
        type=Path,
    )
    browser_parser = parser.add_mutually_exclusive_group(required=False)
    browser_parser.add_argument(
        "-n",
        "--no-browser",
        help="don't open default web browser automatically",
        dest="browser",
        action="store_false",
    )
    parser.set_defaults(browser=True)
    args = parser.parse_args()

    # Change to the directory where the script is located,
    # so that the script can be run from any location.
    os.chdir(Path(__file__).resolve().parent)

    serve(args.root, args.port, args.browser)
