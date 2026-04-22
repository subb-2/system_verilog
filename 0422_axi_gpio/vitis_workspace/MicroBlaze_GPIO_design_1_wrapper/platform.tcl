# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\system_verilog\0422_axi_gpio\vitis_workspace\MicroBlaze_GPIO_design_1_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\system_verilog\0422_axi_gpio\vitis_workspace\MicroBlaze_GPIO_design_1_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {MicroBlaze_GPIO_design_1_wrapper}\
-hw {D:\system_verilog\0422_axi_gpio\XSA\MicroBlaze_GPIO_design_1_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {D:/system_verilog/0422_axi_gpio/vitis_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {MicroBlaze_GPIO_design_1_wrapper}
platform generate -quick
platform generate
