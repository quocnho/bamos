#include <cassert>
#include <iostream>
#include "../src/domain/EyeLeoConfig.hpp"
#include "../src/infrastructure/EyeLeoService.hpp"

using namespace troly::domain;
using namespace troly::infrastructure;

void test_eyeleo_config_defaults() {
    EyeLeoConfig cfg;
    assert(cfg.enabled == true);
    assert(cfg.shortBreakIntervalSec == 20 * 60);
    assert(cfg.shortBreakDurationSec == 20);
    assert(cfg.longBreakIntervalSec == 60 * 60);
    assert(cfg.longBreakDurationSec == 5 * 60);
    assert(cfg.prebreakWarningSec == 30);
    assert(cfg.strictMode == false);
    assert(cfg.autoIdle == true);
    std::cout << "✅ test_eyeleo_config_defaults passed!\n";
}

void test_eyeleo_service_lifecycle() {
    EyeLeoService service;
    assert(service.getWorkSeconds() == 0);
    assert(service.getActiveBreak() == EyeLeoBreakType::None);

    service.start();
    service.triggerShortBreakNow();
    assert(service.getActiveBreak() == EyeLeoBreakType::ShortBreak);

    service.skipBreak();
    assert(service.getActiveBreak() == EyeLeoBreakType::None);

    service.triggerLongBreakNow();
    assert(service.getActiveBreak() == EyeLeoBreakType::LongBreak);

    service.postponeLongBreak(180);
    assert(service.getActiveBreak() == EyeLeoBreakType::None);

    service.stop();
    std::cout << "✅ test_eyeleo_service_lifecycle passed!\n";
}

int main(int argc, char* argv[]) {
    std::cout << "==================================================\n";
    std::cout << "🧪 Running EyeLeo Service CTest Unit Tests...\n";
    std::cout << "==================================================\n";

    test_eyeleo_config_defaults();
    test_eyeleo_service_lifecycle();

    std::cout << "🎉 All EyeLeo tests passed successfully!\n";
    return 0;
}
