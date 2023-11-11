module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

/* '(' = 40
 * ')' = 41
 * '*' = 42
 * '+' = 43
 * '-' = 45
 * '=' = 61
 */

// Output signal
output valid;
output [6:0] result;

reg    valid, In_Data = 0;
reg    [2:0] CurrentState, NextState;
reg    [4:0] top, pindex, tindex, last;
reg    [5:0] postfix [0:15], temp [0:15];
reg    [6:0] result, stack [0:16];
 
localparam  S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011, S4 = 3'b100;

/* State register */
always @(posedge clk or posedge rst)
begin
	if(rst)
		CurrentState = S0;
	else
		CurrentState = NextState;
end

/* Next state logic */
always @(*)
begin
	case(CurrentState)
		S0: begin /* Initialize the variable */
			if(ready == 1)
				NextState = S1;
			else
				NextState = S0;
		end

		S1: begin /* Read data from ascii_in and store to temp array */
			if(In_Data == 1)
				NextState = S2;
			else
				NextState = S1;
		end

		S2: begin /* Infix to postfix */
			if(In_Data == 1)
				NextState = S3;
			else
				NextState = S2;
		end

		S3: begin /* Calculate the answer */
			if(In_Data == 1)
				NextState = S4;
			else
				NextState = S3;
		end

		S4: begin /* Output the answer */
			if(In_Data == 1)
				NextState = S0;
			else
				NextState = S4;
		end

		default: begin
			NextState = S0;
		end
	endcase
end

always @(negedge clk)
begin
	case(CurrentState)
		S0: begin
			valid = 1'd0;	
			top = 5'd0;
			pindex = 5'd0;
			tindex = 5'd0;
			last = 5'd0;
		end

		S1: begin
			In_Data = 0;

			if(ascii_in != 61) begin
				if(ascii_in >= 48 && ascii_in <= 57) /* 0~9 */
	        		temp[tindex] = ascii_in - 48;
				else if(ascii_in >= 97 && ascii_in <= 102) /* 10~15 */
	        		temp[tindex] = ascii_in - 87;
				else /* '(',')','*','+','-' */
	        		temp[tindex] = ascii_in;
			tindex = tindex + 1;
			last = tindex;
			end
			else begin
				tindex = 0;
				In_Data = 1;
			end
		end

		S2: begin
			In_Data = 0;

			if(tindex < last) begin
				if(temp[tindex] >= 0 && temp[tindex] <= 15) begin /* Append 0~15 to postfix array */
					postfix[pindex] = temp[tindex];
					pindex = pindex + 1;
					tindex = tindex + 1;
				end
				else if(temp[tindex] == 43 || temp[tindex] == 45) begin /* Push '+','-' to stack */
					if(top > 0 && stack[top] >= 42 && stack[top] <= 45) begin
						postfix[pindex] = stack[top];
						top = top - 1;
						pindex = pindex + 1;
					end
					else begin
						top = top + 1;
						stack[top] = temp[tindex];
						tindex = tindex + 1;
					end
				end
				else if(temp[tindex] == 40 || temp[tindex] == 42) begin /* Push '(','*' to stack */
					top = top + 1;
					stack[top] = temp[tindex];
					tindex = tindex + 1;
				end
				else begin /* If the current token is ')' */
					if(stack[top] != 40) begin /* pop operators from the stack and append them to the postfix array until a '('*/
						postfix[pindex] = stack[top];
						top = top - 1;
						pindex = pindex + 1;
					end
					else begin
						top = top - 1;
						tindex = tindex + 1;
					end
				end
				
			end
			else begin /* pop out all the tokens in the stack and append to postfix array */
				if(top > 0) begin
					postfix[pindex] = stack[top];
					top = top - 1;
					pindex = pindex + 1;
				end
				else begin
					last = pindex;
					pindex = 0;
					top = 0;
					In_Data = 1;
				end
			end
		end

		S3: begin
			In_Data = 0;

			if(pindex < last) begin
				if(postfix[pindex] <= 15) begin
					top = top + 1;
					stack[top] = postfix[pindex];
				end
				else begin
					case(postfix[pindex])
						42: begin /* Multiplication */
							top = top - 1;
							stack[top] = stack[top] * stack[top + 1];
						end

						43: begin /* Addition */
							top = top - 1;
							stack[top] = stack[top] + stack[top + 1];
						end

						45: begin /* Subtraction */
							top = top - 1;
							stack[top] = stack[top] - stack[top + 1];
						end
					endcase
				end
				pindex = pindex + 1;
			end
			else
				In_Data = 1;
		end

		S4: begin
			valid = 1;
			In_Data = 1;
			result = stack[1];
		end
	endcase
end 
endmodule