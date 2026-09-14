#pragma once

#include <string>
#include <cstdint>

namespace troly::domain {

struct CommandResult {
    std::string command;
    std::string output;
    int32_t exitCode{0};
    int64_t durationMs{0};
    bool isSudo{false};
    bool isSafe{true};
};

} // namespace troly::domain
