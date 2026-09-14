#pragma once

#include <string>

namespace troly::usecases {

enum class RiskLevel {
    Safe,
    Caution,
    Dangerous,
    Blocked
};

struct SafetyAssessment {
    RiskLevel level{RiskLevel::Safe};
    std::string reason;
    bool requiresExplicitConfirmation{false};
};

class ISafetyGuard {
public:
    virtual ~ISafetyGuard() = default;

    virtual SafetyAssessment assessCommand(const std::string& command) = 0;
    virtual void logAudit(const std::string& command, const SafetyAssessment& assessment, bool executed) = 0;
};

} // namespace troly::usecases
