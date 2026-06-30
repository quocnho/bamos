# Contributing to BamOS

Cảm ơn bạn đã quan tâm đóng góp cho BamOS! / Thank you for your interest in contributing to BamOS!

## 🌐 Ngôn ngữ | Language

- **Code, scripts, technical docs**: English (for international collaboration)
- **User-facing documentation**: Vietnamese + English
- **Commit messages**: English
- **Issues & PRs**: Either Vietnamese or English

## 🚀 Bắt đầu | Getting Started

### 1. Fork repository

Fork the [bamos](https://github.com/quocnho/bamos) repository to your GitHub account.

### 2. Clone và setup | Clone and setup

```bash
git clone https://github.com/YOUR_USERNAME/bamos.git
cd bamos

# Install development dependencies
sudo dnf install podman just

# Test build
just build-gnome
```

### 3. Tạo branch | Create a branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-fix-name
```

## 📋 Quy trình đóng góp | Contribution Workflow

1. **Fork** the repository
2. **Create** a feature/fix branch
3. **Make changes** following the project conventions
4. **Test** your changes locally (`just build-gnome` or `just build-kde`)
5. **Commit** with clear, descriptive messages
6. **Push** to your fork
7. **Create** a Pull Request

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example:
```
feat(vn-input): add ibus-bamboo configuration for Wayland

Configured ibus-bamboo with Telex as default Vietnamese input method.
Added Super+Space shortcut for switching between EN/VN.

Closes #42
```

## 🎯 Các lĩnh vực cần đóng góp | Areas to Contribute

### 🖥️ Desktop Configuration
- GNOME extensions and settings
- KDE Plasma themes and layouts (Windows 11-like)
- Wallpaper and icon themes

### 🇻🇳 Vietnamese Integration
- Input method improvements
- Font configurations
- Locale and translation updates

### 📦 Package Management
- Adding/updating package lists
- Testing package compatibility
- Optimizing package selection

### 🛠️ Scripts & Automation
- Setup script improvements
- Justfile commands
- CI/CD pipeline enhancements

### 📚 Documentation
- Vietnamese translation of docs
- User guides and tutorials
- Installation guides

### 🐛 Bug Fixes
- Testing and reporting issues
- Fixing container build errors
- Desktop environment bugs

## ✅ Tiêu chuẩn code | Code Standards

### Shell Scripts

```bash
#!/bin/bash
# Use descriptive comments
set -e  # Exit on error

# Use meaningful variable names
VIETNAMESE_FONT_DIR="/usr/share/fonts/vietnamese"

# Handle errors gracefully
if ! command -v ibus-daemon &> /dev/null; then
    echo "Warning: ibus-daemon not found" >&2
    exit 1
fi
```

### Containerfile Guidelines

- Use multi-stage builds when appropriate
- Clean up temporary files
- Add meaningful LABELs
- Use specific version tags for base images

### Recipe YAML

- Follow the BlueBuild recipe format
- Document all module purposes
- Use consistent indentation (2 spaces)

## 🧪 Testing

```bash
# Build and test locally
just build-gnome
podman run --rm -it bamos-gnome:local /bin/bash -c "ibus engine"

# Validate Containerfile
just validate

# Run CI validation locally
act pull_request
```

## 📄 Pull Request Process

1. Ensure your PR description clearly describes the problem and solution
2. Include screenshots for visual changes
3. Update relevant documentation
4. Ensure CI validation passes
5. Request review from a core maintainer
6. Address review feedback

## 🤝 Quy tắc ứng xử | Code of Conduct

Please read our [Code of Conduct](docs/CODE_OF_CONDUCT.md). We are committed to providing a welcoming and inclusive environment.

## 📞 Liên hệ | Contact

- **Issues**: [GitHub Issues](https://github.com/quocnho/bamos/issues)
- **Discussions**: [GitHub Discussions](https://github.com/quocnho/bamos/discussions)

---

**Cảm ơn bạn đã đóng góp cho cộng đồng BamOS!** 🎋
