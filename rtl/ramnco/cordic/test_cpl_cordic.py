from __future__ import generators

import unittest
from unittest import TestCase
import random
from random import randrange
random.seed(2)
import numpy as np

#import psyco
#psyco.profile()

from myhdl import Simulation, StopSimulation, Signal, \
                  delay, intbv, negedge, posedge, now, modbv

from cpl_cordic import cpl_cordic

class TestInc(TestCase):

    def clockGen(self, clk):
        while 1:
            yield delay(10)
            clk.next = not clk
    
    def stimulus(self, clk, phase, cos):
        phase.next = 0x18a9c71c
        for i in range(32):
            yield negedge(clk)


        cosa = np.zeros(16384)
 
        for i in range(16384):
            cosa[i] = cos >> 2
            yield clk.negedge
 
        np.save("cosa",cosa)
 
        raise StopSimulation

    def bench(self):

        clk = Signal(intbv(0))
        maxv = 2**31
        phase = Signal(intbv(0,min=-maxv,max=maxv))
        maxv = 2**15
        cos = Signal(intbv(0,min=-maxv,max=maxv))
 
        cpl_cordic_1 = cpl_cordic(clk,phase,cos)
        st_1 = self.stimulus(clk,phase,cos)
        clk_1 = self.clockGen(clk)

        sim = Simulation(cpl_cordic_1,st_1,clk_1)
        return sim

    def test1(self):
        """ Check increment operation """
        sim = self.bench()
        sim.run()
 

          
if __name__ == '__main__':
    unittest.main()


            
            

    

    
        


                

        

