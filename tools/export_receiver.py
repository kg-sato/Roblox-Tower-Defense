"""Local receiver for Studio script export (127.0.0.1 only). Studio sends each script's Source in chunks as GET requests:
  /put?p=<full name>&i=<chunk index>&n=<chunk count>&d=<text>
Finished scripts are written to Studio_Export/<script name>.luau. Run: python tools/export_receiver.py [port]"""
import re, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

out = Path(__file__).resolve().parents[1] / "Studio_Export"
out.mkdir(exist_ok=True)
parts, names = {}, {}


class H(BaseHTTPRequestHandler):
    def do_GET(self):
        u = urlparse(self.path)
        if u.path == "/put":
            q = {k: v[0] for k, v in parse_qs(u.query, keep_blank_values=True).items()}
            p, i, n = q["p"], int(q["i"]), int(q["n"])
            buf = parts.setdefault(p, {})
            buf[i] = q.get("d", "")
            if len(buf) == n:
                base = re.sub(r"[^\w.-]", "_", p.rsplit(".", 1)[-1])
                if names.get(base, p) != p:
                    base += "__" + re.sub(r"[^\w]", "_", p)
                names[base] = p
                (out / f"{base}.luau").write_text("".join(buf[k] for k in range(n)), encoding="utf-8", newline="")
                del parts[p]
                print("wrote", base, flush=True)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *a):
        pass


HTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 8765), H).serve_forever()
