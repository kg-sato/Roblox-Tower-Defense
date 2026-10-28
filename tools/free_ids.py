"""List identifiers a slice of a Luau file uses but does not define (upvalues it would need from outside).
python tools/free_ids.py <file> <first line> <last line>"""
import re, sys

path, start, end = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
lines = open(path, encoding="utf-8").read().split("\n")
s = "\n".join(lines[start - 1:end])
s = re.sub(r"--[^\n]*", "", s)
s = re.sub(r'"(?:\\.|[^"\\])*"', '""', s)
ids = set(re.findall(r"(?<![\w.:])([A-Za-z_]\w*)", s))
defined = set()
for m in re.findall(r"\blocal\s+(?:function\s+)?([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)", s):
    defined.update(x.strip() for x in m.split(","))
for m in re.findall(r"function\s*\w*\(([^)]*)\)", s):
    defined.update(x.strip() for x in m.split(","))
for m in re.findall(r"for\s+([\w,\s]+?)\s+in\b", s):
    defined.update(x.strip() for x in m.split(","))
defined.update(re.findall(r"for\s+(\w+)\s*=", s))
kw = set("and break do else elseif end false for function if in local nil not or repeat return then true until while continue".split())
glob = set("math string table task os Instance Vector2 Vector3 UDim UDim2 Color3 CFrame Enum TweenInfo NumberSequence NumberSequenceKeypoint ColorSequence ipairs pairs warn pcall tostring tonumber type workspace game script next select setmetatable utf8 typeof Random".split())
print(sorted(i for i in ids if i not in defined and i not in kw and i not in glob))
