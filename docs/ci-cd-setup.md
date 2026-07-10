# 🔧 CI/CD Setup Guide — BamOS

Hướng dẫn thiết lập GitHub Actions cho BamOS, dựa trên pattern của **ublue-os** (Bazzite/Aurora/Bluefin).

## 🏗️ Kiến trúc Workflows

```
.github/workflows/
├── ci.yml           # 🔍 CI — PR + non-main pushes
├── release.yml      # 🚀 Release — Push to main
└── release-cd.yml   # 📤 CD — Tag push → Cloudflare R2
```

### Flow

```
Push to main
  └─► release.yml
       ├─► version: đọc VERSION, sinh tag (v4.0.0.YYYYMMDD.N)
       ├─► check: flake check + format
       ├─► build-iso: build 3 ISOs (gnome/kde/cosmic) song song
       │    ├─► Push store path lên Cachix
       │    └─► Upload ISO artifact
       ├─► generate-changelog: sinh changelog từ conventional commits
       ├─► release: tạo GitHub Release + tag
       └─► dispatch-cd: trigger release-cd.yml

Tag push v*
  └─► release-cd.yml
       ├─► download: tải ISOs từ GitHub Release
       ├─► upload-r2: đẩy lên Cloudflare R2
       ├─► sign: ký số ISOs với Cosign (optional)
       ├─► metadata: publish release-metadata.json
       └─► attest: build provenance attestation
```

## 🔑 GitHub Secrets Required

Truy cập: **Settings → Secrets and variables → Actions**

| Secret | Required | Description | How to Get |
|--------|----------|-------------|------------|
| `CACHIX_AUTH_TOKEN` | ✅ **Yes** | Auth token cho Cachix cache | `cachix authtoken` hoặc [Cachix Dashboard](https://bamos.cachix.org) |
| `R2_ACCESS_KEY_ID` | ✅ **Yes** | Cloudflare R2 Access Key ID | Cloudflare Dashboard → R2 → Manage R2 API Tokens |
| `R2_SECRET_ACCESS_KEY` | ✅ **Yes** | Cloudflare R2 Secret Access Key | Cloudflare Dashboard → R2 → Manage R2 API Tokens |
| `R2_ENDPOINT` | ✅ **Yes** | Cloudflare R2 endpoint URL | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` |
| `R2_BUCKET` | ❌ Optional | R2 bucket name (default: `bamos`) | Tên bucket bạn đã tạo |
| `R2_PUBLIC_URL` | ❌ Optional | Public URL cho R2 (default: `cdn.bamos.io`) | Cloudflare custom domain |
| `COSIGN_PRIVATE_KEY` | ❌ Optional | Cosign private key để ký ISO | `cosign generate-key-pair` |
| `COSIGN_PASSWORD` | ❌ Optional | Password cho Cosign key | Mật khẩu bảo vệ private key |

### Cách tạo R2 API Token

1. Vào [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Chọn **R2** → **Manage R2 API Tokens**
3. Click **Create API Token**
4. Permissions: `Read+Write` cho bucket `bamos`
5. Copy **Access Key ID** và **Secret Access Key**

### Cách tạo Cosign Key (Optional)

```bash
# Cài cosign
nix-shell -p cosign --run 'cosign generate-key-pair'

# Output:
# - cosign.key  → Private key → COSIGN_PRIVATE_KEY
# - cosign.pub  → Public key → Chia sẻ cho users

# Thêm password vào GitHub Secret: COSIGN_PASSWORD
```

## 🏷️ Version Strategy

Format: `v{VERSION}.{YYYYMMDD}.{BUILD}`

```
VERSION file: 4.0.0
Push to main hôm nay: v4.0.0.20260710.1  (build đầu tiên)
Push lại:             v4.0.0.20260710.2  (build thứ 2)
Hôm sau:              v4.0.0.20260711.1  (build đầu ngày mới)
```

## 🧪 Local Testing

### Validate workflow syntax
```bash
# Kiểm tra YAML syntax
python3 -c "
import yaml
for f in ['.github/workflows/ci.yml', '.github/workflows/release.yml', '.github/workflows/release-cd.yml']:
    with open(f) as fh:
        yaml.safe_load(fh)
    print(f'✅ {f}')
"
```

### Test changelog generation locally
```bash
python3 .github/scripts/generate-changelog.py \
  "$(git tag --sort=-creatordate | head -1)" \
  "v4.0.0.20260710.test" \
  "quocnho/bamos"
```

## ☁️ Cloudflare R2 Structure

```
R2 Bucket: bamos/
├── releases/
│   ├── v4.0.0.20260710.1/
│   │   ├── bamos-gnome-v4.0.0.20260710.1.iso
│   │   ├── bamos-gnome-v4.0.0.20260710.1.iso.sha256
│   │   ├── bamos-kde-v4.0.0.20260710.1.iso
│   │   ├── bamos-kde-v4.0.0.20260710.1.iso.sha256
│   │   ├── bamos-cosmic-v4.0.0.20260710.1.iso
│   │   ├── bamos-cosmic-v4.0.0.20260710.1.iso.sha256
│   │   ├── *.iso.sig (optional, Cosign)
│   │   ├── *.iso.crt (optional, Cosign)
│   │   └── release-metadata.json
│   ├── v4.0.0.20260710.2/
│   │   └── ...
│   └── latest/  ← symlink đến release mới nhất
│       ├── bamos-gnome-latest.iso
│       ├── ...
│       └── release-metadata.json
```

## 📝 Release Notes Format

Mỗi release có changelog tự động sinh từ **conventional commits**:

```markdown
## What Changed (since v4.0.0.20260709.1)

### ✨ Features
- [abc1234](https://github.com/quocnho/bamos/commit/abc1234) — Add unified ISO builder (quocnho)
- [def5678](https://github.com/quocnho/bamos/commit/def5678) — Implement Calamares edition selector (quocnho)

### 🐛 Bug Fixes
- [ghi9012](https://github.com/quocnho/bamos/commit/ghi9012) — Fix NVIDIA detection in auto-detect (quocnho)

### 🔧 Chores
- [jkl3456](https://github.com/quocnho/bamos/commit/jkl3456) — Update flake.lock (quocnho)

---
**Full Changelog:** https://github.com/quocnho/bamos/compare/v4.0.0.20260709.1...v4.0.0.20260710.1
```

## 🔄 So sánh: ublue-os pattern vs BamOS

| Aspect | ublue-os (Bazzite) | BamOS |
|--------|-------------------|-------|
| **Base** | Fedora Atomic (containers) | NixOS (Nix flakes) |
| **Artifact Registry** | GHCR (containers) | Cachix (Nix store) |
| **Build** | buildah → container image | `nix build` → ISO |
| **ISO Source** | Container image via Titanoboa | `nixosConfigurations.config.system.build.image` |
| **Cloud Upload** | rclone → Cloudflare R2 | rclone → Cloudflare R2 |
| **Tag Strategy** | FedoraVersion.Date.Build | VERSION.YYYYMMDD.BUILD |
| **Changelog** | SBOM + git log | Git log (conventional commits) |
| **Signing** | Cosign | Cosign (optional) |
| **Metadata** | JSON per release | JSON per release + latest |

## 🚦 First-time Setup Checklist

- [ ] Add `CACHIX_AUTH_TOKEN` to GitHub Secrets
- [ ] Create R2 bucket + API Token → add `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`
- [ ] (Optional) Setup custom domain → add `R2_PUBLIC_URL`
- [ ] (Optional) Generate Cosign key → add `COSIGN_PRIVATE_KEY`, `COSIGN_PASSWORD`
- [ ] Push to `main` → kiểm tra release.yml chạy thành công
- [ ] Kiểm tra GitHub Release được tạo tự động
- [ ] Kiểm tra ISO trên Cloudflare R2
- [ ] Kiểm tra Cachix cache: `nix build github:quocnho/bamos#iso-gnome`
