#pragma once

#include "../domain/Intent.hpp"
#include <string>

namespace troly::usecases {

class IIntentClassifier {
public:
    virtual ~IIntentClassifier() = default;

    /// Phân loại ý định người dùng với độ trễ cực thấp (< 30ms)
    virtual domain::UserIntent classify(const std::string& text) = 0;
};

} // namespace troly::usecases
