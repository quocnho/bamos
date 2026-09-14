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
)

set(HEADERS
    src/domain/ChatMessage.hpp
    src/domain/Config.hpp
    src/domain/KnowledgeChunk.hpp
    src/domain/CommandResult.hpp
    src/domain/EyeLeoConfig.hpp
    src/usecases/IRAGService.hpp
    src/usecases/IInferenceEngine.hpp
    src/usecases/IActionDispatcher.hpp
    src/usecases/ISafetyGuard.hpp
    src/usecases/IEyeLeoService.hpp
    src/infrastructure/SqliteRAGRepository.hpp
    src/infrastructure/LlamaInferenceEngine.hpp
    src/infrastructure/LinuxActionDispatcher.hpp
    src/infrastructure/EyeLeoService.hpp
    src/infrastructure/DocumentIngestionWorker.hpp
    src/presentation/ChatViewModel.hpp
    src/presentation/SystemMonitorViewModel.hpp
    src/presentation/EyeLeoViewModel.hpp
    src/presentation/RAGViewModel.hpp
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

install(TARGETS troly DESTINATION bin)
