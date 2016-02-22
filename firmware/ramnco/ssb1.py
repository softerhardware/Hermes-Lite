

import numpy as np
from Spectrum import Spectrum
from scipy import signal




depth = 2**20
fs = 73.728e6
dt = 1.0/fs


def genWave(l,depth=depth):

  x = np.linspace(0,2*np.pi,depth,False)
  y = 0
  for n,sf,p in l: y += sf * np.cos(x*n+p)
  y = y/np.max(np.abs(y))

  return y


def oldnco(phase,wavetable,samples=depth):
  depth = len(wavetable)
  addrw = int(np.log2(depth))

  print depth,addrw

  qp = addrw/4

  addrmask = (2**addrw)-1
  phasemax = 2**(32-addrw)

  res = np.zeros(samples,np.complex)
  phase_acc = 0

  for i in range(samples):

    addr = float(phase_acc) / phasemax
    ## Round
    addr = int(np.round(addr))
    addr = addr & addrmask 
 
    res[i] = wavetable[addr] + (1j * wavetable[(addr + qp) & addrmask]) 

    phase_acc = 0xffffffff & np.int(np.round(phase_acc + phase))


  return res


def nco(l,phase,samples=depth):
  x = np.linspace(0,(depth*phase/2**32)*2*np.pi,depth,False)
  yreal = 0
  yimag = 0

  for n,sf,p in l: 
    yreal += sf * np.cos(x*n+p)
    yimag += sf * np.cos(x*n+p+(np.pi/2))

  ymax = max(np.max(np.abs(yreal)),np.max(np.abs(yimag)))

  yreal = yreal/ymax
  yimag = yimag/ymax

  return yreal + (-1j * yimag)


def pure(phase,samples=depth):
  x = np.linspace(0,(depth*phase/2**32)*2*np.pi,depth,False)
  return np.exp(1j*x)


def hz2phase(hz):
  return (hz/fs)*2**32


def nonlinearDistort(daca,c0=0,c1=1.0,c2=0,c3=0,c4=0,c5=0):
	y = daca/np.max(np.abs(daca))
	res = c0 + c1*y + c2*y**2 + c3*y**3 + c4*y**4 + c5*y**5
	return res




 
## Create wavetable
#l = [(1,1.0,0)]
#purewt = genWave(l,depth)

#
#distwt = genWave(l,depth)

print "Done with genWave"

#wave1 = nco(hz2phase(72010),purewt)
wave1 = pure(hz2phase(72010))
#wave1 = signal.hilbert(wave1.real)

wave2 = pure(hz2phase(200223))

wave = wave1 + wave2

wave = wave2


sfm = 57
#sfm = value
#phm = 55
phm = 300
#phm = value
#sf = 0.0109841886379
sf = 0.00015 * sfm
#l12 = [(1,1.0,0),(5,sf,phm*np.pi/30.0)]



#l = [(1,1.0,0),(3,sf,(float(phm)/10)*np.pi/30.0)]
l = [(1,1.0,0),(2,sf,(float(phm)/10)*np.pi/30.0)]

#l = [(1,1.0,0)]
carrier = nco(l,hz2phase(3800000))
#carrier = pure(hz2phase(3800000))

f = wave * carrier
#f = carrier

## Distortion by DAC
#daca = nonlinearDistort(f.real,c2=0.0045,c3=0.035)
#daca = nonlinearDistort(f.real,c3=0.035)
daca = f.real

s = Spectrum(daca,dt,window=np.hanning) # signal.flattop)
peaks = s.findPeaks(order=4,clipdb=95)
s.printPeaks(peaks)
s.plot()



#awave1 = scipy.signal.hilbert(wave1)