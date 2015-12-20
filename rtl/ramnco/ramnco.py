##
##  Hermes Lite
## 
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

## (C) Steve Haynal KF7O 2015

import numpy as np
import sys
from myhdl import *



class RAMNCO_INTERFACE:
  def __init__(self,i):
    self.run = Signal(bool(0))
    self.phase = Signal(modbv(0)[i.accwidth:])
    self.cos = Signal(intbv(0,min=-i.dmm,max=i.dmm))
    self.sin = Signal(intbv(0,min=-i.dmm,max=i.dmm))
    self.din = Signal(intbv(0,min=-i.dmm,max=i.dmm))
    self.addr = Signal(modbv(0)[i.addrw:])
    self.we = Signal(bool(0))



class RAMNCO:

  def __init__(self,width=12,depth=2048,accwidth=32):
    self.width = width
    self.depth = depth
    self.accwidth = accwidth
    self.dmm = 2**(width-1)
    self.addrw = int(np.log2(self.depth))


  def ramnco(self,clk,intf):
    """ RTL """

    st = enum('COS', 'SIN')

    wavetable = [Signal(intbv(0,min=-self.dmm,max=self.dmm)) for i in range(self.depth)]
    phase_acc = Signal(modbv(0)[self.accwidth+1:])

    raddr = Signal(modbv(0)[self.addrw:])
    rdata = Signal(intbv(0,min=-self.dmm,max=self.dmm))

    lfsr = Signal(modbv(1)[20:])
    state = Signal(st.COS)

    @always(clk.posedge)
    def write():
      if intf.we: wavetable[intf.addr].next = intf.din

    @always_comb
    def read():
      rdata.next = wavetable[raddr] 

    @always(clk.posedge)
    def FSM():
      if state == st.COS:
        ## Read cosine
        intf.cos.next = rdata
        
        ## Compute raddr for sine
        raddr.next = raddr + int(self.depth/4)

        ## Add phase word
        phase_acc.next = phase_acc + concat(False,intf.phase)

        if intf.run: state.next = st.SIN

      elif state == st.SIN:
        ## Read sine
        intf.sin.next = rdata

        ## Compute raddr for cosine
        raddr.next = phase_acc[self.accwidth:self.accwidth-self.addrw] #+ lfsr[0]

        lfsr.next = concat(lfsr[0],lfsr[19]^lfsr[0],lfsr[18],lfsr[17],lfsr[16]^lfsr[0],lfsr[15],lfsr[14]^lfsr[0],lfsr[14:1])
        #if phase_acc[self.accwidth]:
          ## Always increment lfsr on overflow
        #  lfsr.next = concat(lfsr[0],lfsr[19]^lfsr[0],lfsr[18],lfsr[17],lfsr[16]^lfsr[0],lfsr[15],lfsr[14]^lfsr[0],lfsr[14:1])
          ## Add dither
        #  if lfsr[0]:
        #    phase_acc.next[self.accwidth+1:self.accwidth-self.addrw] = phase_acc[self.accwidth+1:self.accwidth-self.addrw] + 1
        
        state.next = st.COS

    return write,read,FSM


  ## Generation Code
  def toVerilog(self):
    clk = Signal(bool(0))
    i = RAMNCO_INTERFACE(self)
    toVerilog(self.ramnco,clk,i)


  ## Test Code
  def genWave(self,l):

    x = np.linspace(0,2*np.pi,self.depth+1)
    x = x[:self.depth]
    y = 0
    for n,sf,p in l:
      y += sf * np.cos(x*n+p)

    norm = np.max(np.abs(y))
    y = y/norm

    ## Maximum positive value in twos complement
    maxv = self.dmm-1

    y = y * maxv

    print("MaxMin",np.max(y),np.min(y),y[1],y[-1])

    return y.round()



  def testbench(self):
    clk = Signal(bool(0))
    intf = RAMNCO_INTERFACE(self)

    dut = self.ramnco(clk,intf)

    @always(delay(10))
    def clkgen():
      clk.next = not clk

    @instance
    def check():
      intf.we.next = 0
      intf.phase.next = 0x5670e38e
      intf.run.next = 0
      intf.din.next = 0
      intf.addr.next = 0

      for i in range(3):
        yield clk.negedge

      ## Load Cosine
      l = [(1,1.0,0)]
      wave = self.genWave(l)
      for waddr,v in enumerate(wave):
        intf.we.next = 1
        intf.din.next = int(v)
        intf.addr.next = waddr
        yield clk.negedge

      intf.we.next = 0
      intf.run.next = 1
      yield clk.negedge

      cosa = np.zeros(4096)
      sina = np.zeros(4096)

      for i in range(4096):
        cosa[i] = intf.cos
        yield clk.negedge
        sina[i] = intf.sin
        yield clk.negedge

      np.save("cosa",cosa)
      np.save("sina",sina)

      raise StopSimulation

    return dut, clkgen, check

  def runTest(self,tb):
    #tb_fsm = traceSignals(tb)
    #sim = Simulation(tb_fsm)
    sim = Simulation(tb())
    sim.run()





if __name__ == '__main__':
  if sys.argv[1] == 'convert':
    r = RAMNCO()
    r.toVerilog()
  elif sys.argv[1] == 'test':
    r = RAMNCO(depth=2**13)
    r.runTest(r.testbench)
  else:
    print("Unrecognized option")

