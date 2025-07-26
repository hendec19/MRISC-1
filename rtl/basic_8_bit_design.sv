module MRISC(
	input logic clk, 
	input logic resetn, 
	input logic[7:0] inputBus, 
	output logic [7:0] outputBus
	);

	// opcodes
	typedef enum {
		NOP = 0,
		LDA = 1,
		LDB = 2,
		ADD = 3, // A = A + B
		SUB = 4, // A = A - B
		STA = 5,
		JMP = 6,
		LDAI = 7,
		LDBI = 8,
		MOV = 9
	} opcodes;

	// internal registers
	logic [7:0] PC;
	logic [7:0] MA;
	logic [7:0] RA;
	logic [7:0] RB;
	logic [7:0] IR;
	logic [2:0] IC;

	// main bus, driven by combinational logic
	logic [7:0] mainBus;

	// ========== Execution Unit ==========
	// program counter
	logic PC_en;
	logic PC_out;
	logic JMP_en;
	always_ff @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			PC <= 8'd0;
		end
		else if (JMP_en) begin
			PC <= mainBus;
		end
		else if (PC_en) begin
			PC <= PC + 8'd1;
		end
	end
	
	// ram
	logic [7:0] RAM[255:0];
	logic RAM_in;
	logic RAM_out;
	always_ff @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			// hardcoded program
		end
		else if (RAM_in) begin
			RAM[MA] <= mainBus;
		end
	end

	// memory address register
	logic MA_in;
	always_ff @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			MA <= 0;
		end
		else if (MA_in) begin
			MA <= mainBus;
		end
	end

	// ALU registers
	logic RA_in;
	logic RB_in;
	logic RA_out;
	always_ff @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			RA <= 8'd0;
			RB <= 8'd0;
		end
		else if (RA_in) begin
			RA <= mainBus;
		end
		else if (RB_in) begin
			RB <= mainBus;
		end
	end
	logic ADD_out;
	logic SUB_out;
	
	// ========== Control Unit ==========
	// Instruction Register
	logic IR_in;
	always_ff @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			IR <= 8'd0;
		end
		else if (IR_in) begin
			IR <= mainBus;
		end
	end

	// Instruction Stepper
	logic next;
	always_ff @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			IC <= 3'd0;
		end
		else if (next) begin
			IC <= 3'd0;
		end
		else begin
			IC <= IC + 3'd1;
		end
	end
	
	// Instruction Decoder
	always_comb begin
		PC_en = 1'b0;
		PC_out = 1'b0;
		JMP_en = 1'b0;
		RAM_in = 1'b0;
		RAM_out = 1'b0;
		MA_in = 1'b0;
		RA_in = 1'b0;
		RB_in = 1'b0;
		RA_out = 1'b0;
		ADD_out = 1'b0;
		SUB_out = 1'b0;
		IR_in = 1'b0;
		next = 1'b0;
			
		case(IR)

			// instruction format:
			// step 0: move PC into MA and increment PC after
			// step 1: "dereference" ma into the instruction register
			// step 2-7: actual instruction process

			// why is it done this way?
			// we could easily just make the entire cpu a big FSM and use 1 switch-case statement
			// but that wont work well for more complex designs
			// this way of doing things focuses on driving smaller modules, which is more sustainable than a big FSM

			NOP: begin
				if (IC == 3'd0) begin
					PC_out = 1;
					PC_en = 1;
					MA_in = 1;
				end
				else if (IC == 3'd1) begin
					RAM_out = 1;
					IR_in = 1;
				end
				else if (IC == 3'd2) begin
					next = 1;
				end
			end

			ADD: begin
				if (IC == 3'd0) begin
					PC_out = 1;
					MA_in = 1;
				end
				else if (IC == 3'd1) begin
					RAM_out = 1;
					IR_in = 1;
				end
				else if (IC == 3'd2) begin
					ADD_out = 1;
					next = 1;
				end
			end

		endcase
	end



	// main bus controls, driven by Ctrl Unit
	always_comb begin
		if (RAM_out) begin
			mainBus = RAM[MA];
		end
		if (ADD_out) begin
			mainBus = RA + RB;
		end
		else begin
			mainBus = 8'd0;
		end
	end



endmodule