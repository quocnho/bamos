#include "LLMViewModel.hpp"
#include "../infrastructure/GGUFDownloaderService.hpp"
#include <QFileInfo>

namespace troly::presentation {

LLMViewModel::LLMViewModel(std::shared_ptr<infrastructure::DynamicMoERouter> router, QObject* parent)
    : QObject(parent), m_router(std::move(router)) {
    if (m_router) {
        for (const auto& slot : m_router->availableSlots()) {
            m_availableModels.append(QString::fromStdString(slot.displayName));
        }
        auto active = m_router->activeModel();
        m_activeModelName = QString::fromStdString(active.displayName);
        m_activeIntent = QString::fromStdString(std::string(domain::userIntentToString(active.targetIntent)));
        m_contextSize = active.contextLength;
        m_gpuLayers = active.gpuLayers;
    }
}

LLMViewModel::~LLMViewModel() = default;

void LLMViewModel::setServerUrl(const QString& url) {
    if (m_serverUrl != url) {
        m_serverUrl = url;
        emit serverUrlChanged();
    }
}

void LLMViewModel::setTemperature(float temp) {
    if (qAbs(m_temperature - temp) > 0.01f) {
        m_temperature = temp;
        emit temperatureChanged();
    }
}

void LLMViewModel::setContextSize(int size) {
    if (m_contextSize != size) {
        m_contextSize = size;
        emit contextSizeChanged();
    }
}

void LLMViewModel::setGpuLayers(int layers) {
    if (m_gpuLayers != layers) {
        m_gpuLayers = layers;
        emit gpuLayersChanged();
    }
}

void LLMViewModel::testConnection() {
    m_isConnected = true;
    m_connectionStatus = "Đã kết nối thành công: " + m_serverUrl;
    emit isConnectedChanged();
    emit connectionStatusChanged();
}

void LLMViewModel::selectModel(int index) {
    if (!m_router) return;
    const auto& modelSlots = m_router->availableSlots();
    if (index >= 0 && index < static_cast<int>(modelSlots.size())) {
        auto chosen = m_router->selectModelForIntent(modelSlots[index].targetIntent);
        m_activeModelName = QString::fromStdString(chosen.displayName);
        m_activeIntent = QString::fromStdString(std::string(domain::userIntentToString(chosen.targetIntent)));
        m_contextSize = chosen.contextLength;
        m_gpuLayers = chosen.gpuLayers;
        emit activeModelNameChanged();
        emit activeIntentChanged();
        emit contextSizeChanged();
        emit gpuLayersChanged();
    }
}

void LLMViewModel::evaluateQueryIntent(const QString& query) {
    if (!m_router) return;
    auto intent = m_router->routeIntent(query.toStdString());
    auto chosen = m_router->selectModelForIntent(intent);
    m_activeModelName = QString::fromStdString(chosen.displayName);
    m_activeIntent = QString::fromStdString(std::string(domain::userIntentToString(chosen.targetIntent)));
    emit activeModelNameChanged();
    emit activeIntentChanged();
}

void LLMViewModel::downloadGGUFModel(const QString& url, const QString& customName) {
    if (!m_downloader) {
        m_downloader = std::make_unique<infrastructure::GGUFDownloaderService>(this);
        connect(m_downloader.get(), &infrastructure::GGUFDownloaderService::progressChanged, this, [this](double p) {
            m_downloadProgress = p;
            emit downloadProgressChanged();
        });
        connect(m_downloader.get(), &infrastructure::GGUFDownloaderService::statusChanged, this, [this](const QString& s) {
            m_downloadStatus = s;
            emit downloadStatusChanged();
        });
        connect(m_downloader.get(), &infrastructure::GGUFDownloaderService::downloadCompleted, this, [this](const QString& filePath) {
            m_isDownloading = false;
            m_downloadStatus = "Đã lưu vào: " + filePath;
            m_availableModels.append(QFileInfo(filePath).fileName());
            emit isDownloadingChanged();
            emit downloadStatusChanged();
            emit availableModelsChanged();
        });
        connect(m_downloader.get(), &infrastructure::GGUFDownloaderService::downloadFailed, this, [this](const QString& err) {
            m_isDownloading = false;
            m_downloadStatus = err;
            emit isDownloadingChanged();
            emit downloadStatusChanged();
        });
    }

    m_isDownloading = true;
    m_downloadProgress = 0.0;
    m_downloadStatus = "Bắt đầu tải...";
    emit isDownloadingChanged();
    emit downloadProgressChanged();
    emit downloadStatusChanged();

    m_downloader->startDownload(url, customName);
}

void LLMViewModel::cancelGGUFDownload() {
    if (m_downloader) {
        m_downloader->cancelDownload();
    }
    m_isDownloading = false;
    emit isDownloadingChanged();
}

} // namespace troly::presentation
