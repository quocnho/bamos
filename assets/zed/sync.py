import json, os, pathlib, shutil, sys

assets = pathlib.Path(sys.argv[1])
home = pathlib.Path.home()

def jsonc_loads(text):
    # Parse JSONC: bỏ comment // bên ngoài chuỗi + dấu phẩy thừa
    out, in_str, i, pending_comma = [], False, 0, False
    while i < len(text):
        c = text[i]
        if in_str:
            out.append(c)
            if c == '\\':
                out.append(text[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
        else:
            if c == '"':
                if pending_comma:
                    out.append(','); pending_comma = False
                in_str = True; out.append(c)
            elif c == '/' and i + 1 < len(text) and text[i + 1] == '/':
                if pending_comma:
                    out.append(','); pending_comma = False
                while i < len(text) and text[i] != '\n':
                    i += 1
                continue
            elif c == ',':
                pending_comma = True
            elif c in ' \t\r\n':
                out.append(c)
            elif c in '}]':
                if not pending_comma:
                    out.append(c)
                else:
                    pending_comma = False
                    out.append(c)
            else:
                if pending_comma:
                    out.append(','); pending_comma = False
                out.append(c)
        i += 1
    return json.loads("".join(out))

settings_path = home / ".config/zed/settings.json"
with (assets / "settings.json").open() as f:
    defaults = jsonc_loads(f.read().replace("__HOME__", str(home)))

merged = {}
if settings_path.exists():
    try:
        merged = jsonc_loads(settings_path.read_text())
    except Exception:
        merged = {}

# Áp dụng cấu hình mặc định (font, theme, context_servers...), KHÔNG đụng "agent"
merged.update({k: v for k, v in defaults.items() if k != "agent"})
settings_path.write_text(json.dumps(merged, indent=2) + "\n")

# Đồng bộ skills (assets là nguồn chuẩn)
def make_writable(path):
    for root, dirs, files in os.walk(path, topdown=False):
        for f in files:
            os.chmod(os.path.join(root, f), 0o644)
        os.chmod(root, 0o755)
    os.chmod(path, 0o755)

skills_dst = home / ".config/zed/skills"
skills_dst.mkdir(parents=True, exist_ok=True)
for src in (assets / "skills").iterdir():
    if src.is_dir():
        dst = skills_dst / src.name
        if dst.exists():
            make_writable(dst)
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        make_writable(dst)
