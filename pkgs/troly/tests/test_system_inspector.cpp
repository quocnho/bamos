#include <cassert>
#include <iostream>
#include "infrastructure/SystemInspectorService.hpp"
#include "infrastructure/WakaTrackerService.hpp"
#include "domain/UserProfile.hpp"

using namespace troly;

void testSystemInspector() {
    std::cout << "[TEST] Running SystemInspectorService tests...\n";
    infrastructure::SystemInspectorService inspector;
    auto report = inspector.inspectSystem();
    
    // RAM usage percent should be >= 0.0
    assert(report.ramUsagePercent >= 0.0);
    // Nix store size string should not be empty
    assert(!report.nixStoreSize.empty());
    // Healthy check
    assert(report.isHealthy == (report.failedServices.empty() && report.recentSystemErrors.empty()));
    std::cout << "  RAM Usage: " << report.ramUsagePercent << "%\n";
    std::cout << "  Nix Store: " << report.nixStoreSize << "\n";
    std::cout << "  Is Healthy: " << (report.isHealthy ? "true" : "false") << "\n";
    std::cout << "[PASS] SystemInspectorService tests passed!\n";
}

void testWakaTracker() {
    std::cout << "[TEST] Running WakaTrackerService tests...\n";
    infrastructure::WakaTrackerService tracker;
    auto stats = tracker.getStats();

    assert(stats.totalMinutesToday > 0);
    assert(!stats.primaryLanguage.empty());
    assert(stats.cppPercent + stats.nixPercent + stats.qmlPercent == 100);
    std::cout << "  Total Minutes: " << stats.totalMinutesToday << "\n";
    std::cout << "  Primary Language: " << stats.primaryLanguage << "\n";
    std::cout << "  Percentages: C++ " << stats.cppPercent << "%, Nix " 
              << stats.nixPercent << "%, QML " << stats.qmlPercent << "%\n";
    std::cout << "[PASS] WakaTrackerService tests passed!\n";
}

void testUserProfile() {
    std::cout << "[TEST] Running UserProfile tests...\n";
    domain::UserProfile profile;
    profile.userName = "quocnho";
    profile.addressing = "Đại ca";
    profile.technicalLevel = "Principal Engineer";
    profile.preferredLanguages = "C++20, NixOS";

    auto systemPrompt = profile.makeSystemPrompt();
    assert(systemPrompt.find("Đại ca") != std::string::npos);
    assert(systemPrompt.find("Principal Engineer") != std::string::npos);
    assert(systemPrompt.find("C++20, NixOS") != std::string::npos);
    assert(systemPrompt.find("troly") != std::string::npos);

    std::cout << "  Generated System Prompt:\n  " << systemPrompt << "\n";
    std::cout << "[PASS] UserProfile tests passed!\n";
}

int main() {
    testSystemInspector();
    testWakaTracker();
    testUserProfile();
    std::cout << "All System Inspector & Extension tests passed successfully!\n";
    return 0;
}
