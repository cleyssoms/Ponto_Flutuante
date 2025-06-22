if {[file isdirectory work]} {vdel -all -lib work}
vlib work
vmap work work
vlog Floating.sv
vlog Floating_tb.sv
vsim work.Floating_tb
quietly set StdArithNoWarnings 1
quietly set StdVitalGlitchNoWarnings 1
do wave.do
run 2ms