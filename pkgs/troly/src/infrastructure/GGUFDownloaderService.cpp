#include "GGUFDownloaderService.hpp"

#include <QDir>
#include <QStandardPaths>
#include <QUrl>

namespace troly::infrastructure {

GGUFDownloaderService::GGUFDownloaderService(QObject* parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this)) {}

GGUFDownloaderService::~GGUFDownloaderService() {
    cancelDownload();
}

bool GGUFDownloaderService::isDownloading() const {
    return m_isDownloading;
}

double GGUFDownloaderService::progress() const {
    return m_progress;
}

QString GGUFDownloaderService::statusMessage() const {
    return m_statusMessage;
}

void GGUFDownloaderService::startDownload(const QString& urlStr, const QString& customFileName) {
    if (m_isDownloading) return;

    QUrl url(urlStr);
    if (!url.isValid()) {
        m_statusMessage = "URL tải xuống không hợp lệ!";
        emit downloadFailed(m_statusMessage);
        return;
    }

    QString fileName = customFileName;
    if (fileName.isEmpty()) {
        fileName = url.fileName();
        if (fileName.isEmpty() || !fileName.endsWith(".gguf")) {
            fileName = "custom_model.gguf";
        }
    }

    QString modelDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/models";
    QDir().mkpath(modelDir);
    m_targetFilePath = modelDir + "/" + fileName;

    m_outputFile = std::make_unique<QFile>(m_targetFilePath);
    if (!m_outputFile->open(QIODevice::WriteOnly)) {
        m_statusMessage = "Không thể ghi tệp: " + m_targetFilePath;
        emit downloadFailed(m_statusMessage);
        return;
    }

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setHeader(QNetworkRequest::UserAgentHeader, "Troly-Desktop-AI/1.0 (BamOS; Linux)");

    m_currentReply = m_networkManager->get(request);
    m_isDownloading = true;
    m_progress = 0.0;
    m_statusMessage = "Đang bắt đầu tải: " + fileName;
    emit progressChanged(m_progress);
    emit statusChanged(m_statusMessage);

    connect(m_currentReply, &QNetworkReply::downloadProgress, this, [this](qint64 bytesReceived, qint64 bytesTotal) {
        if (bytesTotal > 0) {
            m_progress = static_cast<double>(bytesReceived) / static_cast<double>(bytesTotal);
            emit progressChanged(m_progress);
        }
    });

    connect(m_currentReply, &QIODevice::readyRead, this, [this]() {
        if (m_outputFile && m_currentReply) {
            m_outputFile->write(m_currentReply->readAll());
        }
    });

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        m_isDownloading = false;
        if (m_currentReply->error() == QNetworkReply::NoError) {
            if (m_outputFile) {
                m_outputFile->flush();
                m_outputFile->close();
            }
            m_progress = 1.0;
            m_statusMessage = "Tải thành công: " + m_targetFilePath;
            emit progressChanged(m_progress);
            emit statusChanged(m_statusMessage);
            emit downloadCompleted(m_targetFilePath);
        } else {
            if (m_outputFile) {
                m_outputFile->close();
                m_outputFile->remove();
            }
            m_statusMessage = "Lỗi tải xuống: " + m_currentReply->errorString();
            emit statusChanged(m_statusMessage);
            emit downloadFailed(m_statusMessage);
        }
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    });
}

void GGUFDownloaderService::cancelDownload() {
    if (m_currentReply && m_isDownloading) {
        m_currentReply->abort();
        m_isDownloading = false;
        if (m_outputFile) {
            m_outputFile->close();
            m_outputFile->remove();
        }
        m_statusMessage = "Đã hủy tải xuống";
        emit statusChanged(m_statusMessage);
    }
}

} // namespace troly::infrastructure
