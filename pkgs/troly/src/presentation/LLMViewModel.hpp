#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <memory>
#include "../infrastructure/DynamicMoERouter.hpp"

namespace troly::presentation {

class LLMViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(QString activeModelName READ activeModelName NOTIFY activeModelNameChanged)
    Q_PROPERTY(QString activeIntent READ activeIntent NOTIFY activeIntentChanged)
    Q_PROPERTY(float temperature READ temperature WRITE setTemperature NOTIFY temperatureChanged)
    Q_PROPERTY(int contextSize READ contextSize WRITE setContextSize NOTIFY contextSizeChanged)
    Q_PROPERTY(int gpuLayers READ gpuLayers WRITE setGpuLayers NOTIFY gpuLayersChanged)
    Q_PROPERTY(QStringList availableModels READ availableModels NOTIFY availableModelsChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString connectionStatus READ connectionStatus NOTIFY connectionStatusChanged)

public:
    explicit LLMViewModel(std::shared_ptr<infrastructure::DynamicMoERouter> router, QObject* parent = nullptr);
    ~LLMViewModel() override = default;

    [[nodiscard]] QString serverUrl() const { return m_serverUrl; }
    [[nodiscard]] QString activeModelName() const { return m_activeModelName; }
    [[nodiscard]] QString activeIntent() const { return m_activeIntent; }
    [[nodiscard]] float temperature() const { return m_temperature; }
    [[nodiscard]] int contextSize() const { return m_contextSize; }
    [[nodiscard]] int gpuLayers() const { return m_gpuLayers; }
    [[nodiscard]] QStringList availableModels() const { return m_availableModels; }
    [[nodiscard]] bool isConnected() const { return m_isConnected; }
    [[nodiscard]] QString connectionStatus() const { return m_connectionStatus; }

    void setServerUrl(const QString& url);
    void setTemperature(float temp);
    void setContextSize(int size);
    void setGpuLayers(int layers);

    Q_INVOKABLE void testConnection();
    Q_INVOKABLE void selectModel(int index);
    Q_INVOKABLE void evaluateQueryIntent(const QString& query);

signals:
    void serverUrlChanged();
    void activeModelNameChanged();
    void activeIntentChanged();
    void temperatureChanged();
    void contextSizeChanged();
    void gpuLayersChanged();
    void availableModelsChanged();
    void isConnectedChanged();
    void connectionStatusChanged();

private:
    std::shared_ptr<infrastructure::DynamicMoERouter> m_router;
    QString m_serverUrl{"http://127.0.0.1:9090"};
    QString m_activeModelName{"Qwen2.5-3B-Instruct (General)"};
    QString m_activeIntent{"GeneralChat"};
    float m_temperature{0.7f};
    int m_contextSize{4096};
    int m_gpuLayers{33};
    QStringList m_availableModels;
    bool m_isConnected{true};
    QString m_connectionStatus{"Sẵn sàng (Local SSE)"};
};

} // namespace troly::presentation
