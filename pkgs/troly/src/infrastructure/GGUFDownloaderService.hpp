#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>
#include <memory>

namespace troly::infrastructure {

class GGUFDownloaderService : public QObject {
    Q_OBJECT

public:
    explicit GGUFDownloaderService(QObject* parent = nullptr);
    ~GGUFDownloaderService() override;

    [[nodiscard]] bool isDownloading() const;
    [[nodiscard]] double progress() const;
    [[nodiscard]] QString statusMessage() const;

    void startDownload(const QString& urlStr, const QString& customFileName = "");
    void cancelDownload();

signals:
    void progressChanged(double progress);
    void statusChanged(const QString& status);
    void downloadCompleted(const QString& filePath);
    void downloadFailed(const QString& error);

private:
    QNetworkAccessManager* m_networkManager{nullptr};
    QNetworkReply* m_currentReply{nullptr};
    std::unique_ptr<QFile> m_outputFile;
    QString m_targetFilePath;
    QString m_statusMessage{"Sẵn sàng"};
    double m_progress{0.0};
    bool m_isDownloading{false};
};

} // namespace troly::infrastructure
