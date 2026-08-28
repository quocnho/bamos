import json, os, pathlib, re, shutil, sys

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

def load(p):
    if not p.exists():
        return {}
    try:
        return jsonc_loads(p.read_text())
    except Exception:
        return {}

# ---------- 1. IDE settings ----------
ide_dir = home / ".config/Antigravity IDE/User"
ide_dir.mkdir(parents=True, exist_ok=True)
settings_path = ide_dir / "settings.json"
merged = load(settings_path)
merged.update(load(assets / "settings.json"))
settings_path.write_text(json.dumps(merged, indent=2) + "\n")

# ---------- 2. MCP config (giữ entry người dùng đã chỉnh sửa) ----------
gemini = home / ".gemini/config"
gemini.mkdir(parents=True, exist_ok=True)
mcp_path = gemini / "mcp_config.json"
mcp = load(mcp_path)
servers = mcp.setdefault("mcpServers", {})

with (assets / "mcp_config.jsonc").open() as f:
    asset_mcp = jsonc_loads(f.read())["mcpServers"]

for name, cfg in asset_mcp.items():
    template = json.dumps(cfg, sort_keys=True).replace("__HOME__", str(home))
    if name not in servers:
        servers[name] = json.loads(template)  # thêm mới
    elif json.dumps(servers[name], sort_keys=True) == template:
        servers[name] = json.loads(template)  # giống template → đồng bộ lại (vd: thay __HOME__)
    # khác template → giữ nguyên bản người dùng đã sửa (không đè)

# Data Cloud (datacloud): ép tắt 2 MCP server remote — extension/IDE có thể
# ghi lại entry này (bỏ "disabled") mỗi lần khởi động; khi chưa có gcloud +
# project/region GCP thì chúng luôn báo lỗi kết nối. Bật lại khi cần:
# xoá 2 dòng dưới + làm theo README (mục "Data Cloud MCP").
for name in ("datacloud_dataproc_remote", "datacloud_knowledge_catalog_remote"):
    if name in servers:
        servers[name]["disabled"] = True

mcp_path.write_text(json.dumps(mcp, indent=2) + "\n")

# ---------- 3. Skills (assets là nguồn chuẩn) ----------
def make_writable(path):
    # Nix store file có mode 444/555 — copytree giữ nguyên nên phải sửa lại
    for root, dirs, files in os.walk(path, topdown=False):
        for f in files:
            os.chmod(os.path.join(root, f), 0o644)
        os.chmod(root, 0o755)
    os.chmod(path, 0o755)

skills_dst = gemini / "skills"
skills_dst.mkdir(parents=True, exist_ok=True)
for src in (assets / "skills").iterdir():
    if src.is_dir():
        dst = skills_dst / src.name
        if dst.exists():
            make_writable(dst)
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        make_writable(dst)
