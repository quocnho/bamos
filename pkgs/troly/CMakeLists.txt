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
    src/presentation/ChatViewModel.cpp
    src/presentation/SystemMonitorViewModel.cpp
)

set(HEADERS
    src/domain/ChatMessage.hpp
    src/domain/Config.hpp
    src/domain/KnowledgeChunk.hpp
    src/domain/CommandResult.hpp
    src/usecases/IRAGService.hpp
    src/usecases/IInferenceEngine.hpp
    src/usecases/IActionDispatcher.hpp
    src/usecases/ISafetyGuard.hpp
    src/infrastructure/SqliteRAGRepository.hpp
    src/infrastructure/LlamaInferenceEngine.hpp
    src/infrastructure/LinuxActionDispatcher.hpp
    src/presentation/ChatViewModel.hpp
    src/presentation/SystemMonitorViewModel.hpp
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

install(TARGETS troly DESTINATION bin)
