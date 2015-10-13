

from CaptureData import *

import numpy as np
import matplotlib as mpl
mpl.use('Qt4Agg',warn=False)
##mpl.rcParams['agg.path.chunksize'] = 1000000
import matplotlib.pyplot as plt
import pyfftw, sys

from scipy import signal


def loadCaptureData(fn):
    cd = load(fn)
    cduia = np.frombuffer(cd.data,np.uint8)
    maxv = cduia.max()
    minv = cduia.min()
    center = cd.yincrement() * float(maxv+minv)/2.0
    cdfa = (cduia * cd.yincrement()) - center
    return (cd.xincrement(),cdfa)


class Spectrum:

    def __init__(self,(xincr,cdfa),averages=1,normalize=False,Z=50.0,window=None,other=None):

        if other:
            self.sa = np.copy(other.sa)
            self.mhz2bin = other.mhz2bin
            self.bin2mhz = other.bin2mhz
            self.carrier = other.carrier
            return

        n = len(cdfa)//averages
        if (n%2 == 1): n -= 1

        print "FFT Size is",n

        self.sa = None

        fftia = pyfftw.n_byte_align_empty(n, 16, 'float32')
        fftoa = pyfftw.n_byte_align_empty(n/2 + 1, 16, 'complex64')
        fft = pyfftw.FFTW(fftia,fftoa,flags=('FFTW_ESTIMATE',),planning_timelimit=60.0)

        if window: w = window(n)

        for i in range(0,averages):
            if window:
                fftia[:] = w * cdfa[i*n:(i+1)*n]
            else:
                fftia[:] = cdfa[i*n:(i+1)*n]

            fft()

            if self.sa != None:
                self.sa = self.sa + np.abs(fftoa)
            else:
                self.sa = np.abs(fftoa)

        if averages > 1: 
            print "Averaging"
            self.sa = self.sa / averages

        ## Scale amplitude for window
        if window:
            scale = 1.0/np.sum(window(10000)/10000.0)
            print "Scaling postwindow by",scale
            self.sa = scale * self.sa

        ## 2.0 To get magnitude in terms of original V since half of spectrum is returned
        ## Result is vrms
        print "Converting to dBm"
        self.sa = (np.sqrt(2.0)/n) * self.sa
        ## convert to W assumiming Z load
        self.sa = (np.square(self.sa)/Z)
        ## convert to dBm
        self.sa = (10.0*np.log10(self.sa)) + 30.0 

        self.mhz2bin = len(self.sa) * 1e6 * 2 * xincr
        self.bin2mhz = 1.0/self.mhz2bin

        self.carrier = self.sa.max(),self.sa.argmax() * self.bin2mhz
        print "Carrier power is",self.carrier[0],"dBm at",self.carrier[1],"MHz."

        if normalize:
            self.sa -= self.carrier[0]
            print "Normalized"

        print "Spectrum Array length is",len(self.sa)

    def subtract(self,other):
        origmaxv = self.sa.max()
        self.sa -= other.sa
        maxv = self.sa.max()
        self.sa += (origmaxv-maxv)

    def isolate(self,freqs,order=1,forcedb=95):

        copy = Spectrum( (None,None), other=self)
        copy.sa.fill(-forcedb)

        for freq in freqs:
            centerbin = int(freq*self.mhz2bin)
            for b in range(centerbin-order,centerbin+order+1):
            	if self.sa[b] > -forcedb:
                	copy.sa[b] = self.sa[b]

        return copy
    
    def eliminate(self,freqs,order=1,forcedb=95):

        copy = Spectrum( (None,None), other=self)

        for freq in freqs:
            centerbin = int(freq*self.mhz2bin)
            for b in range(centerbin-order,centerbin+order+1):
                copy.sa[b] = -forcedb

        return copy


    def printPeaks(self,peaks,maxtoprint=100):

        if len(peaks) > maxtoprint:
            print "Too many peaks to print"
            return
        else:
            print "Found {0} peaks".format(len(peaks))

        for (db,mhz) in peaks:
            print "{0:10.6f} MHz  {1:7.2f} dB".format(mhz,db)

    def findPeaks(self,sl=None,order=2,clipdb=None):

        if sl:
            startbin = int(sl[0]*self.mhz2bin)
            stopbin = int(sl[1]*self.mhz2bin)
            sa = self.sa[startbin:stopbin]
        else:
            sa = self.sa

        if clipdb: 
            normcarrier = self.sa.max()
            sa = np.clip(sa,normcarrier-clipdb,normcarrier+1)

        res = signal.argrelmax(sa,order=order)[0]

        peaks = []
        for i in res:
            peaks.append( (self.sa[i],i*self.bin2mhz) )

        return peaks


    def plot(self,sl=None,peaks=[],clipdb=None):

        if sl:
            startbin = int(sl[0]*self.mhz2bin)
            stopbin = int(sl[1]*self.mhz2bin)
            sa = self.sa[startbin:stopbin]
        else:
            sa = self.sa

        if clipdb: 
            normcarrier = self.sa.max()
            sa = np.clip(sa,normcarrier-clipdb,normcarrier+1)
            print "normcarrier",normcarrier,clipdb

        n = len(sa)

        title = "Spectrum for {0:.1f}dBm Carrier at {1:.3f}MHz".format(*self.carrier)
        fig = plt.figure()
        fig.subplots_adjust(bottom=0.2)
        fig.suptitle(title, fontsize=20)
        sp = fig.add_subplot(111)

        xaxis = np.r_[0:n] * self.bin2mhz
        if sl: xaxis = xaxis + (startbin * self.bin2mhz)
 
        sp.plot(xaxis,sa) ##,'-',color='b',label='Spectrum')
        sp.set_ylabel("dB")
        sp.set_xlabel("MHz")

        if peaks != []:
            ## 10 Marker symbols
            symbols = ['o','v','^','<','>','s','*','+','x','D']
            speaks = sorted(peaks,reverse=True)[0:10]

            i = 0
            for db,mhz in speaks:
                label = "{0:6.1f}dB {1:7.3f}MHz".format(db,mhz)
                sp.plot(mhz,db,symbols[i],label=label)
                i += 1

            sp.legend(numpoints=1,loc=9,bbox_to_anchor=(0.5,-0.1),ncol=5,fontsize=10)

        ##plt.tight_layout()
        plt.show()              


if __name__ == '__main__':
    cd = loadCaptureData(sys.argv[1])
    s = Spectrum(cd,averages=24,normalize=False,window=signal.flattop)
    ##self.sa = s.createSpectrum(normalize=True,window=np.hanning)
    sl = (0,100)
    sl = None
    peaks = s.findPeaks(sl,clipdb=70)
    s.printPeaks(peaks)
    s.plot(sl,peaks) ##,clipdb=50)

