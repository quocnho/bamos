#include "LinuxActionDispatcher.hpp"
#include <QProcess>
#include <fstream>
#include <sstream>
#include <chrono>
#include <filesystem>
#include <vector>

namespace troly::infrastructure {

LinuxActionDispatcher::LinuxActionDispatcher() = default;
LinuxActionDispatcher::~LinuxActionDispatcher() = default;

domain::CommandResult LinuxActionDispatcher::executeCommand(
    const std::string& command,
    const std::string& workingDir,
    bool allowSudo,
    usecases::OutputChunkCallback onOutput,
    std::stop_token stopToken
) {
    domain::CommandResult result;
    result.command = command;
    auto startTime = std::chrono::steady_clock::now();

    QProcess process;
    if (!workingDir.empty()) {
        process.setWorkingDirectory(QString::fromStdString(workingDir));
    }

    // Đảm bảo hỗ trợ đường dẫn NixOS /run/current-system/sw/bin
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    process.setProcessEnvironment(env);

    process.start(QStringLiteral("bash"), QStringList() << QStringLiteral("-c") << QString::fromStdString(command));
    if (!process.waitForStarted(3000)) {
        result.output = "Không thể khởi chạy bash process";
        result.exitCode = -1;
        return result;
    }

    while (!process.waitForFinished(100)) {
        if (stopToken.stop_requested()) {
            process.terminate();
            process.waitForFinished(500);
            result.output += "\n[Đã ngắt bởi người dùng]";
            result.exitCode = 130;
            return result;
        }
        QByteArray chunk = process.readAllStandardOutput();
        if (!chunk.isEmpty() && onOutput) {
            onOutput(chunk.toStdString());
        }
    }

    QByteArray stdOut = process.readAllStandardOutput();
    QByteArray stdErr = process.readAllStandardError();
    result.output = (stdOut + stdErr).toStdString();
    result.exitCode = process.exitCode();

    auto endTime = std::chrono::steady_clock::now();
    result.durationMs = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime).count();

    return result;
}

bool LinuxActionDispatcher::readFile(const std::string& path, std::string& outContent) {
    std::ifstream file(path);
    if (!file.is_open()) return false;
    std::stringstream buffer;
    buffer << file.rdbuf();
    outContent = buffer.str();
    return true;
}

bool LinuxActionDispatcher::writeFile(const std::string& path, const std::string& content) {
    std::ofstream file(path);
    if (!file.is_open()) return false;
    file << content;
    return true;
}

std::vector<std::string> LinuxActionDispatcher::listDirectory(const std::string& path) {
    std::vector<std::string> results;
    try {
        if (!std::filesystem::exists(path) || !std::filesystem::is_directory(path)) {
            return results;
        }
        for (const auto& entry : std::filesystem::directory_iterator(path)) {
            std::string item = entry.path().filename().string();
            if (entry.is_directory()) {
                item += "/";
            }
            results.push_back(item);
        }
    } catch (...) {
        // Safe fallback
    }
    return results;
}

std::vector<std::string> LinuxActionDispatcher::searchInFiles(const std::string& directory, const std::string& query) {
    std::vector<std::string> matches;
    if (query.empty() || !std::filesystem::exists(directory)) {
        return matches;
    }
    try {
        for (const auto& entry : std::filesystem::recursive_directory_iterator(directory, std::filesystem::directory_options::skip_permission_denied)) {
            if (entry.is_regular_file()) {
                // Tránh quét file nhị phân lớn hoặc thư mục git/build
                std::string pathStr = entry.path().string();
                if (pathStr.find("/.git/") != std::string::npos || pathStr.find("/build/") != std::string::npos) {
                    continue;
                }
                std::ifstream file(entry.path());
                if (!file.is_open()) continue;
                std::string line;
                int lineNum = 1;
                while (std::getline(file, line)) {
                    if (line.find(query) != std::string::npos) {
                        matches.push_back(entry.path().string() + ":" + std::to_string(lineNum) + ": " + line);
                        if (matches.size() >= 50) break; // Giới hạn tối đa 50 kết quả
                    }
                    lineNum++;
                }
                if (matches.size() >= 50) break;
            }
        }
    } catch (...) {
        // Safe fallback
    }
    return matches;
}

domain::CommandResult LinuxActionDispatcher::validateNixConfig(const std::string& configPath) {
    std::string cmd = "nix-instantiate --parse " + configPath + " > /dev/null 2>&1";
    if (configPath.find("flake.nix") != std::string::npos || std::filesystem::is_directory(configPath)) {
        cmd = "nix flake check --no-build " + configPath + " 2>&1";
    }
    return executeCommand(cmd);
}

} // namespace troly::infrastructure

