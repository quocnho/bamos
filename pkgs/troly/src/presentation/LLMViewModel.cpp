#include "LLMViewModel.hpp"

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

} // namespace troly::presentation
