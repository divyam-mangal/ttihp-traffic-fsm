

`default_nettype none

module tt_um_traffic_light (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (1=output)
    input  wire       ena,      // always 1 when design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  
  wire reset = !rst_n;
  wire sensor = ui_in[0];       // Traffic sensor input
  
  
  localparam S_GREEN  = 2'b00;
  localparam S_YELLOW = 2'b01;
  localparam S_RED    = 2'b10;
  
  
  localparam GREEN_TIME  = 4'd10;
  localparam YELLOW_TIME = 4'd3;
  localparam RED_TIME    = 4'd10;
  

  reg [1:0] state, next_state;
  reg [3:0] timer;
  

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= S_RED;
      timer <= RED_TIME;
    end else begin
      state <= next_state;
      if (state != next_state) begin
        // Reset timer on state change
        case (next_state)
          S_GREEN:  timer <= GREEN_TIME;
          S_YELLOW: timer <= YELLOW_TIME;
          S_RED:    timer <= RED_TIME;
          default:  timer <= RED_TIME;
        endcase
      end else if (timer > 0) begin
        timer <= timer - 1;
      end
    end
  end
  
  
  always @(*) begin
    next_state = state;
    case (state)
      S_GREEN: begin
        if (timer == 0)
          next_state = S_YELLOW;
      end
      S_YELLOW: begin
        if (timer == 0)
          next_state = S_RED;
      end
      S_RED: begin
        if (timer == 0 && sensor)
          next_state = S_GREEN;
        else if (timer == 0)
          next_state = S_GREEN;  // Auto-cycle if no sensor
      end
      default: next_state = S_RED;
    endcase
  end
  

  reg [7:0] light_out;
  
  always @(*) begin
    case (state)
      S_GREEN:  light_out = 8'b00_100_001;  // Main=Green, Side=Red
      S_YELLOW: light_out = 8'b00_100_010;  // Main=Yellow, Side=Red
      S_RED:    light_out = 8'b00_001_100;  // Main=Red, Side=Green
      default:  light_out = 8'b00_100_100;  // Both Red (safe state)
    endcase
  end
  
  assign uo_out = light_out;
  
  
  assign uio_out = {4'b0, timer};
  assign uio_oe  = 8'b00001111;  // Lower 4 bits as outputs
  

  wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
