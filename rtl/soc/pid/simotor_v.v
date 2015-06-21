//-----------------------------------------------------
// Design Name : simotor.v
// File Name : simotor.v
// Function : Simulates motor with encoder.
// Input:  500kHz
// Output: A,B encoder
//-----------------------------------------------------
module simotor_v (
  CLOCK, //  fast clock (50 MHz) to scan the PWM
  F,     //  pwm forward input
  R,     //  pwm reverse input
  A,     //  encoder output A
  B,     //  encoder output B
); // End of port list
  //-------------Input Ports-----------------------------
  input CLOCK;
  input	F;
  input	R;
  //-------------Output Ports----------------------------
  output A;
  output B;
  //-------------Input ports Data Type-------------------
  // By rule all the input ports should be wires
  wire CLOCK;
  wire F;
  wire R;
  wire A;
  wire B;
  //-------------Output Ports Data Type------------------
  // Output port can be a storage element (reg) or a wire
  reg [1:0] encoder;         // encoder output patter

  reg signed [31:0] speed;
  reg [31:0] aspeed; // absolute speed
  reg [31:0] counter;   // main motor position counter

/*
** slow motor, visible acceleration
   parameter [31:0] motor_power = 4;
   parameter [4:0]  motor_speed = 21;
   parameter [31:0] motor_friction = 1;
   pid parameters
   KP=17;
   KI=17;
   KD=8;

** fast motor,
   PID parameters from real motor approx working
   parameter [31:0] motor_power = 64*8;  // acceleration
   parameter [4:0]  motor_speed = 19-3;  // inverse log2 friction proportional to speed
   // larger motor_speed values allow higher motor top speed
   parameter [31:0] motor_friction = 8*8; // static friction
   pid parameters
   KP=11;
   KI=15;
   KD=5;
*/
  
  parameter [9:0] motor_power = 512;  // acceleration
  parameter [4:0] motor_speed = 16;  // inverse log2 friction proportional to speed
  // larger motor_speed values allow higher motor top speed
  parameter [7:0] motor_friction = 60; // static friction
  // when motor_power > motor_friction it starts to move

  wire [31:0] applied_power;
  assign applied_power = F == 1 && R == 0 ?  motor_power :
                         F == 0 && R == 1 ? -motor_power : 0;

  //------------Code Starts Here-------------------------
  // We trigger the below block with respect to positive
  // edge of the CLOCK.
  always @ (posedge CLOCK)
  begin : MOTOR_SIMULATOR // Block Name

    // motor voltage 
    speed = speed + applied_power;
 
    // absolute speed
    aspeed = speed > 0 ? speed : -speed;
   
    // friction: proportional to speed,
    // decreases absolute speed
    // also has a constant component
    // for static friction
    aspeed = aspeed > motor_friction ? aspeed - (aspeed >> motor_speed) - motor_friction : 0;

    // handle speed +/- sign
    speed = speed > 0 ? aspeed : -aspeed;
    // add speed to the counter
    counter = counter + speed;

    // generate encoder value
    case(counter[31:30])
      2'b00: encoder = 2'b01;
      2'b01: encoder = 2'b11;
      2'b10: encoder = 2'b10;
      2'b11: encoder = 2'b00;
    endcase
  end // End of Block CLOCK_DIVIDER

  assign A = encoder[0];
  assign B = encoder[1];
endmodule // End of Module MOTOR_SIMULATOR