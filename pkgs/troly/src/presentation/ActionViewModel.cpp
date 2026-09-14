#include "ActionViewModel.hpp"
#include <QMetaObject>
#include <thread>

namespace troly::presentation {

ActionViewModel::ActionViewModel(
    std::shared_ptr<usecases::IActionDispatcher> dispatcher,
    std::shared_ptr<usecases::ISafetyGuard> safetyGuard,
    QObject* parent
)
    : QObject(parent)
    , m_dispatcher(std::move(dispatcher))
    , m_safetyGuard(std::move(safetyGuard)) {}

void ActionViewModel::requestExecuteCommand(const QString& cmd) {
    QString trimmed = cmd.trimmed();
    if (trimmed.isEmpty() || m_isRunning) return;

    if (m_safetyGuard) {
        auto assessment = m_safetyGuard->assessCommand(trimmed.toStdString());
        if (assessment.level == usecases::RiskLevel::Blocked) {
            m_lastExitCode = -1;
            m_lastOutput = "[BLOCKED]: " + QString::fromStdString(assessment.reason);
            emit lastExitCodeChanged();
            emit lastOutputChanged();
            emit actionFinished(-1, m_lastOutput);
            return;
        }

        if (assessment.requiresExplicitConfirmation) {
            m_pendingCommand = trimmed;
            m_riskReason = QString::fromStdString(assessment.reason);
            switch (assessment.level) {
                case usecases::RiskLevel::Dangerous: m_riskLevel = "Dangerous"; break;
                case usecases::RiskLevel::Caution:   m_riskLevel = "Caution"; break;
                default:                             m_riskLevel = "Safe"; break;
            }
            m_confirmationRequired = true;
            emit pendingCommandChanged();
            emit riskLevelChanged();
            emit riskReasonChanged();
            emit confirmationRequiredChanged();
            return;
        }
    }

    // Nếu là Safe thì thực thi ngay
    executeInternal(trimmed);
}

void ActionViewModel::confirmPendingCommand() {
    if (!m_confirmationRequired || m_pendingCommand.isEmpty()) return;

    QString cmdToRun = m_pendingCommand;
    m_confirmationRequired = false;
    m_pendingCommand.clear();
    emit confirmationRequiredChanged();
    emit pendingCommandChanged();

    executeInternal(cmdToRun);
}

void ActionViewModel::rejectPendingCommand() {
    if (!m_confirmationRequired) return;

    m_confirmationRequired = false;
    m_pendingCommand.clear();
    emit confirmationRequiredChanged();
    emit pendingCommandChanged();

    m_lastOutput = "[Đã từ chối thực thi bởi người dùng]";
    m_lastExitCode = 1;
    emit lastOutputChanged();
    emit lastExitCodeChanged();
    emit actionFinished(1, m_lastOutput);
}

void ActionViewModel::executeInternal(const QString& cmd) {
    m_isRunning = true;
    m_lastOutput.clear();
    emit isRunningChanged();
    emit lastOutputChanged();

    std::thread([this, cmd]() {
        domain::CommandResult res;
        if (m_dispatcher) {
            res = m_dispatcher->executeCommand(
                cmd.toStdString(),
                "",
                false,
                [this](const std::string& chunk) {
                    QString qChunk = QString::fromStdString(chunk);
                    QMetaObject::invokeMethod(this, [this, qChunk]() {
                        m_lastOutput += qChunk;
                        emit lastOutputChanged();
                    });
                }
            );
        }

        QMetaObject::invokeMethod(this, [this, res]() {
            m_isRunning = false;
            m_lastExitCode = res.exitCode;
            m_lastOutput = QString::fromStdString(res.output);
            emit isRunningChanged();
            emit lastExitCodeChanged();
            emit lastOutputChanged();
            emit actionFinished(res.exitCode, m_lastOutput);
        });
    }).detach();
}

void ActionViewModel::abortCurrentAction() {
    m_isRunning = false;
    emit isRunningChanged();
}

QStringList ActionViewModel::listDirectory(const QString& path) {
    QStringList result;
    if (m_dispatcher) {
        auto items = m_dispatcher->listDirectory(path.toStdString());
        for (const auto& it : items) {
            result.append(QString::fromStdString(it));
        }
    }
    return result;
}

QStringList ActionViewModel::searchFiles(const QString& dir, const QString& query) {
    QStringList result;
    if (m_dispatcher) {
        auto matches = m_dispatcher->searchInFiles(dir.toStdString(), query.toStdString());
        for (const auto& m : matches) {
            result.append(QString::fromStdString(m));
        }
    }
    return result;
}

void ActionViewModel::validateNix(const QString& path) {
    if (m_isRunning || !m_dispatcher) return;
    m_isRunning = true;
    emit isRunningChanged();

    std::thread([this, path]() {
        domain::CommandResult res = m_dispatcher->validateNixConfig(path.toStdString());
        QMetaObject::invokeMethod(this, [this, res]() {
            m_isRunning = false;
            m_lastExitCode = res.exitCode;
            m_lastOutput = QString::fromStdString(res.output);
            if (m_lastExitCode == 0 && m_lastOutput.isEmpty()) {
                m_lastOutput = "[Nix Config Check]: Cú pháp hợp lệ! ✅";
            }
            emit isRunningChanged();
            emit lastExitCodeChanged();
            emit lastOutputChanged();
            emit actionFinished(res.exitCode, m_lastOutput);
        });
    }).detach();
}

} // namespace troly::presentation
