#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <memory>
#include "../usecases/IInferenceEngine.hpp"
#include "../usecases/IRAGService.hpp"
#include "../domain/ChatMessage.hpp"
#include "../infrastructure/DynamicMoERouter.hpp"

namespace troly::presentation {

class ChatViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isGenerating READ isGenerating NOTIFY isGeneratingChanged)
    Q_PROPERTY(QString currentStreamingText READ currentStreamingText NOTIFY currentStreamingTextChanged)
    Q_PROPERTY(QVariantList messageHistory READ messageHistory NOTIFY messageHistoryChanged)
    Q_PROPERTY(QString mascotState READ mascotState WRITE setMascotState NOTIFY mascotStateChanged)
    Q_PROPERTY(bool isPeekMode READ isPeekMode WRITE setPeekMode NOTIFY peekModeChanged)
    Q_PROPERTY(QString mascotGreeting READ mascotGreeting NOTIFY mascotGreetingChanged)
    Q_PROPERTY(QString detectedIntent READ detectedIntent NOTIFY detectedIntentChanged)

public:
    explicit ChatViewModel(
        std::shared_ptr<usecases::IInferenceEngine> inferenceEngine,
        std::shared_ptr<usecases::IRAGService> ragService,
        std::shared_ptr<infrastructure::DynamicMoERouter> router = nullptr,
        QObject* parent = nullptr
    );

    [[nodiscard]] bool isGenerating() const { return m_isGenerating; }
    [[nodiscard]] QString currentStreamingText() const { return m_currentStreamingText; }
    [[nodiscard]] QVariantList messageHistory() const { return m_messageHistory; }
    [[nodiscard]] QString mascotState() const { return m_mascotState; }
    [[nodiscard]] bool isPeekMode() const { return m_isPeekMode; }
    [[nodiscard]] QString mascotGreeting() const { return m_mascotGreeting; }
    [[nodiscard]] QString detectedIntent() const { return m_detectedIntent; }

    Q_INVOKABLE void sendMessage(const QString& userText);
    Q_INVOKABLE void abortGeneration();
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE void setMascotState(const QString& state);
    Q_INVOKABLE void setPeekMode(bool peek);
    Q_INVOKABLE void togglePeekMode();
    Q_INVOKABLE void wakeFromPeek();

signals:
    void isGeneratingChanged();
    void currentStreamingTextChanged();
    void messageHistoryChanged();
    void mascotStateChanged();
    void peekModeChanged();
    void mascotGreetingChanged();
    void detectedIntentChanged();
    void errorOccurred(const QString& errorMessage);

private:
    std::shared_ptr<usecases::IInferenceEngine> m_inferenceEngine;
    std::shared_ptr<usecases::IRAGService> m_ragService;
    std::shared_ptr<infrastructure::DynamicMoERouter> m_router;

    bool m_isGenerating{false};
    bool m_isPeekMode{false};
    QString m_mascotState{"idle"};
    QString m_mascotGreeting{"Gâu gâu! Em chào chủ nhân ạ! 🐶"};
    QString m_detectedIntent{"GeneralChat"};
    QString m_currentStreamingText;
    QVariantList m_messageHistory;
    std::vector<domain::ChatMessage> m_domainHistory;

    void setIsGenerating(bool value);
    void appendStreamingToken(const QString& token);
};

} // namespace troly::presentation
