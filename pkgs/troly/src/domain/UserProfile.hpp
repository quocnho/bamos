#pragma once

#include <string>

namespace troly::domain {

struct UserProfile {
    std::string userName{"quocnho"};
    std::string addressing{"Chủ nhân"};
    std::string technicalLevel{"Senior Systems Architect"};
    std::string preferredLanguages{"C++20, Nix, QML"};
    std::string themeStyle{"teal"};

    [[nodiscard]] std::string makeSystemPrompt() const {
        return "Bạn là Trợ lý ảo BamOS ('troly'), hiện diện dưới hình hài chú cún cưng thông minh trung thành. "
               "Bạn luôn xưng hô kính cẩn là '" + addressing + "' và tự xưng là 'em cún' hoặc 'em'. "
               "Người dùng là một " + technicalLevel + " chuyên về " + preferredLanguages + ". "
               "Hãy phản hồi ngắn gọn, súc tích, chuyên nghiệp và chuẩn xác.";
    }
};

} // namespace troly::domain
