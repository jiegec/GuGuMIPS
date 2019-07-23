# 进度

1. 功能测试已经完成
2. 添加 Cache 并提高频率后，性能测试系数：1.218 -> 2.226 -> 2.856 -> 4.346
3. 可以运行 supervisor-mips32 和 U-Boot
4. 可以驱动以太网，串口，读外置 SPI Flash ， USB 基本完成

# 踩过的坑

1. AXI Uartlite 的 U-Boot 驱动有问题
2. AXI Emacslite 的 U-Boot 驱动有 BUG
3. SPI Flash 的配置比较玄学，外置 Flash 用的也是一个小众的信号
4. Xilinx 的崩溃和玄学

# 感谢

1. 宇翔提供的逻辑分析仪
2. 宇翔提供的各种指导

# 下一周计划

1. 实现 TLB
2. 实现分支预测，提高主频
3. 测试用 USB 连接一些外设：HID ，Mass storage 等，尝试把代码移植到 U-Boot 中
4. 尝试适配 uCore，之后尝试 Linux
5. 把剩余的外设和接口调通：LCD，CFG SPI Flash，PS/2，VGA