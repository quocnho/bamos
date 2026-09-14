#include "ChatViewModel.hpp"
#include <QVariantMap>
#include <QMetaObject>

namespace troly::presentation {

ChatViewModel::ChatViewModel(
    std::shared_ptr<usecases::IInferenceEngine> inferenceEngine,
    std::shared_ptr<usecases::IRAGService> ragService,
    std::shared_ptr<infrastructure::DynamicMoERouter> router,
    QObject* parent
)
    : QObject(parent)
    , m_inferenceEngine(std::move(inferenceEngine))
    , m_ragService(std::move(ragService))
    , m_router(std::move(router)) {}

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

void ChatViewModel::setPeekMode(bool peek) {
    if (m_isPeekMode != peek) {
        m_isPeekMode = peek;
        emit peekModeChanged();
        if (m_isPeekMode) {
            setMascotState("peek_tail");
        } else {
            setMascotState("idle");
        }
    }
}

void ChatViewModel::togglePeekMode() {
    setPeekMode(!m_isPeekMode);
}

void ChatViewModel::wakeFromPeek() {
    if (m_isPeekMode) {
        m_isPeekMode = false;
        emit peekModeChanged();
        // Hiệu ứng cún vồ chuột vui mừng & chào hỏi
        setMascotState("playful_jump");
        m_mascotGreeting = "Gâu gâu! Em đây ạ! Chúc chủ nhân một ngày làm việc tràn đầy năng lượng! 🐾";
        emit mascotGreetingChanged();
    }
}

void ChatViewModel::appendStreamingToken(const QString& token) {
    m_currentStreamingText += token;
    emit currentStreamingTextChanged();
}

void ChatViewModel::sendMessage(const QString& userText) {
    QString trimmed = userText.trimmed();
    if (trimmed.isEmpty() || m_isGenerating) return;

    // Nếu đang ở chế độ núp lùm thì tự động mở rộng
    if (m_isPeekMode) {
        setPeekMode(false);
    }

    // 1. Phân loại ý định qua Dynamic MoE Router (<30ms)
    std::string promptForEngine = trimmed.toStdString();
    if (m_router) {
        auto intent = m_router->routeIntent(promptForEngine);
        m_detectedIntent = QString::fromStdString(std::string(domain::userIntentToString(intent)));
        emit detectedIntentChanged();
        auto selectedModel = m_router->selectModelForIntent(intent);
        (void)selectedModel;
    }

    // 2. Tra cứu RAG nếu câu hỏi liên quan hoặc có từ khóa
    if (m_ragService) {
        auto chunks = m_ragService->searchHybrid(trimmed.toStdString(), 2, 0.65f);
        if (!chunks.empty()) {
            std::string contextAugment = "\n\n[Bối cảnh tri thức liên quan]:\n";
            for (const auto& chunk : chunks) {
                contextAugment += "- " + chunk.content + "\n";
            }
            promptForEngine += contextAugment;
        }
    }

    // Thêm User message vào history UI
    QVariantMap userMsg;
    userMsg["role"] = "user";
    userMsg["content"] = trimmed;
    m_messageHistory.append(userMsg);
    emit messageHistoryChanged();

    domain::ChatMessage domainUserMsg;
    domainUserMsg.role = domain::MessageRole::User;
    domainUserMsg.content = promptForEngine;
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
