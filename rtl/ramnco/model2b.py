

import numpy as np
from Spectrum import Spectrum
from scipy import signal



## Test Code
def genWave(l,width,depth):

  x = np.linspace(0,2*np.pi,depth,False)
  y = 0
  for n,sf,p in l: y += sf * np.cos(x*n+p)
  y = y/np.max(np.abs(y))

  # Maximum value in twos complement
  maxv = (2**(width-1)) - 1
  y = y * maxv

  print("MaxMin",np.max(y),np.min(y),y[1],y[-1])

  #y = y.round()

  print "Maxv is",maxv

  # Interpolation data before any rounding
  maxdelta = 0
  interpolationdata = []
  for i in range(0,depth):

    v = y[i]
    nv = y[i+1] if i < depth-1 else y[0]

    delta = nv-v
    sign = 1 if delta < 0 else 0

    delta = np.abs(delta)

    ## convert to nearest shift
    if delta != 0: delta = 2**int(np.round(np.log2(delta)))

    if delta > maxdelta: maxdelta = delta
    
    interpolationdata.append( (sign,delta) )

    #print deltap,deltan,avgdelta

  print "Max delta is",maxdelta

  ##return np.cos(x)
  return interpolationdata,y.round()


## HLM
def nco(phase,wavetable,interpd=None,width=12,finalwidth=12,samples=16384):
  depth = len(wavetable)

  dmm = 2**(width-1)
  addrw = int(np.log2(depth))
  addrmask = (2**addrw)-1
  phasemax = 2**(32-addrw)
  phasemask = phasemax-1
  maxdelta = 0
  finalwidthdivisor = 2**(width-finalwidth)


  cosa = np.zeros(samples)
  phase_acc = 0
  maxdelta = 0
  for i in range(samples):

    
    addr = (phase_acc >> (32-addrw))
    ## Round
    #addr = addr + (0x01 & (phase_acc >> (32-(addrw+1))))
    #print (0x01 & (phase_acc >> (32-(addrw-1))))
    addr = addr & addrmask 
    #print "addr",addr
    
    y = wavetable[addr]

    ## Interpolate
    if interpd:

      frac = float((phase_acc & phasemask)) / phasemax
      sign,delta = interpd[addr]

      if sign > 0: frac = -1 * frac

      delta = delta * frac

      delta = np.round(delta)

      if np.abs(delta) > maxdelta: maxdelta = np.abs(delta)

      y = y + delta

      y = np.round(y)

    if finalwidth < width:
      cosa[i] = np.round(y/finalwidthdivisor)
    else:
      cosa[i] = y
    phase_acc = 0xffffffff & (phase_acc + phase)

  print "Max delta is",maxdelta

  return cosa




l = [(1,1.0,0)]

sfm = 57
#sfm = value
#phm = 55
phm = 16
#phm = value
#sf = 0.0109841886379
sf = 0.00015 * sfm
#l12 = [(1,1.0,0),(5,sf,phm*np.pi/30.0)]

#l = [(1,1.0,0),(3,sf,phm*np.pi/30.0)]

width = 15
depth = 4096
interpd,wavetable = genWave(l,width,depth)

p1 = 0x01000000
p2 = 0x12345678
p3 = 0x5670e38e
p4 = 0x18a9c71c

npa = nco(p4,wavetable,interpd,width=width,finalwidth=12,samples=16384)

dt = 1.0/73.728e6
s = Spectrum(npa,dt,window=signal.flattop)
peaks = s.findPeaks(order=4,clipdb=90)
s.printPeaks(peaks)
s.plot()
