## start with python -i spectrum_ex1.py

from Spectrum import Spectrum, loadCaptureData
from scipy import signal
import numpy as np


## Load CaptureData object
cd = loadCaptureData("data/sh12_1000")


## Create spectrum object
## Averages is the number of partitions to average
## Normalize scales top output to 0 dB
## Z is the impedance that the scope is measuring voltage across
## Window is the window to apply to fft input data, signal.flattop is best for power
s = Spectrum(cd,averages=24,normalize=False,Z=50.0,window=signal.flattop)

## Create a frequency slice if you want to restrict further operations
## over a particular frequency range, None for no frequency slice
##sl = (0,200)
sl = None

## Find peaks
## clipdb specifies the db value below which to no longer look for peaks
## For example clipdb of 70 will not look for peaks smaller than -70 dbc
peaks = s.findPeaks(sl,clipdb=70)

## Print the peaks
s.printPeaks(peaks)


## Plot the graph
## Include peaks to mark top 10 peaks
s.plot(sl,peaks)

## Exit plot GUI to proceed

## Create a new different spectrum based on the same data
s2 = Spectrum(cd,averages=1,normalize=True,Z=50.0,window=signal.flattop)

## Do as before
peaks2 = s2.findPeaks(sl,clipdb=70)
s2.printPeaks(peaks2)

## Plot but don't include data less than clipdb dbc
s2.plot(sl,peaks2,clipdb=95)


## ctrl-d to exit
