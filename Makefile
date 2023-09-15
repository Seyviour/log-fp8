sim: rtl/fp8_adder2.v tb/tb_fp8.v
	iverilog -g 2012 rtl/fp8_adder.v tb/tb_fp8.v -o temp.sim.out
	vvp temp.sim.out
	python tb/analyse_result.py
	rm temp.sim.out
