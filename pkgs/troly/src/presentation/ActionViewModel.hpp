#pragma once

#include <QObject>
#include <QString>
#include <memory>
#include "../usecases/ISafetyGuard.hpp"
#include "../usecases/IActionDispatcher.hpp"

namespace troly::presentation {

class ActionViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
    Q_PROPERTY(bool confirmationRequired READ confirmationRequired NOTIFY confirmationRequiredChanged)
    Q_PROPERTY(QString pendingCommand READ pendingCommand NOTIFY pendingCommandChanged)
    Q_PROPERTY(QString riskLevel READ riskLevel NOTIFY riskLevelChanged)
    Q_PROPERTY(QString riskReason READ riskReason NOTIFY riskReasonChanged)
    Q_PROPERTY(QString lastOutput READ lastOutput NOTIFY lastOutputChanged)
    Q_PROPERTY(int lastExitCode READ lastExitCode NOTIFY lastExitCodeChanged)

public:
    explicit ActionViewModel(
        std::shared_ptr<usecases::IActionDispatcher> dispatcher,
        std::shared_ptr<usecases::ISafetyGuard> safetyGuard,
        QObject* parent = nullptr
    );
    ~ActionViewModel() override = default;

    [[nodiscard]] bool isRunning() const { return m_isRunning; }
    [[nodiscard]] bool confirmationRequired() const { return m_confirmationRequired; }
    [[nodiscard]] QString pendingCommand() const { return m_pendingCommand; }
    [[nodiscard]] QString riskLevel() const { return m_riskLevel; }
    [[nodiscard]] QString riskReason() const { return m_riskReason; }
    [[nodiscard]] QString lastOutput() const { return m_lastOutput; }
    [[nodiscard]] int lastExitCode() const { return m_lastExitCode; }

    Q_INVOKABLE void requestExecuteCommand(const QString& cmd);
    Q_INVOKABLE void confirmPendingCommand();
    Q_INVOKABLE void rejectPendingCommand();
    Q_INVOKABLE void abortCurrentAction();
    Q_INVOKABLE QStringList listDirectory(const QString& path);
    Q_INVOKABLE QStringList searchFiles(const QString& dir, const QString& query);
    Q_INVOKABLE void validateNix(const QString& path);

signals:
    void isRunningChanged();
    void confirmationRequiredChanged();
    void pendingCommandChanged();
    void riskLevelChanged();
    void riskReasonChanged();
    void lastOutputChanged();
    void lastExitCodeChanged();
    void actionFinished(int exitCode, const QString& output);

private:
    std::shared_ptr<usecases::IActionDispatcher> m_dispatcher;
    std::shared_ptr<usecases::ISafetyGuard> m_safetyGuard;

    bool m_isRunning{false};
    bool m_confirmationRequired{false};
    QString m_pendingCommand;
    QString m_riskLevel{"Safe"};
    QString m_riskReason;
    QString m_lastOutput;
    int m_lastExitCode{0};

    void executeInternal(const QString& cmd);
};

} // namespace troly::presentation
