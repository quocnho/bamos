# Cost Structure

## Current State

Chi phí hiện tại và dự kiến cho dự án:

| Chi phí | Hàng tháng | Hàng năm | Bắt buộc? |
|---------|-----------|----------|-----------|
| **Cachix Binary Cache** (5GB) | ~$0 (free tier) | $0 | ✅ Có |
| **Cachix Binary Cache** (50GB+) | ~$20 | ~$240 | ⚠️ Khi scale |
| **GitHub Actions** | $0 (public repo) | $0 | ✅ Có |
| **Domain (bamos.vn)** | — | ~$15 | ⚠️ Phase 7 |
| **Web hosting** | ~$0 (GitHub Pages) | $0 | — |
| **CI runners (self-hosted)** | ~$0 (máy cá nhân) | $0 | — |
| **TỔNG HIỆN TẠI** | **$0** | **$0** | |
| **TỔNG DỰ KIẾN (Phase 7+)** | **~$20** | **~$255/yr** | |

### Key Cost Drivers
1. **Cachix storage**: Mỗi ISO build ~2-3GB cache. 12 variants × weekly builds = cần ~50-100GB
2. **Build time**: 12 variants × 30-60 min = 6-12 giờ build. Cần distributed builds hoặc cache tốt
3. **Bandwidth**: Mỗi ISO download ~2.5GB. Với 1000 users = 2.5TB bandwidth

### Cost Optimization
- Sử dụng Cachix free tier (5GB) trong giai đoạn đầu
- GitHub Releases cho ISO distribution (free, unlimited bandwidth)
- Tự host CI runner trên máy cá nhân cho build nặng
- Cân nhắc mirror tại Việt Nam khi có > 1000 users

## Hypotheses
- Có thể duy trì chi phí $0 trong suốt Phase 3-6
- Cần Cachix paid tier (>5GB) khi build đủ 12 variants weekly
- Chi phí bandwidth sẽ là vấn đề khi có > 10,000 users

## Validated Learning
- Phase 1-2 đã hoàn thành với chi phí $0
- GitHub Actions free tier đủ cho nix flake check + format check
- Cần đánh giá Cachix cache size sau khi build ISO đầu tiên

## Action Items
- [ ] Monitor Cachix cache size sau mỗi CI build
- [ ] Đăng ký Cachix paid tier khi cần (>5GB)
- [ ] Nghiên cứu mirror options tại Việt Nam (Viettel IDC, VNPT)

## Last Updated
2026-07-03
