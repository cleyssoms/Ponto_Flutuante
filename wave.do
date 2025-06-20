onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fpu_tb/clk
add wave -noupdate /fpu_tb/rst_n
add wave -noupdate /fpu_tb/Op_A_in
add wave -noupdate /fpu_tb/Op_B_in
add wave -noupdate /fpu_tb/data_out
add wave -noupdate /fpu_tb/status_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 140
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1 ns}