#include "infrastructure/LinuxActionDispatcher.hpp"
#include <iostream>
#include <cassert>

using namespace troly::infrastructure;

int main() {
    std::cout << "[TestAgentTools] Testing LinuxActionDispatcher tools expansion...\n";
    LinuxActionDispatcher dispatcher;

    // 1. Kiểm tra listDirectory
    auto items = dispatcher.listDirectory(".");
    std::cout << "[TestAgentTools] Found " << items.size() << " entries in current directory.\n";
    assert(!items.empty());

    // 2. Kiểm tra writeFile và readFile
    std::string testPath = "/tmp/test_troly_tool.txt";
    std::string testContent = "Hello Troly Sprint 08 Native Agent Tools!";
    assert(dispatcher.writeFile(testPath, testContent));

    std::string readBack;
    assert(dispatcher.readFile(testPath, readBack));
    assert(readBack == testContent);
    std::cout << "[TestAgentTools] File write/read verified successfully.\n";

    // 3. Kiểm tra searchInFiles
    auto searchRes = dispatcher.searchInFiles("/tmp", "Sprint 08 Native Agent");
    std::cout << "[TestAgentTools] Search matches found: " << searchRes.size() << "\n";
    assert(!searchRes.empty());

    // 4. Kiểm tra validateNixConfig (dry check)
    auto nixRes = dispatcher.validateNixConfig("/dev/null");
    std::cout << "[TestAgentTools] Validate Nix exitCode: " << nixRes.exitCode << "\n";

    std::cout << "[TestAgentTools] All agent tools tests passed!\n";
    return 0;
}
