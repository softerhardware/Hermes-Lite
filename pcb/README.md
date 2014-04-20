Hermes-Lite PCB
===============

This directory contains the following files document and build the Hermes-Lite hardware:

 * Kicad schematic
 * Kicad pcb 
 * High resolution photos of assembled prototoype (*.jpg)
 * BOM 
 * Gerber files for prototype
 * Gerber files for stencil

The Kicad project is named ad9866.pro. You may have to update paths fp-lib-table, ad9866.net, ad9866.pro and ad9866.xml to point to your install location. (Search for shaynal in these files and update.)

This hardware design is licensed under the TAPR open hardware license. See LICENSE.TXT for details.

## Additional Documentation ##

Analog Devices made a AD9866 evaluation board which is a helpful reference. The schematic is [here](http://www.analog.com/static/imported-files/eval_boards/AD9865_66_Schematics.pdf) and the layout is [here](http://www.analog.com/static/imported-files/eval_boards/AD9865_66_Layout.pdf).

Schematics and documentation for the BeMicro SDR can be found [here](http://www.alteraforum.com/forum/archive/index.php/t-30731.html)

## Assembly Experiences ##

I tried three assembly methods. At first, I thought I'd use an inexpensive stencil from OshStencils, solder paste and my infrawave toaster oven. I could never get the proper (minimum) amount of paste on the pcb because the large thermal via opening in the stencil under the AD9866 caused too much paste to be pushed under the stencil on to some pins. I scrapped this plan and went with hot air. (I have a $80 smt rework station that includes hot air. You can find them on e-bay or amazon.) I was eventually able to get hot air to work by following techniques you can find on youtube videos. The AD9866 moved around quite a bit. This prototype has problems that at different gain settings for the ADC I see excessive noise. I think I fried it during assembly. The last technique and the one I would recommend would be to slightly tin the AD9866 pads and thermal pad on the PCB with a regular iron and regular solder. Care must be taken to not use too much solder. Then, place the AD9866 and use a toaster oven to solder it in place. I then placed and soldered all the other components by hand. I choose a minimum size of 0805 to make this easy. It may be possible to place and solder the other SMT components along with the AD9866 in the toaster oven too. 

I think the last technique is within reach of most hams. You can buy an old toaster oven at a thrift shop for under $5. You can buy an oven thermometer at Wal-Mart for around $5. 

The AD9866 also requires baking at a low temperature for 24 hours to remove moisture. I also did this in the toaster oven but used too high a temperature on my first prototype. (Maybe that is why it didn't work.) With the oven thermometer, this is no problem.

## PCB ##
 * http://oshpark.com
 * http://www.hackvana.com
 * http://seeedstudio.com
 * http://elecrow.com
 * http://smart-prototyping.com

## PCBA ##
 * Seeedstudio will do PCBA if you use their open parts library
 * smart-prototyping will do PCBA and source parts for you
 * Bittele
 * http://www.myropcb.com
 * Many companies on alibaba

## Stencils ##
 * http://ohararp.com
 * http://www.oshstencils.com

