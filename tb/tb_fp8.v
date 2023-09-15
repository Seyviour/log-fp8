
module adderFP8_tb;

int fd; 

initial begin
    fd = $fopen("tb/result.txt", "w");

    if (fd) 
        $display("`results.txt` opened for writing"); 
    else
        $display("Failed to open `results.txt` for writing"); 
end

initial begin
    $dumpfile("fp8.vcd");
    $dumpvars(0, adderFP8_tb); 
end

// Parameters
localparam  FP8_TYPE = 0;

//Ports
reg clk; 
reg  [7:0] A;
reg  [7:0]  B;
wire [7:0] C;

adderFP8 # (
  .FP8_TYPE(FP8_TYPE)
)
adderFP8_inst (
  .A(A),
  .B(B),
  .C(C)
);

initial begin
    A = 0;
    B = 0;
    clk = 0;
end

always #5  clk = !clk ;


always @(posedge clk) begin
    if (A == 8'b1111_1111 && B == 8'b1111_1111) begin
        $fclose(fd); 
        $finish; 
    end 
    #2; 
    A <= A + 1'b1;
    if (A == 8'b1111_1111)
        B <= B + 1'b1; 
end

always @(posedge clk) begin
    #1; 
    $fdisplay(fd, "%b %b %b", A, B, C);
end






endmodule