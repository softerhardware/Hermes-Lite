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
L TLV62130 U6
U 1 1 56D22086
P 3500 2300
F 0 "U6" H 4000 3350 60  0000 C CNN
F 1 "TLV62130" H 4000 2150 60  0000 C CNN
F 2 "" H 3500 2300 60  0000 C CNN
F 3 "" H 3500 2300 60  0000 C CNN
	1    3500 2300
	1    0    0    -1  
$EndComp
$Comp
L INDUCTOR_SMALL L2
U 1 1 56D2237A
P 4850 1400
F 0 "L2" H 4850 1500 50  0000 C CNN
F 1 "3.3uH" H 4850 1350 50  0000 C CNN
F 2 "" H 4850 1400 50  0000 C CNN
F 3 "" H 4850 1400 50  0000 C CNN
	1    4850 1400
	1    0    0    -1  
$EndComp
$Comp
L R R2
U 1 1 56D22502
P 5200 1650
F 0 "R2" V 5280 1650 50  0000 C CNN
F 1 "100K" V 5200 1650 50  0000 C CNN
F 2 "" V 5130 1650 50  0000 C CNN
F 3 "" H 5200 1650 50  0000 C CNN
	1    5200 1650
	1    0    0    -1  
$EndComp
$Comp
L R R3
U 1 1 56D22553
P 5400 1650
F 0 "R3" V 5480 1650 50  0000 C CNN
F 1 "750K" V 5400 1650 50  0000 C CNN
F 2 "" V 5330 1650 50  0000 C CNN
F 3 "" H 5400 1650 50  0000 C CNN
	1    5400 1650
	1    0    0    -1  
$EndComp
$Comp
L R R30
U 1 1 56D2257C
P 5400 2050
F 0 "R30" V 5480 2050 50  0000 C CNN
F 1 "240K" V 5400 2050 50  0000 C CNN
F 2 "" V 5330 2050 50  0000 C CNN
F 3 "" H 5400 2050 50  0000 C CNN
	1    5400 2050
	1    0    0    -1  
$EndComp
Wire Wire Line
	4500 1400 4500 1600
Connection ~ 4500 1500
Wire Wire Line
	4500 1400 4600 1400
Connection ~ 4500 1400
Wire Wire Line
	4500 1800 5200 1800
Wire Wire Line
	5100 1400 5800 1400
Wire Wire Line
	5200 1400 5200 1500
Wire Wire Line
	5400 1400 5400 1500
Connection ~ 5200 1400
Wire Wire Line
	5400 1800 5400 1900
Wire Wire Line
	5400 1900 4500 1900
Wire Wire Line
	4500 1700 5050 1700
Wire Wire Line
	5050 1700 5050 1500
Wire Wire Line
	5050 1500 5200 1500
Connection ~ 5200 1500
Connection ~ 5400 1900
$Comp
L C C25
U 1 1 56D227E7
P 5700 1650
F 0 "C25" H 5725 1750 50  0000 L CNN
F 1 "47uF" H 5725 1550 50  0000 L CNN
F 2 "" H 5738 1500 50  0000 C CNN
F 3 "" H 5700 1650 50  0000 C CNN
	1    5700 1650
	1    0    0    -1  
$EndComp
Wire Wire Line
	5700 1800 5700 2300
Wire Wire Line
	5700 2300 4500 2300
Wire Wire Line
	5700 1400 5700 1500
Connection ~ 5400 1400
Wire Wire Line
	4500 2300 4500 2100
Wire Wire Line
	5400 2200 5400 2350
Connection ~ 5400 2300
Connection ~ 4500 2200
Connection ~ 4500 2300
$Comp
L GND #PWR48
U 1 1 56D229CA
P 5400 2350
F 0 "#PWR48" H 5400 2100 50  0001 C CNN
F 1 "GND" H 5400 2200 50  0001 C CNN
F 2 "" H 5400 2350 50  0000 C CNN
F 3 "" H 5400 2350 50  0000 C CNN
	1    5400 2350
	1    0    0    -1  
$EndComp
$Comp
L VCC #PWR49
U 1 1 56D22CEA
P 5800 1400
F 0 "#PWR49" H 5800 1250 50  0001 C CNN
F 1 "VCC" V 5800 1600 50  0000 C CNN
F 2 "" H 5800 1400 50  0000 C CNN
F 3 "" H 5800 1400 50  0000 C CNN
	1    5800 1400
	0    1    1    0   
$EndComp
Connection ~ 5700 1400
$Comp
L C C17
U 1 1 56D22D7F
P 3000 1650
F 0 "C17" H 3025 1750 50  0000 L CNN
F 1 "10uF" H 3025 1550 50  0000 L CNN
F 2 "" H 3038 1500 50  0000 C CNN
F 3 "" H 3000 1650 50  0000 C CNN
	1    3000 1650
	1    0    0    -1  
$EndComp
$Comp
L C_Small C18
U 1 1 56D22E50
P 3300 2000
F 0 "C18" H 3200 2100 50  0000 L CNN
F 1 "3.3nF" H 3100 1900 50  0000 L CNN
F 2 "" H 3300 2000 50  0000 C CNN
F 3 "" H 3300 2000 50  0000 C CNN
	1    3300 2000
	1    0    0    -1  
$EndComp
Wire Wire Line
	3500 1400 3500 1700
Wire Wire Line
	2900 1400 3500 1400
Wire Wire Line
	3000 1400 3000 1500
Connection ~ 3500 1400
Connection ~ 3500 1500
Connection ~ 3500 1600
Wire Wire Line
	3500 2100 3500 2300
Wire Wire Line
	3500 2300 3000 2300
Wire Wire Line
	3000 2300 3000 1800
Wire Wire Line
	3300 2100 3300 2350
Connection ~ 3300 2300
Wire Wire Line
	3300 1900 3500 1900
$Comp
L GND #PWR47
U 1 1 56D2305D
P 3300 2350
F 0 "#PWR47" H 3300 2100 50  0001 C CNN
F 1 "GND" H 3300 2200 50  0001 C CNN
F 2 "" H 3300 2350 50  0000 C CNN
F 3 "" H 3300 2350 50  0000 C CNN
	1    3300 2350
	1    0    0    -1  
$EndComp
$Comp
L +12V #PWR46
U 1 1 56D23369
P 2900 1400
F 0 "#PWR46" H 2900 1250 50  0001 C CNN
F 1 "+12V" V 2900 1650 50  0000 C CNN
F 2 "" H 2900 1400 50  0000 C CNN
F 3 "" H 2900 1400 50  0000 C CNN
	1    2900 1400
	0    -1   -1   0   
$EndComp
Connection ~ 3000 1400
Connection ~ 3500 2200
Connection ~ 3500 2300
$EndSCHEMATC
