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
 
from ad9866 import ad9866_spi, ad9866


reset = ResetSignal(0, active=1, async=True)
clk = Signal(bool(0))
sclk = Signal(bool(0))
sdio = Signal(bool(0))
sdo = Signal(bool(0))
sen_n = Signal(bool(1))
dataout = Signal(intbv(0)[8:])
extrqst = Signal(bool(0))
extdata = Signal(intbv(0)[16:])

toVerilog(ad9866,reset,clk,sclk,sdio,sdo,sen_n,dataout,extrqst,extdata)
