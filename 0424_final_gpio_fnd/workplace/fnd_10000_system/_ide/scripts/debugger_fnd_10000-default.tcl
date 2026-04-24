# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\system_verilog\0424_final_gpio_fnd\workplace\fnd_10000_system\_ide\scripts\debugger_fnd_10000-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\system_verilog\0424_final_gpio_fnd\workplace\fnd_10000_system\_ide\scripts\debugger_fnd_10000-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183BE0FD1A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183BE0FD1A-0362d093-0"}
fpga -file D:/system_verilog/0424_final_gpio_fnd/workplace/fnd_10000/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw D:/system_verilog/0424_final_gpio_fnd/workplace/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow D:/system_verilog/0424_final_gpio_fnd/workplace/fnd_10000/Debug/fnd_10000.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
