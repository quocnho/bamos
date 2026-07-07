# Key Metrics

## Current State

### AARRR Framework (Pirate Metrics) — Adapted for Open Source Distro

| Giai đoạn | Metric | Target (6 tháng) | Target (12 tháng) | Hiện tại |
|-----------|--------|-----------------|-------------------|----------|
| **Awareness** | GitHub stars | 500 | 2,000 | ~1 |
| **Awareness** | Website visits/tháng | 5,000 | 20,000 | 0 |
| **Acquisition** | ISO downloads/tháng | 500 | 2,000 | 0 |
| **Activation** | Successful installs | 60% của downloads | 70% | — |
| **Retention** | Active users (30-day) | 40% của installs | 50% | — |
| **Revenue** | Monthly donations | $0 | $50-200 | $0 |
| **Referral** | Word-of-mouth mentions | 50/tháng | 200/tháng | — |

### Quality Metrics (Technical)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **ISO build success rate** | > 95% | CI/CD pipeline |
| **Build time (1 ISO)** | < 60 min | GitHub Actions logs |
| **Build time (12 ISOs)** | < 6 hours | GitHub Actions logs |
| **ISO size** | < 3GB each | `nix path-info` |
| **Installation time** | < 30 min | User testing |
| **Rollback time** | < 2 min | Boot test |
| **Reproducibility** | 100% | Same hash from same commit |

### Community Health Metrics

| Metric | Target (12 tháng) | Hiện tại |
|--------|-------------------|----------|
| **Contributors** | 10+ active | 1 |
| **GitHub Issues (open)** | < 20 | 0 |
| **PR merge time** | < 48 hours | — |
| **Documentation coverage** | 100% features | ~30% |

## Hypotheses
- ISO downloads sẽ tăng 50%/tháng trong 6 tháng đầu sau launch
- Tỷ lệ install thành công > 60% nếu Calamares hoạt động tốt
- 80% users sẽ ở lại nếu gõ tiếng Việt hoạt động OOTB

## Validated Learning
[To be filled — sau khi có ISO và bắt đầu phân phối]

## Action Items
- [ ] Thiết lập GitHub Actions metrics dashboard
- [ ] Thiết lập download counter cho ISO
- [ ] Tạo form feedback cho người dùng thử nghiệm
- [ ] Theo dõi Cachix cache hit rate

## Last Updated
2026-07-03
