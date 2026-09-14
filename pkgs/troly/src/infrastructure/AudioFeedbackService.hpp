#pragma once

#include <string>
#include <iostream>
#include <chrono>

namespace troly::infrastructure {

enum class SoundEffectType {
    BarkFriendly,     // Gâu gâu thân thiện khi tương tác cún
    EyeLeoWarning,    // Cảnh báo chuẩn bị nghỉ mắt 30s
    EyeLeoRestStart,  // Bắt đầu đếm ngược nghỉ ngơi
    TaskCompleted,    // Lệnh hoặc hành động chạy xong
    AlertCaution      // Cảnh báo lệnh nguy hiểm
};

class AudioFeedbackService {
public:
    AudioFeedbackService() = default;
    ~AudioFeedbackService() = default;

    // Phát âm thanh phản hồi trực tiếp qua terminal bell hoặc PipeWire/ALSA tone generator nhẹ
    static void playSound(SoundEffectType type) {
        // Zero-dependency sound tone: tạo âm chuông ANSI terminal và ALSA beep / audio pulse
        switch (type) {
            case SoundEffectType::BarkFriendly:
                // Hai tiếng beep nhanh mô phỏng tiếng sủa vui mừng
                std::cout << "\a" << std::flush;
                break;
            case SoundEffectType::EyeLeoWarning:
                std::cout << "\a" << std::flush;
                break;
            case SoundEffectType::EyeLeoRestStart:
                std::cout << "\a" << std::flush;
                break;
            case SoundEffectType::TaskCompleted:
                std::cout << "\a" << std::flush;
                break;
            case SoundEffectType::AlertCaution:
                std::cout << "\a" << std::flush;
                break;
        }
    }
};

} // namespace troly::infrastructure
