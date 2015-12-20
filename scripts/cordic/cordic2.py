import numpy as np
import scipy.optimize


def mkStandardTable(start,stop):
    return np.cos,[(i,np.arctan(2**i)) for i in range(start,stop,-1)]

def doCordic(table,z,f,v=1+0j):

    k = 1
    for i,dd in table:
        di = -1.0 if z <= 0 else 1.0
        v = complex(v.real -(v.imag*di*2.0**i),v.imag+(v.real*di*2.0**i))
        z = z - (di * dd)
        k = k * f(dd)
    v = v*k
    return v,k



def mkHarmonicTable(start,stop,hli):

    def ocosterms(x): return np.sum([a*np.cos(n*x+w) for n,a,w in hli])
    def osinterms(x): return np.sum([a*np.sin(n*x+w) for n,a,w in hli])
    ## Find where sinterms is 0
    zerophase = scipy.optimize.brentq(osinterms,-np.pi/4,np.pi/4)
    print "Zerophase is",zerophase

    ## Max
    print "Max"
    def z(x): return 2.0 - ocosterms(x)
    cmax = scipy.optimize.fmin(z,0)
    #print cmax
    cmaxv = ocosterms(cmax)
    def z(x): return 2.0 - osinterms(x)
    smax = scipy.optimize.fmin(z, np.pi/2)
    #print osinterms(smax)
    #zerophase = 0

    ## Redefine 
    def costerms(x): return ocosterms(x+zerophase)/cmaxv
    def sinterms(x): return osinterms(x+zerophase)/cmaxv

    print "Sin at 0",sinterms(0)
    print "Cos at 0",costerms(0)

    def f(x): return sinterms(x)/costerms(x)

    table = []
    for i in range(start,stop,-1):
        #print i
        def f(x): return (sinterms(x)/costerms(x)) - 2**i
        v = scipy.optimize.brentq(f,0,0.49*np.pi)
        table.append((i,v))

    return sinterms,costerms,table
    #return costerms,sinterms,f


## Create table for all 4 quadrants, 0 for just first
f,table = mkStandardTable(0,-30)

v,k = doCordic(table,np.pi/4.22,f)

print "First"
print v
print k


hli = [ (1,1.0,0),(5,0.1,0) ]
#hli = [ (1,1.0,0) ]

st,ct,table2 = mkHarmonicTable(0,-30,hli)

#ct,st,f = mkHarmonicTable(4,-30,hli)
v2,k2 = doCordic(table2,np.pi/4.22,np.cos)

print "Second"
print v2
print k2