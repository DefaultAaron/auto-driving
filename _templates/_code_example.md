<!--
Code-example template.
- DL → PyTorch.
- ROS2 nodes / classical perception / control → C++ where feasible (else original).
- Long examples: reference `~/Documents/Projects/mingtai/traffic-light/<path>:Lxx-yy` instead of pasting full code.
- Very long examples: extract to `_assets/code/<N>_<M>_<slug>.{py,cpp}` and embed.
-->

> [!example] Code — <one-line title>
>
> **What it shows.** <one sentence>
> **Source.** Original / adapted from <ref> / from `~/Documents/Projects/mingtai/traffic-light/<path>:Lxx-yy`
> **Language.** PyTorch | C++ (ROS2) | C++ (PCL/Eigen/OpenCV) | <other>
> **Runs against.** <dataset / sim / on-vehicle>

```python
# PyTorch skeleton
import torch
import torch.nn as nn

class Example(nn.Module):
    def __init__(self):
        super().__init__()
        # ...

    def forward(self, x):
        # ...
        return x
```

```cpp
// C++ ROS2 node skeleton
#include <rclcpp/rclcpp.hpp>

class ExampleNode : public rclcpp::Node {
public:
    ExampleNode() : Node("example") {
        // ...
    }
};

int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<ExampleNode>());
    rclcpp::shutdown();
    return 0;
}
```

> [!tip] When to externalise
> If a code block exceeds ~40 lines, move it to `_assets/code/<N>_<M>_<slug>.{py,cpp}` and embed with `![[...]]`. Keeps section pages readable.
