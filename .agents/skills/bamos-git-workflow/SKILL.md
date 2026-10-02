---
name: bamos-git-workflow
description: Standard Git workflow, AA.BB.CC versioning enforcement, Conventional Commits, and branch invariants for BamOS and BamApps repositories.
---

# BamOS Git Workflow & Versioning Skill

Sử dụng quy chuẩn này cho toàn bộ hoạt động quản lý phiên bản và release trong hệ sinh thái BamOS & BamApps:

## 1. Chuẩn Hóa Phiên Bản (`AA.BB.CC`)
- **Định dạng**: `AA.BB.CC`
  - **`AA`**: 2 chữ số cuối của năm (ví dụ năm 2026 -> `26`).
  - **`BB`**: Đường ray kiến trúc cốt lõi / Core Milestone (mặc định `01`).
  - **`CC`**: Đợt phát hành lớn / Sprint milestone (bắt đầu từ `01`, tăng `+1` sau mỗi lần phát hành/sprint).
- **Git Tagging**: Mỗi khi merge hoàn tất vào nhánh `main`, tạo annotated tag:
  ```bash
  git tag -a v26.01.CC -m "Release v26.01.CC"
  ```

## 2. Chiến Lược Nhánh (Branch Strategy)
- **Nhánh mặc định cho lập trình**: `develop`. Mọi commit, thay đổi tính năng, sửa lỗi hàng ngày PHẢI diễn ra trên nhánh `develop`.
- **Nhánh Production / Stable**: `main`. CHỈ merge từ `develop` vào `main` khi xong một sprint hoặc có đợt phát hành ISO / App release chính thức.
- **Quy trình Release**:
  ```bash
  git checkout main
  git merge --no-ff develop -m "release: vAA.BB.CC sprint milestone"
  git tag -a vAA.BB.CC -m "Release vAA.BB.CC"
  git push origin main --tags
  git checkout develop
  ```

## 3. Quy Chuẩn Commit (Conventional Commits)
- `feat(scope)`: Tính năng hoặc module mới (vd: `feat(installer): add GPU auto-detection module`)
- `fix(scope)`: Sửa lỗi (vd: `fix(audio): auto heal analog codec service`)
- `refactor(scope)`: Tái cấu trúc mã nguồn mà không đổi logic hành vi
- `perf(scope)`: Cải thiện hiệu năng khởi động, bộ nhớ
- `docs(scope)`: Cập nhật tài liệu
- `chore(scope)`: Nâng cấp flake lock, bump version, cấu hình CI/CD
- **Scopes phổ biến**: `boot`, `gpu`, `audio`, `gnome`, `installer`, `customizer`, `notes`, `cli`, `assets`, `agile`

## 4. Tuyệt Đối Không Commit File Rác (Zero Bloat Invariant)
- Không commit: `result`, `result-*`, `*.iso`, `.direnv`, `.devenv`, `target/`, `node_modules/`, `*.swp`.
