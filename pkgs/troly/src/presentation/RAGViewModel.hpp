#pragma once

#include <QObject>
#include <QString>
#include <memory>
#include "../usecases/IRAGService.hpp"
#include "../infrastructure/DocumentIngestionWorker.hpp"

namespace troly::presentation {

/**
 * @brief ViewModel quản lý tri thức và tiến độ lập chỉ mục RAG
 */
class RAGViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isIndexing READ isIndexing NOTIFY indexingChanged)
    Q_PROPERTY(int indexedFilesCount READ indexedFilesCount NOTIFY progressChanged)
    Q_PROPERTY(int totalFilesCount READ totalFilesCount NOTIFY progressChanged)
    Q_PROPERTY(QString currentFileName READ currentFileName NOTIFY progressChanged)
    Q_PROPERTY(int topK READ topK WRITE setTopK NOTIFY topKChanged)

public:
    explicit RAGViewModel(std::shared_ptr<usecases::IRAGService> ragService, QObject* parent = nullptr)
        : QObject(parent), m_ragService(std::move(ragService)) {}

    [[nodiscard]] bool isIndexing() const { return m_worker.isRunning(); }
    [[nodiscard]] int indexedFilesCount() const { return m_indexedCount; }
    [[nodiscard]] int totalFilesCount() const { return m_totalCount; }
    [[nodiscard]] QString currentFileName() const { return m_currentFile; }
    [[nodiscard]] int topK() const { return m_topK; }

    Q_INVOKABLE void setTopK(int k) {
        if (m_topK != k) {
            m_topK = k;
            emit topKChanged();
        }
    }

    Q_INVOKABLE void startIndexing(const QString& dirPath) {
        if (m_worker.isRunning() || !m_ragService) return;

        m_indexedCount = 0;
        m_totalCount = 0;
        emit indexingChanged();

        m_worker.startIngestion(
            dirPath.toStdString(),
            m_ragService,
            [this](size_t processed, size_t total, const std::string& currentFile) {
                QMetaObject::invokeMethod(this, [this, processed, total, currentFile]() {
                    m_indexedCount = static_cast<int>(processed);
                    m_totalCount = static_cast<int>(total);
                    m_currentFile = QString::fromStdString(currentFile);
                    emit progressChanged();
                });
            }
        );
    }

    Q_INVOKABLE void stopIndexing() {
        m_worker.stop();
        emit indexingChanged();
    }

signals:
    void indexingChanged();
    void progressChanged();
    void topKChanged();

private:
    std::shared_ptr<usecases::IRAGService> m_ragService;
    infrastructure::DocumentIngestionWorker m_worker;
    int m_indexedCount{0};
    int m_totalCount{0};
    int m_topK{5};
    QString m_currentFile;
};

} // namespace troly::presentation
