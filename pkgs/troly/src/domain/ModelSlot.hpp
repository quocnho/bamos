#pragma once

#include "../domain/Intent.hpp"
#include <string>

namespace troly::domain {

struct ModelSlot {
    std::string modelId;
    std::string displayName;
    std::string ggufFileName;
    UserIntent targetIntent;
    int32_t contextLength{4096};
    int32_t gpuLayers{33};
    size_t estimatedVRAMMB{3500};
};

} // namespace troly::domain
