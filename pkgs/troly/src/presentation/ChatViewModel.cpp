#include "ChatViewModel.hpp"
#include <QVariantMap>
#include <QMetaObject>

namespace troly::presentation {

ChatViewModel::ChatViewModel(
    std::shared_ptr<usecases::IInferenceEngine> inferenceEngine,
    std::shared_ptr<usecases::IRAGService> ragService,
    QObject* parent
)
    : QObject(parent)
    , m_inferenceEngine(std::move(inferenceEngine))
    , m_ragService(std::move(ragService)) {}

void ChatViewModel::setIsGenerating(bool value) {
    if (m_isGenerating != value) {
        m_isGenerating = value;
        emit isGeneratingChanged();
        setMascotState(value ? "excited" : "idle");
    }
}

void ChatViewModel::setMascotState(const QString& state) {
    if (m_mascotState != state) {
        m_mascotState = state;
        emit mascotStateChanged();
    }
}

void ChatViewModel::appendStreamingToken(const QString& token) {
    m_currentStreamingText += token;
    emit currentStreamingTextChanged();
}

void ChatViewModel::sendMessage(const QString& userText) {
    QString trimmed = userText.trimmed();
    if (trimmed.isEmpty() || m_isGenerating) return;

    // Thêm User message vào history
    QVariantMap userMsg;
    userMsg["role"] = "user";
    userMsg["content"] = trimmed;
    m_messageHistory.append(userMsg);
    emit messageHistoryChanged();

    domain::ChatMessage domainUserMsg;
    domainUserMsg.role = domain::MessageRole::User;
    domainUserMsg.content = trimmed.toStdString();
    m_domainHistory.push_back(domainUserMsg);

    setIsGenerating(true);
    m_currentStreamingText.clear();
    emit currentStreamingTextChanged();

    // Gọi Inference Engine với Token Streaming
    m_inferenceEngine->streamChat(
        m_domainHistory,
        0.7f,
        [this](const std::string& token) {
            QString qToken = QString::fromStdString(token);
            QMetaObject::invokeMethod(this, [this, qToken]() {
                appendStreamingToken(qToken);
            });
        },
        [this](const std::string& fullResponse) {
            QMetaObject::invokeMethod(this, [this, fullResponse]() {
                QVariantMap asstMsg;
                asstMsg["role"] = "assistant";
                asstMsg["content"] = QString::fromStdString(fullResponse);
                m_messageHistory.append(asstMsg);
                emit messageHistoryChanged();

                domain::ChatMessage domainAsstMsg;
                domainAsstMsg.role = domain::MessageRole::Assistant;
                domainAsstMsg.content = fullResponse;
                m_domainHistory.push_back(domainAsstMsg);

                m_currentStreamingText.clear();
                emit currentStreamingTextChanged();
                setIsGenerating(false);
            });
        },
        [this](const std::string& error) {
            QMetaObject::invokeMethod(this, [this, error]() {
                emit errorOccurred(QString::fromStdString(error));
                setIsGenerating(false);
            });
        }
    );
}

void ChatViewModel::abortGeneration() {
    if (m_inferenceEngine) {
        m_inferenceEngine->abort();
    }
    setIsGenerating(false);
}

void ChatViewModel::clearHistory() {
    m_messageHistory.clear();
    m_domainHistory.clear();
    m_currentStreamingText.clear();
    emit messageHistoryChanged();
    emit currentStreamingTextChanged();
}

} // namespace troly::presentation
