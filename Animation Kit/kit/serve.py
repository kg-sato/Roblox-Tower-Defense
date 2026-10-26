"""Serve this pack folder to Roblox Studio on http://127.0.0.1:8765 (this computer only).

    python kit/serve.py

AnimKit.load / AnimKit.verify / the AnimKit installer fetch exported animations from here, so nothing
has to be copied and pasted. Stop it with Ctrl+C when you are done.
"""
import functools
import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
PACK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


SECRETS = os.path.join(PACK, ".secrets")


class Handler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        real = os.path.realpath(super().translate_path(path))
        if os.path.normcase(real).startswith(os.path.normcase(os.path.realpath(SECRETS))):
            return os.path.join(PACK, "__never__")  # the API key folder is never served
        return real

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    handler = functools.partial(Handler, directory=PACK)
    with http.server.ThreadingHTTPServer(("127.0.0.1", PORT), handler) as httpd:
        print(f"Serving {PACK} to Studio on http://127.0.0.1:{PORT} (Ctrl+C to stop)")
        httpd.serve_forever()
