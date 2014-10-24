EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:special
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:hermeslite
LIBS:waveshare-cache
EELAYER 24 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 1 1
Title "WaveShare Swizzle Board"
Date "21 Oct 2014"
Rev "0.9"
Comp "SofterHardware"
Comment1 "KF7O"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L CN CN1
U 1 1 54473DA8
P 4350 3250
F 0 "CN1" H 4350 2750 50  0000 C CNN
F 1 "WaveShare Angle" H 4350 3750 50  0000 C CNN
F 2 "MODULE" H 4350 3250 50  0001 C CNN
F 3 "DOCUMENTATION" H 4350 3250 50  0001 C CNN
	1    4350 3250
	1    0    0    1   
$EndComp
$Comp
L ECN CN2
U 1 1 54473ED2
P 6500 3300
F 0 "CN2" H 6500 2750 50  0000 C CNN
F 1 "WaveShare Edge" H 6500 3850 50  0000 C CNN
F 2 "MODULE" H 6500 3300 50  0001 C CNN
F 3 "DOCUMENTATION" H 6500 3300 50  0001 C CNN
	1    6500 3300
	1    0    0    1   
$EndComp
Wire Wire Line
	5100 3100 5750 3100
Wire Wire Line
	5750 3200 5100 3200
Wire Wire Line
	5100 3300 5750 3300
Wire Wire Line
	5750 3400 5100 3400
Wire Wire Line
	5100 3500 5750 3500
Wire Wire Line
	3600 3500 3500 3500
Wire Wire Line
	3500 3500 3500 3900
Wire Wire Line
	3500 3900 7350 3900
Wire Wire Line
	7350 3900 7350 3600
Wire Wire Line
	7350 3600 7250 3600
Wire Wire Line
	5750 3600 5750 3900
Connection ~ 5750 3900
Wire Wire Line
	5650 3500 5650 4000
Wire Wire Line
	5650 4000 7450 4000
Wire Wire Line
	7450 4000 7450 3500
Wire Wire Line
	7450 3500 7250 3500
Connection ~ 5650 3500
Wire Wire Line
	3600 3400 3400 3400
Wire Wire Line
	3400 3400 3400 4100
Wire Wire Line
	3400 4100 7550 4100
Wire Wire Line
	7550 4100 7550 3400
Wire Wire Line
	7550 3400 7250 3400
Wire Wire Line
	3600 3300 3300 3300
Wire Wire Line
	3300 3300 3300 4200
Wire Wire Line
	3300 4200 7650 4200
Wire Wire Line
	7650 4200 7650 3300
Wire Wire Line
	7650 3300 7250 3300
Wire Wire Line
	3600 3000 3500 3000
Wire Wire Line
	3500 3000 3500 2700
Wire Wire Line
	3500 2700 7350 2700
Wire Wire Line
	7350 2700 7350 3000
Wire Wire Line
	7350 3000 7250 3000
Wire Wire Line
	7250 3100 7450 3100
Wire Wire Line
	7450 3100 7450 2600
Wire Wire Line
	7450 2600 3400 2600
Wire Wire Line
	3400 2600 3400 3100
Wire Wire Line
	3400 3100 3600 3100
Wire Wire Line
	3600 3200 3300 3200
Wire Wire Line
	3300 3200 3300 2500
Wire Wire Line
	3300 2500 7550 2500
Wire Wire Line
	7550 2500 7550 3200
Wire Wire Line
	7550 3200 7250 3200
NoConn ~ 5100 3000
NoConn ~ 5750 3000
$EndSCHEMATC
