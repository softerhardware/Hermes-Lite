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
LIBS:hermeslite-cache
EELAYER 25 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 5 6
Title "Power"
Date "2016-02-18"
Rev "2.0-pre1"
Comp "SofterHardware"
Comment1 "KF7O Steve Haynal"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L C_Small C?
U 1 1 56C9F494
P 4900 3150
F 0 "C?" H 4925 3200 30  0000 L CNN
F 1 "1UF" H 4900 3100 30  0000 L CNN
F 2 "SMD_Packages:SMD-0805" H 4900 3150 60  0001 C CNN
F 3 "" H 4900 3150 60  0000 C CNN
	1    4900 3150
	1    0    0    -1  
$EndComp
$Comp
L CP1_Small C?
U 1 1 56C9F49B
P 5100 3150
F 0 "C?" H 5125 3200 30  0000 L CNN
F 1 "10UF" H 5125 3075 30  0000 L CNN
F 2 "SMD_Packages:SMD-1206_Pol" H 5100 3150 60  0001 C CNN
F 3 "" H 5100 3150 60  0000 C CNN
	1    5100 3150
	1    0    0    -1  
$EndComp
$Comp
L C_Small C?
U 1 1 56C9F4A2
P 4700 3150
F 0 "C?" H 4725 3200 30  0000 L CNN
F 1 "0.1UF" H 4725 3100 30  0000 L CNN
F 2 "SMD_Packages:SMD-0805" H 4700 3150 60  0001 C CNN
F 3 "" H 4700 3150 60  0000 C CNN
	1    4700 3150
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR?
U 1 1 56C9F4A9
P 4900 3750
F 0 "#PWR?" H 4900 3750 30  0001 C CNN
F 1 "GND" H 4900 3680 30  0001 C CNN
F 2 "" H 4900 3750 60  0000 C CNN
F 3 "" H 4900 3750 60  0000 C CNN
	1    4900 3750
	1    0    0    -1  
$EndComp
$Comp
L C_Small C?
U 1 1 56C9F4AF
P 4900 3550
F 0 "C?" H 4925 3600 30  0000 L CNN
F 1 "1UF" H 4900 3500 30  0000 L CNN
F 2 "SMD_Packages:SMD-0805" H 4900 3550 60  0001 C CNN
F 3 "" H 4900 3550 60  0000 C CNN
	1    4900 3550
	1    0    0    -1  
$EndComp
$Comp
L CP1_Small C?
U 1 1 56C9F4B6
P 5100 3550
F 0 "C?" H 5125 3600 30  0000 L CNN
F 1 "10UF" H 5125 3475 30  0000 L CNN
F 2 "SMD_Packages:SMD-1206_Pol" H 5100 3550 60  0001 C CNN
F 3 "" H 5100 3550 60  0000 C CNN
	1    5100 3550
	1    0    0    -1  
$EndComp
$Comp
L C_Small C?
U 1 1 56C9F4BD
P 4700 3550
F 0 "C?" H 4725 3600 30  0000 L CNN
F 1 "0.1UF" H 4725 3500 30  0000 L CNN
F 2 "SMD_Packages:SMD-0805" H 4700 3550 60  0001 C CNN
F 3 "" H 4700 3550 60  0000 C CNN
	1    4700 3550
	1    0    0    -1  
$EndComp
Text GLabel 4600 3050 0    60   Input ~ 0
3VIN
Wire Wire Line
	5250 3050 5250 3650
Connection ~ 5250 3250
Wire Wire Line
	4600 3050 5250 3050
Wire Wire Line
	4700 3450 5250 3450
Connection ~ 5250 3450
Wire Wire Line
	4600 3650 5100 3650
Wire Wire Line
	4600 3650 4600 3250
Wire Wire Line
	4600 3250 5100 3250
Connection ~ 4700 3650
Connection ~ 4900 3250
Connection ~ 4700 3250
Connection ~ 4900 3650
Connection ~ 4900 3450
Connection ~ 5100 3450
Connection ~ 4900 3050
Connection ~ 5100 3050
Connection ~ 5250 3050
Connection ~ 4700 3050
Wire Wire Line
	4900 3650 4900 3750
$EndSCHEMATC
