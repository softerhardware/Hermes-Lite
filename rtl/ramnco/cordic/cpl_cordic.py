import os

from myhdl import Cosimulation

cmd = "iverilog -o cpl_cordic.o " + \
      "cpl_cordic.v " + \
      "dut_cpl_cordic.v "
      
def cpl_cordic(clk, phase, cos):
    os.system(cmd)
    return Cosimulation("vvp -m ./myhdl.vpi cpl_cordic.o", **locals())
               
