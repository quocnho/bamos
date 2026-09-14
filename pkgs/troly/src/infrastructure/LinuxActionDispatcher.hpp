#pragma once

#include "../usecases/IActionDispatcher.hpp"
#include <QObject>

namespace troly::infrastructure {

class LinuxActionDispatcher : public usecases::IActionDispatcher {
public:
    LinuxActionDispatcher();
    ~LinuxActionDispatcher() override;

    domain::CommandResult executeCommand(
        const std::string& command,
        const std::string& workingDir = "",
        bool allowSudo = false,
        usecases::OutputChunkCallback onOutput = nullptr,
        std::stop_token stopToken = {}
    ) override;

    bool readFile(const std::string& path, std::string& outContent) override;
    bool writeFile(const std::string& path, const std::string& content) override;
    std::vector<std::string> listDirectory(const std::string& path) override;
    std::vector<std::string> searchInFiles(const std::string& directory, const std::string& query) override;
    domain::CommandResult validateNixConfig(const std::string& configPath) override;
};

} // namespace troly::infrastructure
