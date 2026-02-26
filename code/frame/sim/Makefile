SRC_PATH=../src
TESTBENCH_NAME=Ethernet_frame_gen_tb

all: simulate

sv_compile:
	xvlog -sv $(SRC_PATH)/*

elaborate: sv_compile
	xelab -debug typical -top $(TESTBENCH_NAME) -snapshot $(TESTBENCH_NAME)_snapshot

simulate: elaborate
	xsim $(TESTBENCH_NAME)_snapshot -R 

simulate_dump: elaborate
	xsim $(TESTBENCH_NAME)_snapshot -tclbatch Makefile_cfg_xsim.tcl
	xsim --gui $(TESTBENCH_NAME)_snapshot.wdb

clean:
	find . -type f ! -name 'Makefile*' -execdir rm {} +
	rm -rf xsim.dir
