# Guess from Deepseek, blind for waveform, no guarantee.

2．数据链路层模块功能及子模块划分描述如下：
（1）crc5_r模块：接收来自物理层的令牌包和握手包，以保证传输的控制内容无误；
（2）crc16_r模块：接收来自物理层的数据包，以保证传输的数据内容无误；
（3）crc5_t模块：用于组装令牌包和握手包；
（4）control_t模块：用于控制切换发送包类型，数据包/令牌包/握手包；
（5）link_ctrl模块：用于控制rx_data_on / tx_data_on / rx_handshakeon, and d_oe等信号是否使能。

### **1. Basic 基础接口（已补充完整）**
| Port   | width | direction | description                     |
|--------|-------|-----------|---------------------------------|
| clk    | 1     | input     | system clk                      |
| rst_n  | 1     | input     | system reset, active low        |

---

### **2. Register 寄存器接口**
| Port              | width | direction | description                                                                 |
|-------------------|-------|-----------|-----------------------------------------------------------------------------|
| self_addr         | 7     | input     | 设备自身地址（7位），用于过滤接收包的目标地址是否匹配（如SETUP/OUT令牌包） |
| ms                | 1     | input     | 1: master（主机模式） 0: slave（设备模式）                                 |
| time_threshold    | 16    | input     | 超时阈值（单位：时钟周期），用于检测ACK响应超时                            |
| delay_threshole   | 6     | input     | 延迟容忍阈值（单位：时钟周期），用于检测信号抖动或物理层传输延迟            |
| crc5_err          | 1     | output    | CRC5校验错误标志（令牌包或握手包CRC校验失败时置高）                       |
| time_out          | 1     | output    | 超时标志（等待ACK或数据包超时后置高）                                      |
| d_oe              | 1     | output    | 数据方向控制信号（1: 输出到物理层，0: 从物理层输入）                      |

---

### **3. Interface with PHY 物理层接口**
| Port            | width | direction | description                                                                 |
|-----------------|-------|-----------|-----------------------------------------------------------------------------|
| rx_lp_sop       | 1     | input     | 接收数据包起始信号（Start of Packet），标识物理层数据包的开始              |
| rx_lp_eop       | 1     | input     | 接收数据包结束信号（End of Packet），标识物理层数据包的结束               |
| rx_lp_valid     | 1     | input     | 接收数据有效信号（物理层数据有效时置高）                                  |
| rx_lp_ready     | 1     | output    | 接收流控信号（链路层准备好接收物理层数据时置高）                          |
| rx_lp_data      | 8     | input     | 接收数据总线（8位并行数据，包含PID/ADDR/DATA等字段）                      |
| tx_lp_sop       | 1     | output    | 发送数据包起始信号（标识链路层发送包的开始）                              |
| tx_lp_eop       | 1     | output    | 发送数据包结束信号（标识链路层发送包的结束）                              |
| tx_lp_valid     | 1     | output    | 发送数据有效信号（链路层数据有效时置高）                                  |
| tx_lp_ready     | 1     | input     | 发送流控信号（物理层准备好接收链路层数据时置高）                          |
| tx_lp_data      | 8     | output    | 发送数据总线（8位并行数据，包含PID/ADDR/DATA等字段）                      |
| tx_lp_cancle    | 1     | output    | 发送取消信号（强制终止当前发送事务，如检测到错误或冲突）                  |

---

### **4. With Link Layer 链路层内部接口**
| Port             | width | direction | description                                                                 |
|------------------|-------|-----------|-----------------------------------------------------------------------------|
| rx_pid_en        | 1     | output    | PID字段有效信号（标识当前接收数据为PID字段，用于解析包类型）               |
| rx_pid           | 4     | output    | 接收包类型标识（如`DATA0=0x3`, `ACK=0x2`）                                  |
| rx_endp          | 4     | output    | 接收端点号（4位，标识目标端点，如EP0~EP15）                                |
| rx_lt_sop        | 1     | output    | 接收数据包起始信号（标识传输层数据开始）                             |
| rx_lt_eop        | 1     | output    | 接收数据包结束信号（标识传输层数据结束）                             |
| rx_lt_valid      | 1     | output    | 接收数据有效信号（传输层数据有效时置高）                             |
| rx_lt_ready      | 1     | input     | 接收流控信号（传输层准备好接收数据时置高）                           |
| rx_lt_data       | 8     | output    | 接收数据总线（8位数据，传递给传输层）                                |
| tx_pid           | 4     | input     | 发送包类型标识（由传输层指定，如`DATA1=0xB`）                               |
| tx_addr          | 7     | input     | 发送目标设备地址（7位，嵌入令牌包地址域）                                   |
| tx_endp          | 4     | input     | 发送目标端点号（4位，嵌入令牌包端点域）                                     |
| tx_valid         | 1     | input     | 发送请求有效信号（传输层请求发送数据时置高）                                |
| tx_ready         | 1     | output    | 发送请求就绪信号（链路层准备好发送数据时置高）                              |
| tx_lt_sop        | 1     | input     | 发送数据包起始信号（标识传输层数据开始）                              |
| tx_lt_eop        | 1     | input     | 发送数据包结束信号（标识传输层数据结束）                              |
| tx_lt_valid      | 1     | input     | 发送数据有效信号（传输层数据有效时置高）                              |
| tx_lt_ready      | 1     | output    | 发送流控信号（链路层准备好接收传输层数据时置高）                      |
| tx_lt_data       | 8     | input     | 发送数据总线（8位数据，来自传输层）                                   |
| tx_lt_cancle     | 1     | input     | 发送取消信号（传输层请求终止当前发送事务时置高）                            |
