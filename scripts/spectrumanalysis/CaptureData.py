import cPickle as pickle
import numpy as np

def load(fn):
    pkl_file = open(fn+".scd", 'rb')
    m = pickle.load(pkl_file)
    pkl_file.close()
    return m  

class CaptureData:

    def __init__(self):

        self.preamble = ""
        self.data = bytes()

    def __getitem__(self,sl):
        return self.data[sl]

    def xincrement(self):
        return float(self.preamble.split(',')[4])

    def samplerate(self):
        return 1.0/self.xincrement()

    def yincrement(self):
        return float(self.preamble.split(',')[7])

    def yorigin(self):
        return int(self.preamble.split(',')[8])

    def yreference(self):
        s = self.preamble.split(',')[9]
        return int(s.split('\n')[0]) 

    def points(self):
        return len(self.data)

    def append1000Zdata(self,newdata):
        ## 1000Z has 11 byte preamble, 1 termination byte
        self.data += newdata[11:-1]

    def save(self,fn):
        pkl_file = open(fn+".scd", 'wb')    
        pickle.dump(self, pkl_file, pickle.HIGHEST_PROTOCOL)
        pkl_file.close()

    def stats(self):
        minv = ord(min(self.data))
        maxv = ord(max(self.data))
        print "Min={0} Max={1} Span={2} Yincrement={3} Vpp={4}".format(minv,maxv,maxv-minv,self.yincrement(),(maxv-minv)*self.yincrement())
        print "Preamble is",self.preamble

    def createsynthetic(self,f1,f2,f3,noise=None):
        ## Assume 500 MHz sampling rate
        totaltime = 24.0e6 /500.0e6
        t = np.linspace(0,totaltime,24000000)
        ## 20 dBm
        a20 = 3.162 * np.sin(2*np.pi*f1*1e6 * t)
        ## 10 dBm
        a10 = np.sin( (2*np.pi*f2*1e6 * t) + .1)
        ## 5 dBm
        a5 = 0.562 * np.sin( (2*np.pi*f3*1e6 * t) + .3)
        w = a20+a10+a5
        ## Possible noise
        if noise:
            if not (0.0 < noise <= 1.0): noise = 0.5  
            w = w + np.random.normal(0.0, scale=noise, size=24000000) 
        
        ## Max peak is 4.724, scale by 20, min peak near 0
        offset = abs(w.min())+0.005
        w = 20 * (w + offset)
        print "Min,Max",w.min(),w.max()
        self.t = np.round(w).astype(np.uint8)
        self.data = self.t.tostring()

        self.preamble = u'0,0,0,0,2.000000e-09,0,0,{0},0,115\n'.format(1.0/20)

    def createsynthetic2(self,f1,f2,f3,noise=None):
        totaltime = 24.0e6 /1000.0e6
        t = np.linspace(0,totaltime,24000000)
        ## 20 dBm
        a20 = .000316180 * np.sin(2*np.pi*f1*1e6 * t)
        ## 10 dBm
        a10 = .000223838 * np.sin( (2*np.pi*f2*1e6 * t) + .1)
        ## 5 dBm
        a5 = .000501 * np.sin( (2*np.pi*f3*1e6 * t) + .3)
        w = a20+a10+a5
        ## Possible noise
        if noise:
            if not (0.0 < noise <= 1.0): noise = 0.5  
            w = w + np.random.normal(0.0, scale=noise, size=24000000) 
        
        ## Max peak is 4.724, scale by 20, min peak near 0
        w = (w /.001) + 3
        ##offset = abs(w.min())+0.005
        ##w = 20 * (w + offset)
        print "Min,Max",w.min(),w.max()
        self.t = np.round(w).astype(np.uint8)
        self.data = self.t.tostring()

        self.preamble = u'0,0,0,0,1.000000e-09,0,0,{0},0,115\n'.format(0.001)
