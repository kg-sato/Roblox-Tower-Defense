"""Tiny Markdown -> HTML for GUIDE.md (headings, lists, code, tables, quotes, images, links).

    python kit/guide_html.py GUIDE.md GUIDE.html     run it after editing GUIDE.md
"""
import html
import re
import sys

CSS = """
:root{--bg:#f5f4f1;--card:#fff;--ink:#1b1a1f;--muted:#5c5a64;--line:#e2dfe6;--accent:#c8361d;--accent2:#e8902a;
--code:#efece9;--pre:#1b1a1f;--pretext:#f2efe9}
@media (prefers-color-scheme:dark){:root{--bg:#121115;--card:#1b1a20;--ink:#ecebef;--muted:#a3a1ab;--line:#2c2a33;
--accent:#ff6a4d;--accent2:#ffb15c;--code:#26242c;--pre:#0b0a0e;--pretext:#ecebef}}
*{box-sizing:border-box}html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.65 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:900px;margin:0 auto;padding:40px 16px 80px}
h1{font-size:2.3em;line-height:1.15;margin:.2em 0 .3em;letter-spacing:-.02em}
h2{font-size:1.5em;margin:2.2em 0 .5em;padding-top:.3em;letter-spacing:-.01em}
h3{font-size:1.15em;margin:1.6em 0 .4em}
a{color:var(--accent)}hr{border:0;border-top:1px solid var(--line);margin:2.5em 0}
code{background:var(--code);padding:.1em .35em;border-radius:5px;font:.88em ui-monospace,Consolas,monospace}
pre{background:var(--pre);color:var(--pretext);padding:16px 18px;border-radius:10px;overflow-x:auto;line-height:1.5}
pre code{background:none;padding:0;color:inherit;font-size:.85em}
blockquote{margin:1.4em 0;padding:14px 18px;background:var(--card);border:1px solid var(--line);
border-left:5px solid var(--accent2);border-radius:8px}blockquote p{margin:.3em 0}
.table{overflow-x:auto;margin:1.2em 0}table{border-collapse:collapse;width:100%;background:var(--card);font-size:.93em}
th,td{text-align:left;padding:9px 12px;border-bottom:1px solid var(--line);vertical-align:top}th{background:var(--code)}
figure{margin:1.6em 0}figure img{max-width:100%;border-radius:10px;display:block;border:1px solid var(--line)}
figcaption{color:var(--muted);font-size:.9em;margin-top:8px;text-align:center}
li{margin:.25em 0}.credit{position:sticky;top:0;z-index:2;background:var(--accent);color:#fff;text-align:center;
padding:8px 12px;font-weight:600;font-size:.95em}
"""


def slug(text):
    text = re.sub(r"<[^>]+>", "", text).lower()
    text = re.sub(r"[^\w\s-]", "", text)
    return re.sub(r"\s", "-", text.strip())


def inline(text):
    codes = []

    def stash(m):
        codes.append(f"<code>{html.escape(m.group(1))}</code>")
        return f"\x00{len(codes) - 1}\x00"

    p = re.sub(r"`([^`]+)`", stash, text)
    p = html.escape(p, quote=False)
    p = re.sub(r"!\[([^\]]*)\]\(([^)]+)\)", r'<img src="\2" alt="\1">', p)
    p = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', p)
    p = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", p)
    p = re.sub(r"(?<![\w*])\*([^*\s][^*]*)\*(?![\w*])", r"<em>\1</em>", p)
    return re.sub(r"\x00(\d+)\x00", lambda m: codes[int(m.group(1))], p)


def convert(md):
    lines = md.split("\n")
    out, i = [], 0
    title = None
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            buf = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                buf.append(lines[i])
                i += 1
            out.append("<pre><code>" + html.escape("\n".join(buf)) + "</code></pre>")
            i += 1
            continue
        m = re.match(r"^(#{1,3}) (.*)", line)
        if m:
            level, text = len(m.group(1)), inline(m.group(2))
            title = title or re.sub(r"<[^>]+>", "", text)
            out.append(f'<h{level} id="{slug(m.group(2))}">{text}</h{level}>')
            i += 1
            continue
        if line.strip() == "---":
            out.append("<hr>")
            i += 1
            continue
        img = re.match(r"^!\[([^\]]*)\]\(([^)]+)\)\s*$", line)
        if img:
            alt = html.escape(img.group(1))
            out.append(f'<figure><img src="{img.group(2)}" alt="{alt}" loading="lazy"><figcaption>{alt}</figcaption></figure>')
            i += 1
            continue
        if line.startswith(">"):
            buf = []
            while i < len(lines) and lines[i].startswith(">"):
                buf.append(lines[i].lstrip(">").strip())
                i += 1
            out.append("<blockquote><p>" + inline(" ".join(buf)) + "</p></blockquote>")
            continue
        if line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
                i += 1
            head, body = rows[0], [r for r in rows[1:] if not all(re.match(r"^:?-+:?$", c) for c in r)]
            t = "<div class=\"table\"><table><thead><tr>" + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>"
            t += "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body)
            out.append(t + "</tbody></table></div>")
            continue
        lm = re.match(r"^(\s*)([-*]|\d+\.) (.*)", line)
        if lm:
            out.append(parse_list(lines, i))
            i = parse_list.end
            continue
        if not line.strip():
            i += 1
            continue
        buf = []
        while i < len(lines) and lines[i].strip() and not re.match(r"^(#{1,3} |```|>|\||\s*([-*]|\d+\.) |---$)", lines[i]):
            buf.append(lines[i].strip())
            i += 1
        out.append("<p>" + inline(" ".join(buf)) + "</p>")
    return title, "\n".join(out)


def parse_list(lines, i):
    """Nested lists by indentation; list items may continue on indented lines and hold code blocks."""
    base = len(lines[i]) - len(lines[i].lstrip())
    ordered = bool(re.match(r"^\s*\d+\.", lines[i]))
    items = []
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            # a blank line ends the list unless the next line is still part of it
            nxt = lines[i + 1] if i + 1 < len(lines) else ""
            ind = len(nxt) - len(nxt.lstrip())
            if nxt.strip() and (ind > base or re.match(r"^\s*([-*]|\d+\.) ", nxt) and ind == base):
                i += 1
                continue
            break
        ind = len(line) - len(line.lstrip())
        m = re.match(r"^\s*([-*]|\d+\.) (.*)", line)
        if m and ind == base:
            items.append([m.group(2)])
            i += 1
        elif ind > base and items:
            if re.match(r"^\s*([-*]|\d+\.) ", line):
                sub = parse_list(lines, i)
                items[-1].append(("html", sub))
                i = parse_list.end
            elif line.strip().startswith("```"):
                buf = []
                i += 1
                while i < len(lines) and not lines[i].strip().startswith("```"):
                    buf.append(lines[i].strip())
                    i += 1
                i += 1
                items[-1].append(("html", "<pre><code>" + html.escape("\n".join(buf)) + "</code></pre>"))
            elif line.strip().startswith(">"):
                items[-1].append(("html", "<blockquote><p>" + inline(line.strip().lstrip(">").strip()) + "</p></blockquote>"))
                i += 1
            else:
                items[-1].append(line.strip())
                i += 1
        else:
            break
    parse_list.end = i
    tag = "ol" if ordered else "ul"
    html_items = []
    for it in items:
        chunks, text = [], []
        for part in it:  # keep text and nested blocks in their original order
            if isinstance(part, tuple):
                if text:
                    chunks.append(inline(" ".join(text)))
                    text = []
                chunks.append(part[1])
            else:
                text.append(part)
        if text:
            chunks.append(inline(" ".join(text)))
        html_items.append("<li>" + "".join(chunks) + "</li>")
    return f"<{tag}>" + "".join(html_items) + f"</{tag}>"


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    md = open(src, encoding="utf-8").read()
    title, body = convert(md)
    page = ("<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
            f"<title>Roblox Animations with Claude, by fwjelaa</title><meta name=\"author\" content=\"fwjelaa (FWJ STUDIOS)\">"
            f"<style>{CSS}</style></head>\n<body><div class=\"credit\">Method by fwjelaa (FWJ STUDIOS): please credit fwjelaa "
            f"if you use or share it</div>\n<main>\n{body}\n</main></body></html>\n")
    open(dst, "w", encoding="utf-8").write(page)
    print("wrote", dst, len(page))
