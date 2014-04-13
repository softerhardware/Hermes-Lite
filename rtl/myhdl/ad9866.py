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


ts = enum('START', 'SEND')

def ad9866_spi(reset,clk,sclk,sdio,sdo,sen_n,start,datain,dataout):
  """ Simple SPI master interface for AD9866 """

  data = Signal(intbv(0)[16:])
  state = Signal(ts.START)
  bitcount = Signal(modbv(0)[4:])

  @always_comb
  def COMB():
    dataout.next = data[8:]
    sdio.next = data[15]

  @always_seq(clk.posedge,reset=reset)
  def FSM():

    if state == ts.START:

      sclk.next = 0
      bitcount.next = 15
      if start:
        ## latch data
        data.next = datain
        sen_n.next = 0
        state.next = ts.SEND
      else:
        sen_n.next = 1

    elif state == ts.SEND:

      if not sclk:
        sclk.next = 1
      else:
        ## Read input on falling edge of sclk
        data.next = concat(data[15:0],sdo)
        bitcount.next = bitcount - 1
        sclk.next = 0
        if bitcount == 0: state.next = ts.START

  return instances()


def ad9866_pgm(reset,clk,sen_n,start,datain,extrqst,extdata):
  """ Send commpands to the AD9866 """

  pc = Signal(intbv(0)[4:])
  ##state = Signal(intbv(0)[1:])

  ## Mealy outputs
  @always_comb
  def COMB():
    ## Setup 4 wire SPI
    if pc == 1 and sen_n:
      start.next = 1
      datain.next = 0x0080
    ## TX Twos complement and interpolation factor
    elif pc == 3 and sen_n:
      start.next = 1
      datain.next = 0x0c41
    elif pc == 5 and sen_n:
      start.next = 1
      #datain.next = 0x094c
      #datain.next = 0x0b20
      ## Clear TX DAC Output
      datain.next = 0x0e00
      ## Set IAMP
      ##datain.next = 0x1084
    ## Twos complement by default when Mode is 1
    ## Set RX to use twos complement
    elif pc == 7 and sen_n:
      start.next = 1
      datain.next = 0x0d01
    
    ## Enable RX Filter and initiate offset calibration
    elif pc == 9 and sen_n:
      start.next = 1
      datain.next = 0x0721
    ##
    ## RX Filter f-3db at ~32MHz
    elif pc == 0x0b and sen_n:
      start.next = 1
      datain.next = 0x0861
   
    elif pc == 0x0e and sen_n and extrqst:
      start.next = 1
      datain.next = extdata

    else:
      start.next = 0
      datain.next = 0



  @always_seq(clk.posedge,reset=reset)
  def FSM():

    if pc == 0x0f:
      pc.next = 0x0e
    elif sen_n:
      pc.next = pc + 1



  return instances()





def ad9866(reset,clk,sclk,sdio,sdo,sen_n,dataout,extrqst,extdata):
  datain = Signal(intbv(0)[16:])
  start = Signal(bool(0))

  dut1 = ad9866_pgm(reset,clk,sen_n,start,datain,extrqst,extdata)
  dut2 = ad9866_spi(reset,clk,sclk,sdio,sdo,sen_n,start,datain,dataout)
  return instances()



