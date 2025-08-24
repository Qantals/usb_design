//=============================================================
// usb_link_tb.sv  —  SystemVerilog CRT Random Testbench (fixed CRC)
//   - No UVM
//   - Randomized case0~case3 traffic
//   - TOKEN/DATA0/ACK with CRC5/CRC16 exactly matching DUT
//   - Driver / Monitor / Scoreboard / Coverage / Env / TB
//=============================================================
`timescale 1ns/1ps

//=========================== Package =========================
package usb_tb_pkg;

  // ----------------- PID nibbles (lower-nibble == PID) -----------------
  localparam logic [3:0] PID_IN    = 4'b1001;
  localparam logic [3:0] PID_OUT   = 4'b0001;
  localparam logic [3:0] PID_DATA0 = 4'b0011; // **FIXED** (DATA0 nibble = 0011)
  localparam logic [3:0] PID_ACK   = 4'b0010;

  // PID byte helper: {~pid[3:0], pid[3:0]}
  function automatic byte pid_byte(logic [3:0] pid);
    pid_byte = {~pid, pid};
  endfunction

  // ----------------- CRC5 for TOKEN (match crc5.v + crc5_t.v) -----------------
  // DUT等效：d = {addr[0],...,addr[6], endp[0],endp[1],endp[2],endp[3]}
  // c = 5'h1f；c_out按crc5.v公式，最后crc_out = {~c_out[0],...~c_out[4]}
  function automatic logic [4:0] crc5_token_bits(input logic [6:0] addr, input logic [3:0] endp);
    logic [10:0] d;
    logic [4:0]  c, co;
    c = 5'h1f;
    d = {addr[0], addr[1], addr[2], addr[3], addr[4], addr[5], addr[6],
         endp[0], endp[1], endp[2], endp[3]};
    co[0] = d[10] ^ d[9] ^ d[6] ^ d[5] ^ d[3] ^ d[0] ^ c[0] ^ c[3] ^ c[4];
    co[1] = d[10] ^ d[7] ^ d[6] ^ d[4] ^ d[1] ^ c[0] ^ c[1] ^ c[4];
    co[2] = d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[3] ^ d[2] ^ d[0] ^
            c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[4];
    co[3] = d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[4] ^ d[3] ^ d[1] ^
            c[1] ^ c[2] ^ c[3] ^ c[4];
    co[4] = d[10] ^ d[9] ^ d[8] ^ d[5] ^ d[4] ^ d[2] ^
            c[2] ^ c[3] ^ c[4];
    // 注意顺序与 DUT 一致：{~c_out[0], ~c_out[1], ~c_out[2], ~c_out[3], ~c_out[4]}
    crc5_token_bits = {~co[0], ~co[1], ~co[2], ~co[3], ~co[4]};
  endfunction

  // ----------------- CRC16 next (match crc16.v) -----------------
  function automatic logic [15:0] crc16_next(input logic [15:0] c, input byte data);
    logic [7:0] d;
    logic [15:0] n;
    d = data;
    n[0]  = c[10]^c[11]^c[12]^c[13]^c[14]^c[15]^c[8]^c[9]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6]^d[7];
    n[1]  = c[10]^c[11]^c[12]^c[13]^c[14]^c[15]^c[9]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6];
    n[2]  = c[8]^c[9]^d[6]^d[7];
    n[3]  = c[10]^c[9]^d[5]^d[6];
    n[4]  = c[10]^c[11]^d[4]^d[5];
    n[5]  = c[11]^c[12]^d[3]^d[4];
    n[6]  = c[12]^c[13]^d[2]^d[3];
    n[7]  = c[13]^c[14]^d[1]^d[2];
    n[8]  = c[0]^c[14]^c[15]^d[0]^d[1];
    n[9]  = c[1]^c[15]^d[0];
    n[10] = c[2];
    n[11] = c[3];
    n[12] = c[4];
    n[13] = c[5];
    n[14] = c[6];
    n[15] = c[10]^c[11]^c[12]^c[13]^c[14]^c[15]^c[7]^c[8]^c[9]^
            d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6]^d[7];
    return n;
  endfunction

  // 按 DUT 的接收端做最终比较的方式生成要发出去的 CRC16 两字节：
  // 起始值 0xFFFF；对 payload（不含 PID）逐字节调用 crc16_next；
  // 然后做：crc_inv = ~{c[8],..,c[15], c[0],..,c[7]}；
  // 发送顺序：低字节在前（即 crc_inv[7:0] 先发，crc_inv[15:8] 后发）
  function automatic void make_crc16_bytes(input byte payload[], output byte crc_lo, output byte crc_hi);
    logic [15:0] c;
    c = 16'hFFFF;
    foreach (payload[i]) c = crc16_next(c, payload[i]);
    crc_lo = ~{ c[8], c[9], c[10], c[11], c[12], c[13], c[14], c[15]};
    crc_hi = ~{ c[0], c[1], c[2],  c[3],  c[4],  c[5],  c[6],  c[7] };
  endfunction

  // ----------------- Transaction object -----------------
  class usb_transaction;
    rand logic [1:0]  case_id;         // 0~3
    rand logic        ms;              // 由case决定
    rand logic [6:0]  self_addr;
    rand logic [15:0] time_threshole;
    rand logic [5:0]  delay_threshole;
    rand logic [3:0]  endp;
    rand int unsigned data_len;        // payload长度（不含PID/CRC）
    rand byte         data_bytes[];    // payload内容

    // Derived / expected packets
    byte token_b0, token_b1, token_b2;
    byte data_pid_b0;
    byte crc16_lo, crc16_hi;

    // Constraints
    constraint c_case {
      case_id inside {[0:3]};
      (case_id==0 || case_id==1) -> ms==1'b0;
      (case_id==2 || case_id==3) -> ms==1'b1;
    }
    constraint c_ranges {
      self_addr inside {[1:127]};
      endp inside {[0:15]};
      time_threshole inside {[10:1200]};
      delay_threshole inside {[0:63]};
      data_len inside {[1:32]};
      data_bytes.size() == data_len;
      foreach (data_bytes[i]) data_bytes[i] inside {[0:255]};
    }

    function void build_expected_packets();
      // TOKEN
      logic [4:0] c5 = crc5_token_bits(self_addr, endp);
      token_b0 = pid_byte((case_id==0 || case_id==3) ? PID_IN : PID_OUT);
      token_b1 = {endp[0], self_addr};                 // 与 DUT 一致
      token_b2 = {c5, endp[3:1]};                      // 与 DUT 一致
      // DATA0
      data_pid_b0 = pid_byte(PID_DATA0);
      // CRC16 两字节（低位先发）
      make_crc16_bytes(data_bytes, crc16_lo, crc16_hi);
    endfunction

    function void display();
      $display("[TRANS] case=%0d ms=%0d addr=%0d endp=%0d len=%0d time_th=%0d delay_th=%0d",
               case_id, ms, self_addr, endp, data_len, time_threshole, delay_threshole);
    endfunction
  endclass

endpackage : usb_tb_pkg

//=========================== Interface ========================
interface usb_if(input logic clk, input logic rst_n);

  // DUT ports (same names as DUT)
  // inputs
  logic [6:0] self_addr;
  logic       ms;
  logic [15:0] time_threshold;
  logic [5:0]  delay_threshole;

  logic rx_lp_sop, rx_lp_eop, rx_lp_valid;
  logic [7:0] rx_lp_data;
  logic tx_lp_ready;
  logic rx_lt_ready;
  logic [3:0] tx_pid;
  logic [6:0] tx_addr;
  logic [3:0] tx_endp;
  logic       tx_valid;
  logic       tx_lt_sop, tx_lt_eop, tx_lt_valid;
  logic [7:0] tx_lt_data;
  logic       tx_lt_cancle;

  // outputs
  logic crc5_err, crc16_err, time_out, d_oe;
  logic rx_lp_ready;
  logic tx_lp_sop, tx_lp_eop, tx_lp_valid;
  logic [7:0] tx_lp_data;
  logic tx_lp_cancle;
  logic rx_pid_en;
  logic [3:0] rx_pid;
  logic [3:0] rx_endp;
  logic rx_lt_sop, rx_lt_eop, rx_lt_valid;
  logic [7:0] rx_lt_data;
  logic tx_ready;
  logic tx_lt_ready;

  task automatic wait_clks(int n); repeat(n) @(posedge clk); endtask
endinterface : usb_if

//=========================== Classes ==========================
import usb_tb_pkg::*;

class usb_driver;
  virtual usb_if vif;

  // 仅用于制造 backpressure 的空等拍数
  int gap_cycles_token = 32;
  int gap_cycles_data  = 32;

  function new(virtual usb_if vif);
    this.vif = vif;
  endfunction

  //==================== 基础握手工具 ====================

  // (PHY->DUT) 在 rx_lp_* 上推送一个字节（valid 等 rx_lp_ready）
  task automatic phy_push_rx_byte(byte b, logic sop=0, logic eop=0, int gap=32);
    vif.rx_lp_sop   <= sop;
    vif.rx_lp_eop   <= eop;
    vif.rx_lp_data  <= b;
    vif.rx_lp_valid <= 1'b1;

    @(posedge vif.clk);
    while (!vif.rx_lp_ready) @(posedge vif.clk);
    #1;
    vif.rx_lp_valid <= 1'b0;
    vif.rx_lp_sop   <= 1'b0;
    vif.rx_lp_eop   <= 1'b0;
    repeat (gap) @(posedge vif.clk);
  endtask

  // (DUT->PHY) 在 tx_lp_* 上按“一个字节=一个 ready 脉冲”消费 nbytes
  task automatic phy_consume_tx_lp(int nbytes, int wait_lp);
    vif.tx_lp_ready <= 1'b0;
    for (int j = 0; j < nbytes; j++) begin
      @(posedge vif.clk);
      while (!vif.tx_lp_valid) @(posedge vif.clk); // 等待有字节可取

      vif.tx_lp_ready <= 1'b1;
      @(posedge vif.clk);
      vif.tx_lp_ready <= 1'b0;
      repeat (wait_lp) @(posedge vif.clk);
    end
  endtask

  // (TB->DUT) 经 tx_lt_* 发送一串字节（逐字节：valid 等 tx_lt_ready）
  // seq[0] 置 SOP，最后一字节置 EOP
  task automatic lt_send_seq(input byte seq[$], int wait_lt);
    int n = seq.size();
    if (n == 0) return;

    vif.tx_lt_sop   <= 1'b0;
    vif.tx_lt_eop   <= 1'b0;
    vif.tx_lt_valid <= 1'b0;

    for (int i = 0; i < n; i++) begin
      vif.tx_lt_data  <= seq[i];
      vif.tx_lt_sop   <= (i == 0);
      vif.tx_lt_eop   <= (i == n-1);
      vif.tx_lt_valid <= 1'b1;

      @(posedge vif.clk);
      while (!vif.tx_lt_ready) @(posedge vif.clk); // 等待准备好

      #1;
      vif.tx_lt_valid <= 1'b0;
      vif.tx_lt_sop   <= 1'b0;
      vif.tx_lt_eop   <= 1'b0;

      repeat (wait_lt) @(posedge vif.clk);
    end
  endtask

  // (DUT->TB) 消费 rx_lt_* 流，直到拿到带 EOP 的最后一个字节
  task automatic lt_consume_rx_until_eop(int wait_lt);
    bit last_eop;
    vif.rx_lt_ready <= 1'b0;

    // 等待起始（SOP 出现/或直接进入数据有效）
    @(posedge vif.clk);
    // 可选：等待到 SOP；若不要求可删掉下一行
    // while (!(vif.rx_lt_valid && vif.rx_lt_sop)) @(posedge vif.clk);

    do begin
      @(posedge vif.clk);
      while (!vif.rx_lt_valid) @(posedge vif.clk);
      last_eop = vif.rx_lt_eop;

      vif.rx_lt_ready <= 1'b1;
      @(posedge vif.clk);
      vif.rx_lt_ready <= 1'b0;

      repeat (wait_lt) @(posedge vif.clk);
    end while (!last_eop);
  endtask

  // (控制口) 触发 TOKEN：tx_valid 等 tx_ready
  task automatic ctrl_push_token(logic [3:0] pid, logic [6:0] addr, logic [3:0] endp);
    vif.tx_pid   <= pid;
    vif.tx_addr  <= addr;
    vif.tx_endp  <= endp;
    vif.tx_valid <= 1'b1;

    @(posedge vif.clk);
    while (!vif.tx_ready) @(posedge vif.clk); // 等待控制握手完成

    #1;
    vif.tx_valid <= 1'b0;
  endtask

  //==================== 各用例序列 ====================

  // ------------------------ CASE0 ------------------------
  // (slave): rx TOKEN(IN) -> DUT tx DATA0 -> rx ACK
  task automatic drive_case0(usb_transaction tr);
    byte seq[$];
    int total_bytes = 1 + tr.data_len + 2; // DATA0: PID + payload + CRC16

    // 配置
    vif.ms              <= 1'b0;
    vif.self_addr       <= tr.self_addr;
    vif.time_threshold  <= tr.time_threshole;
    vif.delay_threshole <= tr.delay_threshole;
    @(posedge vif.clk);

    // rx token (phy->dut)
    phy_push_rx_byte(tr.token_b0, 1, 0, gap_cycles_token);
    phy_push_rx_byte(tr.token_b1, 0, 0, gap_cycles_token);
    phy_push_rx_byte(tr.token_b2, 0, 1, gap_cycles_token);

    // tx DATA0: lt->dut push + dut->phy consume
    seq.push_back(tr.data_pid_b0);
    foreach (tr.data_bytes[i]) seq.push_back(tr.data_bytes[i]);
    seq.push_back(tr.crc16_lo);
    seq.push_back(tr.crc16_hi);

    repeat (40) @(posedge vif.clk); // token 与 data 之间留点缝
    fork
      lt_send_seq(seq, gap_cycles_data);
      phy_consume_tx_lp(total_bytes, gap_cycles_data);
    join

    // rx ACK (phy->dut push)
    repeat (80) @(posedge vif.clk);
    phy_push_rx_byte(pid_byte(PID_ACK), 1, 1, gap_cycles_token);
  endtask

  // ------------------------ CASE1 ------------------------
  // (slave): rx TOKEN(OUT) -> rx DATA0 -> DUT tx ACK
  task automatic drive_case1(usb_transaction tr);
    // 配置
    vif.ms              <= 1'b0;
    vif.self_addr       <= tr.self_addr;
    vif.time_threshold  <= tr.time_threshole;
    vif.delay_threshole <= tr.delay_threshole;
    @(posedge vif.clk);

    // rx token (phy->dut)
    phy_push_rx_byte(tr.token_b0, 1, 0, gap_cycles_token);
    phy_push_rx_byte(tr.token_b1, 0, 0, gap_cycles_token);
    phy_push_rx_byte(tr.token_b2, 0, 1, gap_cycles_token);

    // rx DATA0: phy->dut push 与 dut->lt consume 同时进行
    repeat (80) @(posedge vif.clk);
    fork
      begin : push_rx_data0
        phy_push_rx_byte(tr.data_pid_b0, 1, 0, gap_cycles_data);
        foreach (tr.data_bytes[i]) phy_push_rx_byte(tr.data_bytes[i], 0, 0, gap_cycles_data);
        phy_push_rx_byte(tr.crc16_lo, 0, 0, gap_cycles_data);
        phy_push_rx_byte(tr.crc16_hi, 0, 1, gap_cycles_data);
      end
      begin : consume_to_lt
        lt_consume_rx_until_eop(gap_cycles_data);
      end
    join

    // tx ACK: dut->phy consume (1 字节)
    fork
      ctrl_push_token(PID_ACK, tr.self_addr, tr.endp);
      phy_consume_tx_lp(1, /*wait_lp*/ 5);
    join
  endtask

  // ------------------------ CASE2 ------------------------
  // (master): tx TOKEN(OUT) -> tx DATA0 -> rx ACK
  task automatic drive_case2(usb_transaction tr);
    byte seq[$];
    int total_bytes = 1 + tr.data_len + 2;

    // 配置
    vif.ms              <= 1'b1;
    vif.self_addr       <= tr.self_addr;
    vif.time_threshold  <= tr.time_threshole;
    vif.delay_threshole <= tr.delay_threshole;
    @(posedge vif.clk);

    // tx token: lt->dut 控制 push + dut->phy consume (3B: PID+B1+B2)
    fork
      ctrl_push_token(PID_OUT, tr.self_addr, tr.endp);
      phy_consume_tx_lp(3, /*wait_lp*/ 5);
    join

    // tx DATA0: lt->dut push + dut->phy consume
    seq.push_back(tr.data_pid_b0);
    foreach (tr.data_bytes[i]) seq.push_back(tr.data_bytes[i]);
    seq.push_back(tr.crc16_lo);
    seq.push_back(tr.crc16_hi);

    repeat (40) @(posedge vif.clk); // token 与 data 之间留点缝
    fork
      lt_send_seq(seq, gap_cycles_data);
      phy_consume_tx_lp(total_bytes, gap_cycles_data);
    join

    // rx ACK (phy->dut push)
    repeat (80) @(posedge vif.clk);
    phy_push_rx_byte(pid_byte(PID_ACK), 1, 1, gap_cycles_token);
  endtask

  // ------------------------ CASE3 ------------------------
  // (master): tx TOKEN(IN) -> rx DATA0 -> tx ACK
  task automatic drive_case3(usb_transaction tr);
    // 配置
    vif.ms              <= 1'b1;
    vif.self_addr       <= tr.self_addr;
    vif.time_threshold  <= tr.time_threshole;
    vif.delay_threshole <= tr.delay_threshole;
    @(posedge vif.clk);

    // tx token: lt->dut 控制 push + dut->phy consume (3B)
    fork
      ctrl_push_token(PID_IN, tr.self_addr, tr.endp);
      phy_consume_tx_lp(3, /*wait_lp*/ 5);
    join

    // rx DATA0: phy->dut push + dut->lt consume
    repeat (136) @(posedge vif.clk);
    fork
      begin : push_rx_data0
        phy_push_rx_byte(tr.data_pid_b0, 1, 0, gap_cycles_data);
        foreach (tr.data_bytes[i]) phy_push_rx_byte(tr.data_bytes[i], 0, 0, gap_cycles_data);
        phy_push_rx_byte(tr.crc16_lo, 0, 0, gap_cycles_data);
        phy_push_rx_byte(tr.crc16_hi, 0, 1, gap_cycles_data);
      end
      begin : consume_to_lt
        lt_consume_rx_until_eop(gap_cycles_data);
      end
    join

    repeat (40) @(posedge vif.clk);
    fork
      ctrl_push_token(PID_ACK, tr.self_addr, tr.endp);
      phy_consume_tx_lp(1, /*wait_lp*/ 5);
    join

  endtask

  // ------------------------ 顶层入口 ------------------------
  task automatic drive(usb_transaction tr);
    tr.display();
    case (tr.case_id)
      0: drive_case0(tr);
      1: drive_case1(tr);
      2: drive_case2(tr);
      3: drive_case3(tr);
    endcase
  endtask

endclass



// ------------------------- Monitors -------------------------
// 包裹 DUT->PHY / DUT->LT 上看到的一帧（首字节为 PID，随后为负载）
class phy_packet_t;
  logic sop, eop;
  byte  bytes[$];  // bytes[0] = PID byte {~pid, pid}
endclass

// 捕捉 rx_pid_en 的事件（DUT->LT 对“接收端”解析到的 TOKEN/ACK）
class rx_pid_event_t;
  logic [3:0] pid;    // 与 DUT 的 rx_pid 对应
  logic [3:0] endp;   // 与 DUT 的 rx_endp 对应（ACK 的 endp 可能无意义，按 DUT 行为）
endclass


// ========== DUT->PHY: 监视 tx_lp_* ==========
// 注意：采样以 (tx_lp_valid && tx_lp_ready) 为真正的数据传输时刻
class phy_tx_monitor;
  virtual usb_if vif;
  mailbox #(phy_packet_t) mbox;

  function new(virtual usb_if vif, mailbox #(phy_packet_t) mbox);
    this.vif = vif; this.mbox = mbox;
  endfunction

  task run();
    forever begin
      phy_packet_t p;
      // 等待一个带 SOP 的有效握手周期作为包的开始
      @(posedge vif.clk);
      while (!(vif.tx_lp_sop && vif.tx_lp_valid && vif.tx_lp_ready)) @(posedge vif.clk);

      // 开始收包（在握手周期读取数据）
      p = new();
      p.bytes = {};
      p.sop = 1;
      p.eop = 0;

      // 抓取首字节（SOP 那个握手周期）
      p.bytes.push_back(vif.tx_lp_data);
      if (vif.tx_lp_eop) begin
        p.eop = 1;
        mbox.put(p);
        continue;
      end

      // 抓取后续字节：每个字节等 valid && ready 的握手周期
      forever begin
        @(posedge vif.clk);
        // 等待下一个完整的握手（valid && ready）
        while (!(vif.tx_lp_valid && vif.tx_lp_ready)) @(posedge vif.clk);

        p.bytes.push_back(vif.tx_lp_data);
        if (vif.tx_lp_eop) begin
          p.eop = 1;
          mbox.put(p);
          break;
        end
      end
    end
  endtask
endclass


// ========== DUT->LT: 监视 rx_lt_*（包含 PID + payload）==========
// 注意：采样以 (rx_lt_valid && rx_lt_ready) 为真正的数据传输时刻
class lt_rx_monitor;
  virtual usb_if vif;
  mailbox #(phy_packet_t) mbox;

  function new(virtual usb_if vif, mailbox #(phy_packet_t) mbox);
    this.vif = vif; this.mbox = mbox;
  endfunction

  task run();
    forever begin
      phy_packet_t p;
      // 等待一个带 SOP 的有效握手周期作为包的开始
      @(posedge vif.clk);
      while (!(vif.rx_lt_sop && vif.rx_lt_valid && vif.rx_lt_ready)) @(posedge vif.clk);

      p = new();
      p.bytes = {};
      p.sop = 1;
      p.eop = 0;

      // 抓取首字节（SOP 那个握手周期）
      p.bytes.push_back(vif.rx_lt_data);
      if (vif.rx_lt_eop) begin
        p.eop = 1;
        mbox.put(p);
        continue;
      end

      // 抓取后续字节：每个字节等 valid && ready 的握手周期
      forever begin
        @(posedge vif.clk);
        while (!(vif.rx_lt_valid && vif.rx_lt_ready)) @(posedge vif.clk);

        p.bytes.push_back(vif.rx_lt_data);
        if (vif.rx_lt_eop) begin
          p.eop = 1;
          mbox.put(p);
          break;
        end
      end
    end
  endtask
endclass


// ========== 捕捉 rx_pid_en（接收到 TOKEN/ACK 时的 1 周期脉冲）==========
// 这一块保持不变：rx_pid_en 已经是 DUT 在解析到 TOKEN/ACK 时的单周期脉冲
class rx_pid_monitor;
  virtual usb_if vif;
  mailbox #(rx_pid_event_t) mbox;

  function new(virtual usb_if vif, mailbox #(rx_pid_event_t) mbox);
    this.vif = vif; this.mbox = mbox;
  endfunction

  task run();
    forever begin
      @(posedge vif.clk);
      if (vif.rx_pid_en) begin
        rx_pid_event_t ev = new();
        ev.pid  = vif.rx_pid;
        ev.endp = vif.rx_endp;
        mbox.put(ev);
      end
    end
  endtask
endclass


// ------------------------- Scoreboard -----------------------
class usb_scoreboard;
  mailbox #(usb_transaction) exp_mbox;
  mailbox #(phy_packet_t)    phy_mbox;
  mailbox #(phy_packet_t)    lt_mbox;
  mailbox #(rx_pid_event_t)  rxpid_mbox;

  function new(mailbox #(usb_transaction) e,
               mailbox #(phy_packet_t)    p_txphy,
               mailbox #(phy_packet_t)    p_lt,
               mailbox #(rx_pid_event_t)  p_rxpid);
    exp_mbox   = e;
    phy_mbox   = p_txphy;
    lt_mbox    = p_lt;
    rxpid_mbox = p_rxpid;
  endfunction

  // helper: compare PID byte
  function automatic logic is_pid(byte b, logic [3:0] pid);
    return b == {~pid, pid};
  endfunction

  // helper: return index of first mismatch between pkt.bytes[1..] and ref_bytes[0..len-1]
  // returns: -1 if equal, -2 if pkt too short, otherwise index (0..len-1) of first mismatch
  function automatic int payload_mismatch_index(ref phy_packet_t pkt,
                                                ref byte ref_bytes[],
                                                int unsigned len);
    int unsigned pkt_payload_len;
    if (pkt.bytes.size() < 1) begin
      return -2; // no pid even
    end
    pkt_payload_len = pkt.bytes.size() - 1;
    if (pkt_payload_len < len) return -2;
    for (int i = 0; i < len; i++) begin
      if (pkt.bytes[i+1] !== ref_bytes[i]) return i;
    end
    return -1;
  endfunction

  // helper: print a phy_packet_t (PID + payload)
  task automatic print_packet(phy_packet_t pkt, string name);
    string line;
    $display("  [DUMP] %s : size=%0d", name, pkt.bytes.size());
    if (pkt.bytes.size() == 0) begin
      $display("    <empty>");
      return;
    end
    // print bytes as hex
    line = "";
    for (int i = 0; i < pkt.bytes.size(); i++) begin
      line = { line, $sformatf("%02h ", pkt.bytes[i]) };
    end
    $display("    bytes: %s", line);
    // mark PID and payload slice
    if (pkt.bytes.size() > 0) begin
      $display("    pid_byte=%02h (pid_nibble=%01h)", pkt.bytes[0], pkt.bytes[0][3:0]);
      if (pkt.bytes.size() > 1) begin
        line = "";
        for (int j = 1; j < pkt.bytes.size(); j++) line = { line, $sformatf("%02h ", pkt.bytes[j]) };
        $display("    payload: %s", line);
      end
    end
  endtask

  // helper: print expected payload array
  task automatic print_expected_payload(byte exp_bytes[], int unsigned len, string tag);
    string line;
    line = "";
    for (int i = 0; i < len; i++) begin
      line = { line, $sformatf("%02h ", exp_bytes[i]) };
    end
    $display("  [DUMP] %s expected len=%0d : %s", tag, len, line);
  endtask

  // top-level run: receives expected transaction and compares against observed mailboxes
  task run();
    forever begin
      usb_transaction tr;
      exp_mbox.get(tr);

      case (tr.case_id)
        // ================= CASE 0: slave; RX TOKEN(IN) -> TX DATA0 -> RX ACK =================
        0: begin
          rx_pid_event_t ev_tok;
          phy_packet_t dpk;
          rx_pid_event_t ev_ack;

          // 1) RX TOKEN: check rxpid event contains correct PID & endp
          rxpid_mbox.get(ev_tok);
          if ((ev_tok.pid !== PID_IN) || (ev_tok.endp !== tr.endp)) begin
            $error("[SB][case0][%0t] RX TOKEN mismatch: got pid=%0h endp=%0d  expected pid=IN(%0h) endp=%0d",
                   $time, ev_tok.pid, ev_tok.endp, PID_IN, tr.endp);
            $display("  Diagnostic: transaction: addr=%0d endp=%0d", tr.self_addr, tr.endp);
            $display("  rxpid event: pid=%0h endp=%0d", ev_tok.pid, ev_tok.endp);
          end else begin
            $display("[SB][case0][%0t] RX TOKEN IN PASS (endp=%0d)", $time, tr.endp);
          end

          // 2) DUT->PHY DATA0: check PID and payload
          phy_mbox.get(dpk);
          if (!is_pid(dpk.bytes.size()?dpk.bytes[0]:8'h00, PID_DATA0)) begin
            $error("[SB][case0][%0t] TX first packet is not DATA0 (first_byte=%02h)", $time,
                   (dpk.bytes.size()?dpk.bytes[0]:8'hxx));
            print_packet(dpk, "dut->phy packet");
            print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
          end else begin
            int mismatch = payload_mismatch_index(dpk, tr.data_bytes, tr.data_len);
            if (mismatch == -2) begin
              $error("[SB][case0][%0t] DATA0 payload too short: expected_len=%0d pkt_payload_len=%0d",
                     $time, tr.data_len, (dpk.bytes.size()?dpk.bytes.size()-1:0));
              print_packet(dpk, "dut->phy packet");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else if (mismatch >= 0) begin
              $error("[SB][case0][%0t] DATA0 payload mismatch at index %0d: expected=%02h got=%02h",
                     $time, mismatch, tr.data_bytes[mismatch], dpk.bytes[mismatch+1]);
              print_packet(dpk, "dut->phy packet");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else begin
              $display("[SB][case0][%0t] TX DATA0 PASS (len=%0d)", $time, tr.data_len);
            end
          end

          // 3) RX ACK: check rxpid event for ACK
          rxpid_mbox.get(ev_ack);
          if (ev_ack.pid !== PID_ACK) begin
            $error("[SB][case0][%0t] RX ACK mismatch: got pid=%0h expected=ACK(%0h)",
                   $time, ev_ack.pid, PID_ACK);
            $display("  rxpid event: pid=%0h endp=%0d", ev_ack.pid, ev_ack.endp);
          end else begin
            $display("[SB][case0][%0t] RX ACK PASS", $time);
          end
        end

        // ================= CASE 1: slave; RX TOKEN(OUT) -> RX DATA0 -> TX ACK =================
        1: begin
          rx_pid_event_t ev_tok;
          phy_packet_t ltpkt;
          phy_packet_t ack;

          // RX TOKEN OUT
          rxpid_mbox.get(ev_tok);
          if ((ev_tok.pid !== PID_OUT) || (ev_tok.endp !== tr.endp)) begin
            $error("[SB][case1][%0t] RX TOKEN mismatch: got pid=%0h endp=%0d expected pid=OUT(%0h) endp=%0d",
                   $time, ev_tok.pid, ev_tok.endp, PID_OUT, tr.endp);
            $display("  rxpid event: pid=%0h endp=%0d", ev_tok.pid, ev_tok.endp);
            $display("  transaction: addr=%0d endp=%0d", tr.self_addr, tr.endp);
          end else begin
            $display("[SB][case1][%0t] RX TOKEN OUT PASS", $time);
          end

          // DUT->LT: DATA0
          lt_mbox.get(ltpkt);
          if (!is_pid(ltpkt.bytes.size()?ltpkt.bytes[0]:8'h00, PID_DATA0)) begin
            $error("[SB][case1][%0t] LT packet is not DATA0 (first_byte=%02h)", $time,
                   (ltpkt.bytes.size()?ltpkt.bytes[0]:8'hxx));
            print_packet(ltpkt, "dut->lt packet");
            print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
          end else begin
            int mismatch = payload_mismatch_index(ltpkt, tr.data_bytes, tr.data_len);
            if (mismatch == -2) begin
              $error("[SB][case1][%0t] LT DATA0 payload too short: expected_len=%0d pkt_payload_len=%0d",
                     $time, tr.data_len, (ltpkt.bytes.size()?ltpkt.bytes.size()-1:0));
              print_packet(ltpkt, "dut->lt packet");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else if (mismatch >= 0) begin
              $error("[SB][case1][%0t] LT DATA0 payload mismatch at index %0d: expected=%02h got=%02h",
                     $time, mismatch, tr.data_bytes[mismatch], ltpkt.bytes[mismatch+1]);
              print_packet(ltpkt, "dut->lt packet");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else begin
              $display("[SB][case1][%0t] LT DATA0 PASS (len=%0d)", $time, tr.data_len);
            end
          end

          // TX ACK (DUT->PHY)
          phy_mbox.get(ack);
          if (!is_pid(ack.bytes.size()?ack.bytes[0]:8'h00, PID_ACK)) begin
            $error("[SB][case1][%0t] TX packet is not ACK (first_byte=%02h)", $time,
                   (ack.bytes.size()?ack.bytes[0]:8'hxx));
            print_packet(ack, "dut->phy packet");
          end else begin
            $display("[SB][case1][%0t] TX ACK PASS", $time);
          end
        end

        // ================= CASE 2: master; TX TOKEN(OUT) -> TX DATA0 -> RX ACK =================
        2: begin
          phy_packet_t tok;
          phy_packet_t dpk;
          rx_pid_event_t ev_ack;

          // TX TOKEN OUT
          phy_mbox.get(tok);
          if (!is_pid(tok.bytes.size()?tok.bytes[0]:8'h00, PID_OUT)) begin
            $error("[SB][case2][%0t] First TX packet not OUT TOKEN (first_byte=%02h)", $time,
                   (tok.bytes.size()?tok.bytes[0]:8'hxx));
            print_packet(tok, "dut->phy packet #1 (token)");
          end else begin
            $display("[SB][case2][%0t] TX TOKEN OUT PASS", $time);
          end

          // TX DATA0
          phy_mbox.get(dpk);
          if (!is_pid(dpk.bytes.size()?dpk.bytes[0]:8'h00, PID_DATA0)) begin
            $error("[SB][case2][%0t] Second TX packet not DATA0 (first_byte=%02h)", $time,
                   (dpk.bytes.size()?dpk.bytes[0]:8'hxx));
            print_packet(dpk, "dut->phy packet #2 (data)");
            print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
          end else begin
            int mismatch = payload_mismatch_index(dpk, tr.data_bytes, tr.data_len);
            if (mismatch == -2) begin
              $error("[SB][case2][%0t] TX DATA0 payload too short: expected_len=%0d pkt_payload_len=%0d",
                     $time, tr.data_len, (dpk.bytes.size()?dpk.bytes.size()-1:0));
              print_packet(dpk, "dut->phy packet #2 (data)");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else if (mismatch >= 0) begin
              $error("[SB][case2][%0t] TX DATA0 payload mismatch at index %0d: expected=%02h got=%02h",
                     $time, mismatch, tr.data_bytes[mismatch], dpk.bytes[mismatch+1]);
              print_packet(dpk, "dut->phy packet #2 (data)");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else begin
              $display("[SB][case2][%0t] TX DATA0 PASS (len=%0d)", $time, tr.data_len);
            end
          end

          // RX ACK
          rxpid_mbox.get(ev_ack);
          if (ev_ack.pid !== PID_ACK) begin
            $error("[SB][case2][%0t] RX ACK mismatch: got pid=%0h expected=ACK(%0h)",
                   $time, ev_ack.pid, PID_ACK);
            $display("  rxpid event: pid=%0h endp=%0d", ev_ack.pid, ev_ack.endp);
          end else begin
            $display("[SB][case2][%0t] RX ACK PASS", $time);
          end
        end

        // ================= CASE 3: master; TX TOKEN(IN) -> RX DATA0 -> TX ACK =================
        3: begin
          phy_packet_t tok;
          phy_packet_t ltpkt;
          phy_packet_t ack;

          // TX TOKEN IN
          phy_mbox.get(tok);
          if (!is_pid(tok.bytes.size()?tok.bytes[0]:8'h00, PID_IN)) begin
            $error("[SB][case3][%0t] First TX packet not IN TOKEN (first_byte=%02h)", $time,
                   (tok.bytes.size()?tok.bytes[0]:8'hxx));
            print_packet(tok, "dut->phy packet #1 (token)");
          end else begin
            $display("[SB][case3][%0t] TX TOKEN IN PASS", $time);
          end

          // RX DATA0 (DUT->LT)
          lt_mbox.get(ltpkt);
          if (!is_pid(ltpkt.bytes.size()?ltpkt.bytes[0]:8'h00, PID_DATA0)) begin
            $error("[SB][case3][%0t] LT packet is not DATA0 (first_byte=%02h)", $time,
                   (ltpkt.bytes.size()?ltpkt.bytes[0]:8'hxx));
            print_packet(ltpkt, "dut->lt packet");
            print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
          end else begin
            int mismatch = payload_mismatch_index(ltpkt, tr.data_bytes, tr.data_len);
            if (mismatch == -2) begin
              $error("[SB][case3][%0t] LT DATA0 payload too short: expected_len=%0d pkt_payload_len=%0d",
                     $time, tr.data_len, (ltpkt.bytes.size()?ltpkt.bytes.size()-1:0));
              print_packet(ltpkt, "dut->lt packet");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else if (mismatch >= 0) begin
              $error("[SB][case3][%0t] LT DATA0 payload mismatch at index %0d: expected=%02h got=%02h",
                     $time, mismatch, tr.data_bytes[mismatch], ltpkt.bytes[mismatch+1]);
              print_packet(ltpkt, "dut->lt packet");
              print_expected_payload(tr.data_bytes, tr.data_len, "expected payload");
            end else begin
              $display("[SB][case3][%0t] LT DATA0 PASS (len=%0d)", $time, tr.data_len);
            end
          end

          // TX ACK (DUT->PHY)
          phy_mbox.get(ack);
          if (!is_pid(ack.bytes.size()?ack.bytes[0]:8'h00, PID_ACK)) begin
            $error("[SB][case3][%0t] TX packet is not ACK (first_byte=%02h)", $time,
                   (ack.bytes.size()?ack.bytes[0]:8'hxx));
            print_packet(ack, "dut->phy packet #3 (ack)");
          end else begin
            $display("[SB][case3][%0t] TX ACK PASS", $time);
          end
        end

        default: begin
          $display("[SB] Unknown case %0d", tr.case_id);
        end
      endcase
    end
  endtask
endclass





// ------------------------- Coverage -------------------------
class usb_cov;
  int case_id, data_len, endp, self_addr, time_th, delay_th;
  covergroup cg;
    coverpoint case_id { bins all[] = {[0:3]}; }
    coverpoint data_len { bins s={[1:4]}; bins m={[5:16]}; bins l={[17:32]}; }
    coverpoint endp { bins e0={[0:7]}; bins e1={[8:15]}; }
    coverpoint self_addr { bins low={[1:31]}; bins mid={[32:95]}; bins hi={[96:127]}; }
    coverpoint time_th { bins t0={[10:200]}; bins t1={[201:600]}; bins t2={[601:1200]}; }
    coverpoint delay_th { bins d0={[0:15]}; bins d1={[16:31]}; bins d2={[32:47]}; bins d3={[48:63]}; }
    cross case_id, data_len;
    cross case_id, endp;
    option.per_instance = 1;
  endgroup
  function new(); cg = new(); endfunction
  function void sample(usb_transaction tr);
    case_id    = tr.case_id;
    data_len   = tr.data_len;
    endp       = tr.endp;
    self_addr  = tr.self_addr;
    time_th    = tr.time_threshole;
    delay_th   = tr.delay_threshole;
    cg.sample();
    // 打印当前覆盖率
    $display("[%0t] Functional coverage now = %0.2f%%", $time, cg.get_inst_coverage());
  endfunction
endclass

// --------------------------- Env ----------------------------
class usb_env;
  virtual usb_if vif;
  usb_driver       drv;
  phy_tx_monitor   mon_phy;
  lt_rx_monitor    mon_ltrx;
  rx_pid_monitor   mon_rxpid;
  usb_scoreboard   sb;
  usb_cov          cov;

  mailbox #(usb_transaction) exp_mbox   = new();
  mailbox #(phy_packet_t)    phy_mbox   = new();
  mailbox #(phy_packet_t)    ltrx_mbox  = new();
  mailbox #(rx_pid_event_t)  rxpid_mbox = new();

  function new(virtual usb_if vif);
    this.vif = vif;
    drv = new(vif);
    mon_phy   = new(vif, phy_mbox);
    mon_ltrx  = new(vif, ltrx_mbox);
    mon_rxpid = new(vif, rxpid_mbox);
    sb = new(exp_mbox, phy_mbox, ltrx_mbox, rxpid_mbox);
    cov = new();
  endfunction

  task run(int n_iters = 40);
    // 启动 monitors + scoreboard（后台运行）
    fork
      mon_phy.run();
      mon_ltrx.run();
      mon_rxpid.run();
      sb.run();
    join_none

    // 初始化 iface 信号（把数据/valid 类信号清零，ready 保持为可用）
    vif.rx_lp_sop    <= 1'b0; vif.rx_lp_eop  <= 1'b0; vif.rx_lp_valid <= 1'b0; vif.rx_lp_data <= 8'h00;
    vif.tx_lp_ready  <= 1'b1; // PHY 默认可接收（driver 在需要时会按策略驱动脉冲）
    vif.tx_lp_cancle <= 1'b0;
    vif.rx_lt_ready  <= 1'b1; // LT 默认可接收
    vif.rx_lt_sop    <= 1'b0; vif.rx_lt_eop  <= 1'b0; vif.rx_lt_valid <= 1'b0; vif.rx_lt_data <= 8'h00;

    vif.tx_lt_sop    <= 1'b0; vif.tx_lt_eop  <= 1'b0; vif.tx_lt_valid <= 1'b0; vif.tx_lt_data <= 8'h00; vif.tx_lt_cancle <= 1'b0;
    vif.tx_valid     <= 1'b0; vif.tx_pid     <= 4'h0; vif.tx_addr      <= 7'h0; vif.tx_endp <= 4'h0;
    vif.ms           <= 1'b0;
    vif.self_addr    <= 7'h08;
    vif.time_threshold<=16'd200;
    vif.delay_threshole<=6'd10;

    // 运行若干次 transaction
    repeat (n_iters) begin
      usb_transaction tr = new();
      assert(tr.randomize());
      tr.build_expected_packets();
      exp_mbox.put(tr);
      cov.sample(tr);
      drv.drive(tr);
      repeat (50) @(posedge vif.clk);
    end
  endtask

endclass


//============================= TB ============================
module usb_link_tb;

  // clock/reset
  logic clk = 0;
  logic rst_n = 0;

  // Interface
  usb_if uif(clk, rst_n);

  // Clock
  initial forever #10 clk = ~clk; // 50MHz

  // Reset
  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  // ---------------- DUT Instance ----------------
  usb_link dut (
    .clk             (clk),
    .rst_n           (rst_n),
    .self_addr       (uif.self_addr),
    .crc5_err        (uif.crc5_err),
    .crc16_err       (uif.crc16_err),
    .ms              (uif.ms),
    .time_threshold  (uif.time_threshold),
    .delay_threshole (uif.delay_threshole),
    .time_out        (uif.time_out),
    .d_oe            (uif.d_oe),
    .rx_lp_sop       (uif.rx_lp_sop),
    .rx_lp_eop       (uif.rx_lp_eop),
    .rx_lp_valid     (uif.rx_lp_valid),
    .rx_lp_ready     (uif.rx_lp_ready),
    .rx_lp_data      (uif.rx_lp_data),
    .tx_lp_sop       (uif.tx_lp_sop),
    .tx_lp_eop       (uif.tx_lp_eop),
    .tx_lp_valid     (uif.tx_lp_valid),
    .tx_lp_ready     (uif.tx_lp_ready),
    .tx_lp_data      (uif.tx_lp_data),
    .tx_lp_cancle    (uif.tx_lp_cancle),
    .rx_pid_en       (uif.rx_pid_en),
    .rx_pid          (uif.rx_pid),
    .rx_endp         (uif.rx_endp),
    .rx_lt_sop       (uif.rx_lt_sop),
    .rx_lt_eop       (uif.rx_lt_eop),
    .rx_lt_valid     (uif.rx_lt_valid),
    .rx_lt_ready     (uif.rx_lt_ready),
    .rx_lt_data      (uif.rx_lt_data),
    .tx_pid          (uif.tx_pid),
    .tx_addr         (uif.tx_addr),
    .tx_endp         (uif.tx_endp),
    .tx_valid        (uif.tx_valid),
    .tx_ready        (uif.tx_ready),
    .tx_lt_sop       (uif.tx_lt_sop),
    .tx_lt_eop       (uif.tx_lt_eop),
    .tx_lt_valid     (uif.tx_lt_valid),
    .tx_lt_ready     (uif.tx_lt_ready),
    .tx_lt_data      (uif.tx_lt_data),
    .tx_lt_cancle    (uif.tx_lt_cancle)
  );

  // ---------------- Coverage Dump ----------------
  initial begin
    // 打开覆盖率统计（可选，默认也是开启的）
    $set_coverage_db_name("usb_cov.vdb");  // 指定数据库文件名
  end


  // ---------------- Run Env ----------------
  initial begin
    usb_env env;
    // defaults
    uif.rx_lp_sop = 0; uif.rx_lp_eop=0; uif.rx_lp_valid=0; uif.rx_lp_data=0;
    uif.tx_lp_ready=0; uif.rx_lt_ready=1;
    uif.tx_pid=0; uif.tx_addr=0; uif.tx_endp=0; uif.tx_valid=0;
    uif.tx_lt_sop=0; uif.tx_lt_eop=0; uif.tx_lt_valid=0; uif.tx_lt_data=0; uif.tx_lt_cancle=0;
    uif.ms=0; uif.self_addr=7'h08; uif.time_threshold=16'd200; uif.delay_threshole=6'd10;

    @(posedge rst_n);
    env = new(uif);
    env.run(40);
    $display("Simulation finished.");
    #200; $finish;
  end

`ifdef FSDB
  initial begin
    $fsdbDumpfile("tb_usb_link.fsdb");
    $fsdbDumpvars(0, usb_link_tb);
  end
`endif

endmodule
