#include "LinuxActionDispatcher.hpp"
#include <QProcess>
#include <fstream>
#include <sstream>
#include <chrono>

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

} // namespace troly::infrastructure
