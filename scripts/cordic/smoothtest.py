
import numpy as np

def rotate(v,x,hli):
	return v*complex(np.sum([a*np.cos(n*x+w) for n,a,w in hli]),np.sum([a*np.sin(n*x+w) for n,a,w in hli]))


hli = [ (1,1.0,0) ]
hli = [ (1,1.0,0),(4,0.1,0) ]

v = 1+0j

print "Double",rotate(rotate(v,np.pi/2,hli),0.1,hli)
print "Direct",rotate(v,0.1+np.pi/2,hli)

print "Double",rotate(rotate(v,0.3,hli),-0.1,hli)
print "Direct",rotate(v,0.2,hli)