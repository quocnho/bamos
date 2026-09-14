#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFile>
#include <iostream>
#include <memory>

#include "domain/Config.hpp"
#include "infrastructure/SqliteRAGRepository.hpp"
#include "infrastructure/LlamaInferenceEngine.hpp"
#include "infrastructure/LinuxActionDispatcher.hpp"
#include "infrastructure/EyeLeoService.hpp"
#include "presentation/ChatViewModel.hpp"
#include "presentation/SystemMonitorViewModel.hpp"
#include "presentation/EyeLeoViewModel.hpp"
#include "presentation/RAGViewModel.hpp"

#include "infrastructure/DynamicMoERouter.hpp"
#include "infrastructure/FastHeuristicIntentClassifier.hpp"
#include "presentation/LLMViewModel.hpp"

int main(int argc, char *argv[]) {
    // Tối ưu hỗ trợ Wayland / XWayland
    qputenv("QT_QPA_PLATFORM", "wayland;xcb");

    QGuiApplication app(argc, argv);
    app.setApplicationName("troly");
    app.setOrganizationName("BamOS");

    std::cout << "==================================================\n";
    std::cout << "🚀 Troly - Native Edge AI Desktop (C++20 + Qt6)\n";
    std::cout << "   - Clean Architecture Skeleton\n";
    std::cout << "   - Hybrid RAG (FTS5 + SQLite-vec)\n";
    std::cout << "   - Dynamic MoE Router (<30ms Intent Classifier)\n";
    std::cout << "   - Native EyeLeo Eye Protection Service\n";
    std::cout << "   - Zero Web Overhead\n";
    std::cout << "==================================================\n";

    // Khởi tạo Dependency Injection (Infrastructure -> Usecases -> Presentation)
    auto ragRepo = std::make_shared<troly::infrastructure::SqliteRAGRepository>();
    ragRepo->initialize("/tmp/troly_knowledge.db");

    auto intentClassifier = std::make_shared<troly::infrastructure::FastHeuristicIntentClassifier>();
    auto moeRouter = std::make_shared<troly::infrastructure::DynamicMoERouter>(intentClassifier);

    auto inferenceEngine = std::make_shared<troly::infrastructure::LlamaInferenceEngine>("http://127.0.0.1:9090");
    auto actionDispatcher = std::make_shared<troly::infrastructure::LinuxActionDispatcher>();

    // Khởi tạo EyeLeo Native Service & khởi động chu kỳ đếm
    auto eyeLeoService = std::make_shared<troly::infrastructure::EyeLeoService>();
    eyeLeoService->start();

    auto chatVM = std::make_unique<troly::presentation::ChatViewModel>(inferenceEngine, ragRepo, moeRouter);
    auto systemMonitorVM = std::make_unique<troly::presentation::SystemMonitorViewModel>();
    auto eyeLeoVM = std::make_unique<troly::presentation::EyeLeoViewModel>(eyeLeoService);
    auto ragVM = std::make_unique<troly::presentation::RAGViewModel>(ragRepo);
    auto llmVM = std::make_unique<troly::presentation::LLMViewModel>(moeRouter);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("chatVM", chatVM.get());
    engine.rootContext()->setContextProperty("systemMonitorVM", systemMonitorVM.get());
    engine.rootContext()->setContextProperty("eyeLeoVM", eyeLeoVM.get());
    engine.rootContext()->setContextProperty("ragVM", ragVM.get());
    engine.rootContext()->setContextProperty("llmVM", llmVM.get());

    const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    // Load file QML: ưu tiên file tương đối từ thư mục nhị phân hoặc thư mục làm việc, hỗ trợ chạy độc lập
    QString qmlPath = QCoreApplication::applicationDirPath() + "/../src/presentation/ui/main.qml";
    if (!QFile::exists(qmlPath)) {
        qmlPath = "src/presentation/ui/main.qml";
    }
    if (!QFile::exists(qmlPath)) {
        qmlPath = QStringLiteral("qrc:/ui/main.qml");
    }
    engine.load(QUrl::fromLocalFile(qmlPath));

    return app.exec();
}
