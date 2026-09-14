#include <cassert>
#include <iostream>
#include <string>
#include "../src/usecases/ISafetyGuard.hpp"
#include "../src/infrastructure/DefaultSafetyGuard.hpp"
#include "../src/infrastructure/LinuxActionDispatcher.hpp"

using namespace troly::usecases;
using namespace troly::infrastructure;

void testSafetyGuardRiskLevels() {
    std::cout << "[TEST] Running testSafetyGuardRiskLevels...\n";
    DefaultSafetyGuard guard;

    // 1. Safe commands
    auto safe1 = guard.assessCommand("ls -la /home");
    assert(safe1.level == RiskLevel::Safe);
    assert(!safe1.requiresExplicitConfirmation);

    auto safe2 = guard.assessCommand("cat /etc/os-release");
    assert(safe2.level == RiskLevel::Safe);

    auto safe3 = guard.assessCommand("nix search nixpkgs ripgrep");
    assert(safe3.level == RiskLevel::Safe);

    // 2. Caution commands (sudo / systemctl / bam switch)
    auto caution1 = guard.assessCommand("sudo apt update");
    assert(caution1.level == RiskLevel::Caution);
    assert(caution1.requiresExplicitConfirmation);

    auto caution2 = guard.assessCommand("bam switch");
    assert(caution2.level == RiskLevel::Caution);
    assert(caution2.requiresExplicitConfirmation);

    auto caution3 = guard.assessCommand("systemctl restart bluetooth");
    assert(caution3.level == RiskLevel::Caution);

    // 3. Dangerous commands (rm -rf / killall -9)
    auto danger1 = guard.assessCommand("rm -rf ./build_tmp");
    assert(danger1.level == RiskLevel::Dangerous);
    assert(danger1.requiresExplicitConfirmation);

    auto danger2 = guard.assessCommand("killall -9 troly");
    assert(danger2.level == RiskLevel::Dangerous);

    // 4. Blocked commands (rm -rf / or fork bomb or dd dev)
    auto block1 = guard.assessCommand("rm -rf /");
    assert(block1.level == RiskLevel::Blocked);

    auto block2 = guard.assessCommand("rm -rf /*");
    assert(block2.level == RiskLevel::Blocked);

    auto block3 = guard.assessCommand("dd if=/dev/zero of=/dev/sda");
    assert(block3.level == RiskLevel::Blocked);

    auto block4 = guard.assessCommand(":(){ :|:& };:");
    assert(block4.level == RiskLevel::Blocked);

    std::cout << " -> Passed testSafetyGuardRiskLevels!\n";
}

void testLinuxActionDispatcherExecution() {
    std::cout << "[TEST] Running testLinuxActionDispatcherExecution...\n";
    LinuxActionDispatcher dispatcher;

    // Test echo
    auto res = dispatcher.executeCommand("echo 'Troly Action Dispatcher OK'");
    assert(res.exitCode == 0);
    assert(res.output.find("Troly Action Dispatcher OK") != std::string::npos);

    // Test non-zero exit code
    auto errRes = dispatcher.executeCommand("ls /duong_dan_khong_ton_tai_12345");
    assert(errRes.exitCode != 0);

    std::cout << " -> Passed testLinuxActionDispatcherExecution!\n";
}

int main() {
    std::cout << "========================================\n";
    std::cout << "🧪 Troly SafetyGuard & Action Test Suite\n";
    std::cout << "========================================\n";

    testSafetyGuardRiskLevels();
    testLinuxActionDispatcherExecution();

    std::cout << "========================================\n";
    std::cout << "✅ ALL SAFETY & ACTION TESTS PASSED 100%\n";
    std::cout << "========================================\n";
    return 0;
}
