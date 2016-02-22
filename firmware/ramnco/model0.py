

import numpy as np
import sys
from scipy import signal
from Spectrum import Spectrum

## Test Code
def genWave(l,depth,dmm):

  x = np.linspace(0,2*np.pi,depth,False)
  y = 0
  for n,sf,p in l:
    y += sf * np.cos(x*n+p)

  norm = np.max(np.abs(y))
  y = y/norm

  ## Maximum positive value in twos complement
  maxv = dmm-1

  y = y * maxv

  print("MaxMin",np.max(y),np.min(y),y[1],y[-1])

  ##return np.cos(x)
  return y.round()

## HLM
def nco(phase,width=12,depth=8192,samples=16384,finalwidth=12,dodither=None,dointerpolate=None):
  dmm = 2**(width-1)
  addrw = int(np.log2(depth))
  addrmask = (2**addrw)-1
  phasemax = 2**(32-addrw)
  phasemask = phasemax-1
  maxdelta = 0
  finalwidthdivisor = 2**(width-finalwidth)

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

  wavetable = genWave(l,depth,dmm)

  cosa = np.zeros(samples)
  phase_acc = 0
  for i in range(samples):

    if dodither:
      dither = np.random.randint(*dodither) << (32-addrw)
      print dither
    else:
      dither = 0
    addr = ((phase_acc + dither) >> (32-addrw)) & (2**addrw)-1

    ##print "addr",addr
    
    y = wavetable[addr]

    ## Interpolate
    if dointerpolate != None:
      naddr = (addr+1) & addrmask
      ny = wavetable[naddr]
      delta = ny - y
           
      frac = float( (phase_acc & phasemask) >> dointerpolate) / (phasemax >> dointerpolate)
      #print "Interpolate info",delta,frac
      #ditherrange = int(delta/2)
      #if np.abs(delta) > 0:
      #ampdither = np.random.randint(0,2)
      #ampdither = 0
      #else:
      #  ampdither = 0
      #if delta != 0:
      #  print "Interpolated",delta,frac,y,
      fdelta = (frac * delta)
      y = y + fdelta  # + ampdither
      if np.abs(fdelta) > maxdelta: maxdelta = np.abs(fdelta) 
      y = np.round(y)

      #if delta != 0: print y 


    if finalwidth < width:
      cosa[i] = np.round(y/finalwidthdivisor)
    else:
      cosa[i] = y
    phase_acc = 0xffffffff & (phase_acc + phase)

  print "Max Delta is",maxdelta

  return cosa



if __name__ == '__main__':
  dt = 1.0/73.728e6

  p1 = 0x01000000
  p2 = 0x12345678
  p3 = 0x5670e38e
  p4 = 0x18a9c71c

  if sys.argv[1] == 'file':
    npa = np.load(sys.argv[2])
  elif sys.argv[1] == 'hlm':
    npa = nco(p4,width=12,depth=1024,samples=16384,finalwidth=12,dodither=None,dointerpolate=0)
  elif sys.argv[1] == "pure":
    samples = 16384
    phase = 0x2670e38e
    npa = np.zeros(samples)

    pf = float(phase)/float(0xffffffff)

    maxdelta = 0
    ly = 0
    for i in range(samples):
      x = i*2*np.pi*pf
      #x = np.round(x,2)
      #x = x + np.random.randint(-5,6) / 1000.0
      ##print x,phase_dither
      y = np.cos(x)
      delta = np.abs(y - ly)
      if delta > maxdelta: maxdelta = delta
      npa[i] = y
    print "Maxdelta is",maxdelta*2048


    
  s = Spectrum(npa,dt,window=signal.flattop)

  peaks = s.findPeaks(order=4,clipdb=90)
  s.printPeaks(peaks)
  s.plot()

