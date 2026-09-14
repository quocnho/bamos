#pragma once

#include "../usecases/ISafetyGuard.hpp"
#include <regex>
#include <vector>
#include <string>
#include <algorithm>

namespace troly::infrastructure {

class DefaultSafetyGuard : public usecases::ISafetyGuard {
public:
    DefaultSafetyGuard() {
        initRules();
    }

    usecases::SafetyAssessment assessCommand(const std::string& command) override {
        usecases::SafetyAssessment assessment;
        assessment.level = usecases::RiskLevel::Safe;
        assessment.requiresExplicitConfirmation = false;

        if (command.empty()) {
            return assessment;
        }

        std::string lowerCmd = command;
        std::transform(lowerCmd.begin(), lowerCmd.end(), lowerCmd.begin(), ::tolower);

        // 1. Kiểm tra các lệnh HỦY HOẠI / BLOCKED tuyệt đối
        for (const auto& pattern : m_blockedPatterns) {
            if (std::regex_search(lowerCmd, pattern)) {
                assessment.level = usecases::RiskLevel::Blocked;
                assessment.reason = "Lệnh nguy hiểm bị chặn tuyệt đối (Rủi ro xóa toàn bộ hệ thống hoặc fork bomb).";
                assessment.requiresExplicitConfirmation = true;
                return assessment;
            }
        }

        // 2. Kiểm tra các lệnh CỰC KỲ NGUY HIỂM (DANGEROUS) -> Cần Human Confirmation
        for (const auto& pattern : m_dangerousPatterns) {
            if (std::regex_search(lowerCmd, pattern)) {
                assessment.level = usecases::RiskLevel::Dangerous;
                assessment.reason = "Lệnh can thiệp sâu vào tệp tin hoặc phân vùng hệ thống. Cần xác nhận từ người dùng.";
                assessment.requiresExplicitConfirmation = true;
                return assessment;
            }
        }

        // 3. Kiểm tra các lệnh THAY ĐỔI CẤU HÌNH HỆ THỐNG / SUDO (CAUTION)
        for (const auto& pattern : m_cautionPatterns) {
            if (std::regex_search(lowerCmd, pattern)) {
                assessment.level = usecases::RiskLevel::Caution;
                assessment.reason = "Lệnh yêu cầu quyền quản trị (sudo) hoặc cập nhật hệ điều hành NixOS.";
                assessment.requiresExplicitConfirmation = true;
                return assessment;
            }
        }

        assessment.reason = "Lệnh kiểm tra hoặc thao tác an toàn.";
        return assessment;
    }

    void logAudit(const std::string& command, const usecases::SafetyAssessment& assessment, bool executed) override {
        // Ghi log audit console / file
        (void)command;
        (void)assessment;
        (void)executed;
    }

private:
    std::vector<std::regex> m_blockedPatterns;
    std::vector<std::regex> m_dangerousPatterns;
    std::vector<std::regex> m_cautionPatterns;

    void initRules() {
        // Blocked: rm -rf /, mkfs, dd if=/dev/zero of=/dev/sd, :(){ :|:& };:
        m_blockedPatterns = {
            std::regex(R"(rm\s+-(r|f|rf|fr)\s+/((\s|$)|(\*)))"),
            std::regex(R"(mkfs(\.[a-z0-9]+)?\s+)"),
            std::regex(R"(dd\s+.*of=/dev/(sd[a-z]|nvme[0-9]n[0-9]|null|zero))"),
            std::regex(R"(\:\(\)\s*\{\s*\:\|\:\&\s*\}\s*\;)"), // fork bomb
            std::regex(R"(chmod\s+-R\s+777\s+/)")
        };

        // Dangerous: rm -rf bất kỳ, shred, fdisk, wipefs
        m_dangerousPatterns = {
            std::regex(R"(rm\s+-(r|f|rf|fr)\s+)"),
            std::regex(R"(shred\s+)"),
            std::regex(R"(fdisk\s+)"),
            std::regex(R"(wipefs\s+)"),
            std::regex(R"(killall\s+-9\s+)")
        };

        // Caution: sudo, nixos-rebuild, bam switch, systemctl restart/stop
        m_cautionPatterns = {
            std::regex(R"(\bsudo\b)"),
            std::regex(R"(nixos-rebuild\s+switch)"),
            std::regex(R"(bam\s+switch)"),
            std::regex(R"(systemctl\s+(stop|restart|disable|mask))")
        };
    }
};

} // namespace troly::infrastructure
