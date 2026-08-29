node Toolchain/sbin.js Machines/Mch1/test.asm Machines/Mch1/test.hex
iverilog -o Machines/Mch1/cpu_sim Machines/Mch1/tb.v cpu.v
cd Machines/Mch1/
vvp cpu_sim
cd ../../