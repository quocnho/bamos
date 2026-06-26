#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: Post-Build ==="

# ── Set default hostname ─────────────────────────────────────────────────────
echo "bamos" > /etc/hostname

# ── Rename real dnf5 and create wrappers (like RakuOS) ──────────────────────
mv /usr/bin/dnf5 /usr/bin/dnf5.real 2>/dev/null || true
mv /usr/bin/dnf /usr/bin/dnf.real 2>/dev/null || true

# Mark all base image packages as dependency
dnf5.real -y mark dependency $(rpm -qa --qf '%{NAME} ') --skip-unavailable 2>/dev/null || true

# Create dnf5 wrapper that routes install/remove/update through bamos
cat > /usr/bin/dnf5 << 'WRAPPER'
#!/usr/bin/env bash
COMMAND="${1:-}"
case "$COMMAND" in
    install)
        shift
        exec bamos install "$@"
        ;;
    update|upgrade)
        shift
        exec bamos update "$@"
        ;;
    remove|erase)
        shift
        exec bamos remove "$@"
        ;;
    *)
        exec /usr/bin/dnf5.real "$@"
        ;;
esac
WRAPPER

# Create dnf wrapper
cat > /usr/bin/dnf << 'WRAPPER'
#!/usr/bin/env bash
exec /usr/bin/dnf5 "$@"
WRAPPER

chmod +x /usr/bin/dnf5 /usr/bin/dnf

echo "=== BamOS: Post-Build Complete ==="
