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

## (C) Steve Haynal KF7O 2014


from myhdl import *
 
from ad9866 import ad9866_spi, ad9866_pgm, ad9866



def testbench():

  reset = ResetSignal(0, active=1, async=True)
  clk = Signal(bool(0))
  sclk = Signal(bool(0))
  sdio = Signal(bool(0))
  sdo = Signal(bool(0))
  sen_n = Signal(bool(1))
  dataout = Signal(intbv(0)[8:])
  extrqst = Signal(bool(0))
  extdata = Signal(intbv(0)[16:])

  dut = ad9866(reset,clk,sclk,sdio,sdo,sen_n,dataout,extrqst,extdata)
  #dut1 = ad9866_spi(reset,clk,sclk,sdio,sdo,sen_n,start,datain,dataout)
  #dut2 = ad9866_pgm(reset,clk,sen_n,start,datain)

  @always(delay(10))
  def clkgen():
    clk.next = not clk

  @instance
  def stimulus():
    datain.next = 0
    start.next = 0
    sdo.next = 1

    for i in range(3):
      yield clk.negedge

    datain.next = int('0110000001011001',2)
    start.next = 1
    yield clk.negedge
    datain.next = 0
    start.next = 0

    for i in range(98):
      yield clk.negedge

    raise StopSimulation

  @instance
  def stimulus2():
    for i in range(140):
      yield clk.negedge

    extrqst.next = 1
    extdata.next = 0b0110000001011001

    for i in range(240):
      yield clk.negedge

    raise StopSimulation


  return dut, clkgen, stimulus2


tb_fsm = traceSignals(testbench)
sim = Simulation(tb_fsm)
sim.run()

