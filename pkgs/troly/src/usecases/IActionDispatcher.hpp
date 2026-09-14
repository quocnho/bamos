#pragma once

#include "../domain/CommandResult.hpp"
#include <string>
#include <functional>
#include <stop_token>

namespace troly::usecases {

using OutputChunkCallback = std::function<void(const std::string& chunk)>;

class IActionDispatcher {
public:
    virtual ~IActionDispatcher() = default;

    virtual domain::CommandResult executeCommand(
        const std::string& command,
        const std::string& workingDir = "",
        bool allowSudo = false,
        OutputChunkCallback onOutput = nullptr,
        std::stop_token stopToken = {}
    ) = 0;

    virtual bool readFile(const std::string& path, std::string& outContent) = 0;
    virtual bool writeFile(const std::string& path, const std::string& content) = 0;
};

} // namespace troly::usecases
