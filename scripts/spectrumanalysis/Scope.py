import visa, time

from CaptureData import CaptureData


class Scope:
    def __init__(self,channel=1):

        self.rm = visa.ResourceManager('@py')
        ##rm.list_resources()
        self.channel = channel
        self.i = self.rm.open_resource('USB0::6833::1230::DS1ZA171710608::0::INSTR')
        self.i.encoding = 'ISO-8859-1'

    def setup(self):
        self.i.write("CHAN{0}:COUP AC".format(self.channel))

        ## All channels off
        for i in range(1,5):
            self.i.write("CHAN{0}:DISP OFF".format(i))

        ## Selected channel on
        self.i.write("CHAN{0}:DISP ON".format(self.channel))

        self.i.write("CHAN{0}:BWL OFF".format(self.channel))

        self.i.write("TIM:MAIN:SCAL 0.001")

        self.i.write("WAV:SOUR CHAN{0}".format(self.channel))
        self.i.write("WAV:MODE RAW")
        self.i.write("WAV:FORM BYTE")
        ## Full Depth
        self.i.write("ACQ:MDEP 24000000")

    def read(self):
    	self.i.write("STOP")
    	time.sleep(1.0)
        cd = CaptureData()

        ## Read 1000000 points at a time due to some limitation...
        for i in range(0,24):
            self.i.write("WAV:START {0}".format(i*1000000 + 1))
            self.i.write("WAV:STOP {0}".format((i+1)*1000000))
            self.i.write("WAV:DATA?")
            d = self.i.read_raw()
            cd.append1000Zdata(d)
        ## Preamble after wave query
    	cd.preamble = self.i.query("WAV:PRE?")
    	self.i.write("RUN")
    	cd.stats()
        return cd



if __name__ == '__main__':
    s = Scope(int(sys.argv[1]))
    s.setup()


