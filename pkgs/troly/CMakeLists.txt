cmake_minimum_required(VERSION 3.22)
project(troly VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2)
qt_standard_project_setup()

find_package(SQLite3 REQUIRED)
find_package(Threads REQUIRED)

set(SOURCES
    src/main.cpp
    src/infrastructure/SqliteRAGRepository.cpp
    src/infrastructure/LlamaInferenceEngine.cpp
    src/infrastructure/LinuxActionDispatcher.cpp
    src/infrastructure/EyeLeoService.cpp
    src/presentation/ChatViewModel.cpp
    src/presentation/SystemMonitorViewModel.cpp
    src/presentation/EyeLeoViewModel.cpp
    src/presentation/RAGViewModel.cpp
    src/presentation/LLMViewModel.cpp
    src/presentation/ActionViewModel.cpp
    src/presentation/ExtensionsViewModels.cpp
)

set(HEADERS
    src/domain/ChatMessage.hpp
    src/domain/Config.hpp
    src/domain/KnowledgeChunk.hpp
    src/domain/CommandResult.hpp
    src/domain/EyeLeoConfig.hpp
    src/domain/Intent.hpp
    src/domain/ModelSlot.hpp
    src/domain/UserProfile.hpp
    src/domain/GoldenInteraction.hpp
    src/usecases/IRAGService.hpp
    src/usecases/IInferenceEngine.hpp
    src/usecases/IIntentClassifier.hpp
    src/usecases/IActionDispatcher.hpp
    src/usecases/ISafetyGuard.hpp
    src/usecases/IEyeLeoService.hpp
    src/infrastructure/SqliteRAGRepository.hpp
    src/infrastructure/LlamaInferenceEngine.hpp
    src/infrastructure/LinuxActionDispatcher.hpp
    src/infrastructure/EyeLeoService.hpp
    src/infrastructure/DocumentIngestionWorker.hpp
    src/infrastructure/FastHeuristicIntentClassifier.hpp
    src/infrastructure/DynamicMoERouter.hpp
    src/infrastructure/DefaultSafetyGuard.hpp
    src/infrastructure/SystemInspectorService.hpp
    src/infrastructure/WakaTrackerService.hpp
    src/infrastructure/SelfEvolvingService.hpp
    src/infrastructure/AudioFeedbackService.hpp
    src/presentation/ChatViewModel.hpp
    src/presentation/SystemMonitorViewModel.hpp
    src/presentation/EyeLeoViewModel.hpp
    src/presentation/RAGViewModel.hpp
    src/presentation/LLMViewModel.hpp
    src/presentation/ActionViewModel.hpp
    src/presentation/ExtensionsViewModels.hpp
)

qt_add_executable(troly
    ${SOURCES}
    ${HEADERS}
)

target_include_directories(troly PRIVATE src)

target_link_libraries(troly PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    SQLite3::SQLite3
    Threads::Threads
)

enable_testing()
add_executable(test_eyeleo
    tests/test_eyeleo.cpp
    src/infrastructure/EyeLeoService.cpp
)
target_include_directories(test_eyeleo PRIVATE src)
target_link_libraries(test_eyeleo PRIVATE
    Qt6::Core
)
add_test(NAME EyeLeoTests COMMAND test_eyeleo)

add_executable(test_rag
    tests/test_rag.cpp
    src/infrastructure/SqliteRAGRepository.cpp
)
target_include_directories(test_rag PRIVATE src)
target_link_libraries(test_rag PRIVATE
    SQLite3::SQLite3
    Threads::Threads
)
add_test(NAME RAGTests COMMAND test_rag)

add_executable(test_inference
    tests/test_inference.cpp
    src/infrastructure/LlamaInferenceEngine.cpp
)
target_include_directories(test_inference PRIVATE src)
target_link_libraries(test_inference PRIVATE
    Threads::Threads
)
add_test(NAME InferenceTests COMMAND test_inference)

add_executable(test_action
    tests/test_action.cpp
    src/infrastructure/LinuxActionDispatcher.cpp
)
target_include_directories(test_action PRIVATE src)
target_link_libraries(test_action PRIVATE
    Qt6::Core
    Threads::Threads
)
add_test(NAME ActionTests COMMAND test_action)

add_executable(test_system_inspector
    tests/test_system_inspector.cpp
)
target_include_directories(test_system_inspector PRIVATE src)
add_test(NAME SystemInspectorTests COMMAND test_system_inspector)

add_executable(test_self_evolving
    tests/test_self_evolving.cpp
)
target_include_directories(test_self_evolving PRIVATE src)
add_test(NAME SelfEvolvingTests COMMAND test_self_evolving)

add_executable(test_agent_tools
    tests/test_agent_tools.cpp
    src/infrastructure/LinuxActionDispatcher.cpp
)
target_include_directories(test_agent_tools PRIVATE src)
target_link_libraries(test_agent_tools PRIVATE
    Qt6::Core
    Threads::Threads
)
add_test(NAME AgentToolsTests COMMAND test_agent_tools)

install(TARGETS troly DESTINATION bin)
