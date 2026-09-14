#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <memory>
#include "../infrastructure/DynamicMoERouter.hpp"

namespace troly::infrastructure {
class GGUFDownloaderService;
}

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
    Q_PROPERTY(bool isDownloading READ isDownloading NOTIFY isDownloadingChanged)
    Q_PROPERTY(double downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(QString downloadStatus READ downloadStatus NOTIFY downloadStatusChanged)

public:
    explicit LLMViewModel(std::shared_ptr<infrastructure::DynamicMoERouter> router, QObject* parent = nullptr);
    ~LLMViewModel() override;

    [[nodiscard]] QString serverUrl() const { return m_serverUrl; }
    [[nodiscard]] QString activeModelName() const { return m_activeModelName; }
    [[nodiscard]] QString activeIntent() const { return m_activeIntent; }
    [[nodiscard]] float temperature() const { return m_temperature; }
    [[nodiscard]] int contextSize() const { return m_contextSize; }
    [[nodiscard]] int gpuLayers() const { return m_gpuLayers; }
    [[nodiscard]] QStringList availableModels() const { return m_availableModels; }
    [[nodiscard]] bool isConnected() const { return m_isConnected; }
    [[nodiscard]] QString connectionStatus() const { return m_connectionStatus; }
    [[nodiscard]] bool isDownloading() const { return m_isDownloading; }
    [[nodiscard]] double downloadProgress() const { return m_downloadProgress; }
    [[nodiscard]] QString downloadStatus() const { return m_downloadStatus; }

    void setServerUrl(const QString& url);
    void setTemperature(float temp);
    void setContextSize(int size);
    void setGpuLayers(int layers);

    Q_INVOKABLE void testConnection();
    Q_INVOKABLE void selectModel(int index);
    Q_INVOKABLE void evaluateQueryIntent(const QString& query);
    Q_INVOKABLE void downloadGGUFModel(const QString& url, const QString& customName = "");
    Q_INVOKABLE void cancelGGUFDownload();

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
    void isDownloadingChanged();
    void downloadProgressChanged();
    void downloadStatusChanged();

private:
    std::shared_ptr<infrastructure::DynamicMoERouter> m_router;
    std::unique_ptr<infrastructure::GGUFDownloaderService> m_downloader;
    QString m_serverUrl{"http://127.0.0.1:9090"};
    QString m_activeModelName{"Qwen2.5-3B-Instruct (General)"};
    QString m_activeIntent{"GeneralChat"};
    float m_temperature{0.7f};
    int m_contextSize{4096};
    int m_gpuLayers{33};
    QStringList m_availableModels;
    bool m_isConnected{true};
    QString m_connectionStatus{"Sẵn sàng (Local SSE)"};
    bool m_isDownloading{false};
    double m_downloadProgress{0.0};
    QString m_downloadStatus{"Sẵn sàng tải mô hình GGUF"};
};

} // namespace troly::presentation
