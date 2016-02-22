
import numpy as np
import matplotlib as mpl
mpl.use('Qt4Agg',warn=False)
##mpl.rcParams['agg.path.chunksize'] = 1000000
import matplotlib.pyplot as plt
import pyfftw, sys

from scipy import signal

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

  ly = 0
  for iy in y:
    edelta = np.abs(iy-ly)
    ry = np.round(iy)
    rly = np.round(ly)
    delta = np.abs(ry-rly)
    print iy,ly,edelta,ry,rly,delta
    ly = iy

  ##return np.cos(x)
  return y.round()

l = [(1,1.0,0)]

depth = 512
width = 12
dmm = 2**(width-1)

genWave(l,depth,dmm)