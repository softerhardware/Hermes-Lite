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
Sheet 4 8
Title "Clock"
Date "2016-07-10"
Rev "2.0-pre2"
Comp "SofterHardware"
Comment1 "KF7O Steve Haynal"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L 5P49V5923 U6
U 1 1 56B0541A
P 5400 5800
F 0 "U6" H 5400 7750 60  0000 C CNN
F 1 "5P49V5923" H 5400 5750 60  0000 C CNN
F 2 "" H 5400 5800 60  0001 C CNN
F 3 "" H 5400 5800 60  0000 C CNN
	1    5400 5800
	1    0    0    -1  
$EndComp
NoConn ~ 4500 5200
NoConn ~ 4500 5300
NoConn ~ 4500 5400
NoConn ~ 4500 5500
NoConn ~ 4500 5600
NoConn ~ 4500 5700
NoConn ~ 4500 4600
NoConn ~ 4500 4700
$Comp
L C_Small B59
U 1 1 56B05549
P 6450 4325
F 0 "B59" H 6460 4395 39  0000 L CNN
F 1 "0.1uF" H 6460 4245 39  0000 L CNN
F 2 "" H 6450 4325 50  0001 C CNN
F 3 "" H 6450 4325 50  0000 C CNN
	1    6450 4325
	1    0    0    -1  
$EndComp
$Comp
L C_Small B60
U 1 1 56B0557E
P 6650 4325
F 0 "B60" H 6660 4395 39  0000 L CNN
F 1 "0.1uF" H 6660 4245 39  0000 L CNN
F 2 "" H 6650 4325 50  0001 C CNN
F 3 "" H 6650 4325 50  0000 C CNN
	1    6650 4325
	1    0    0    -1  
$EndComp
$Comp
L C_Small B61
U 1 1 56B0559B
P 6850 4325
F 0 "B61" H 6860 4395 39  0000 L CNN
F 1 "0.1uF" H 6860 4245 39  0000 L CNN
F 2 "" H 6850 4325 50  0001 C CNN
F 3 "" H 6850 4325 50  0000 C CNN
	1    6850 4325
	1    0    0    -1  
$EndComp
$Comp
L C_Small B64
U 1 1 56B055BA
P 7575 4825
F 0 "B64" H 7585 4895 39  0000 L CNN
F 1 "0.1uF" H 7585 4745 39  0000 L CNN
F 2 "" H 7575 4825 50  0001 C CNN
F 3 "" H 7575 4825 50  0000 C CNN
	1    7575 4825
	1    0    0    -1  
$EndComp
$Comp
L C_Small B62
U 1 1 56B05A9B
P 6450 4825
F 0 "B62" H 6460 4895 39  0000 L CNN
F 1 "0.1uF" H 6460 4745 39  0000 L CNN
F 2 "" H 6450 4825 50  0001 C CNN
F 3 "" H 6450 4825 50  0000 C CNN
	1    6450 4825
	1    0    0    -1  
$EndComp
$Comp
L C_Small B63
U 1 1 56B05AC8
P 6650 4825
F 0 "B63" H 6660 4895 39  0000 L CNN
F 1 "0.1uF" H 6660 4745 39  0000 L CNN
F 2 "" H 6650 4825 50  0001 C CNN
F 3 "" H 6650 4825 50  0000 C CNN
	1    6650 4825
	1    0    0    -1  
$EndComp
$Comp
L C_Small C43
U 1 1 56B05AEF
P 6850 4825
F 0 "C43" H 6860 4895 39  0000 L CNN
F 1 "1uF" H 6860 4745 39  0000 L CNN
F 2 "" H 6850 4825 50  0001 C CNN
F 3 "" H 6850 4825 50  0000 C CNN
	1    6850 4825
	1    0    0    -1  
$EndComp
Connection ~ 6450 4700
Connection ~ 6650 4700
Connection ~ 6850 4700
$Comp
L GND #PWR042
U 1 1 56B05C80
P 6850 4975
F 0 "#PWR042" H 6850 4725 39  0001 C CNN
F 1 "GND" H 6850 4825 39  0001 C CNN
F 2 "" H 6850 4975 50  0000 C CNN
F 3 "" H 6850 4975 50  0000 C CNN
	1    6850 4975
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR043
U 1 1 56B05CD0
P 7675 4975
F 0 "#PWR043" H 7675 4725 39  0001 C CNN
F 1 "GND" H 7675 4825 39  0001 C CNN
F 2 "" H 7675 4975 50  0000 C CNN
F 3 "" H 7675 4975 50  0000 C CNN
	1    7675 4975
	1    0    0    -1  
$EndComp
$Comp
L R R42
U 1 1 56B06059
P 6550 5300
F 0 "R42" V 6630 5300 39  0000 C CNN
F 1 "33" V 6550 5300 39  0000 C CNN
F 2 "" V 6480 5300 50  0001 C CNN
F 3 "" H 6550 5300 50  0000 C CNN
	1    6550 5300
	0    1    1    0   
$EndComp
$Comp
L R R45
U 1 1 56B06092
P 6550 5500
F 0 "R45" V 6630 5500 39  0000 C CNN
F 1 "33" V 6550 5500 39  0000 C CNN
F 2 "" V 6480 5500 50  0001 C CNN
F 3 "" H 6550 5500 50  0000 C CNN
F 4 "IntSyncClkOut" V 6550 5500 60  0001 C CNN "Option"
	1    6550 5500
	0    1    1    0   
$EndComp
Wire Wire Line
	6300 5300 6400 5300
Wire Wire Line
	6300 5500 6400 5500
$Comp
L FB FB13
U 1 1 56B062DD
P 7325 4700
F 0 "FB13" H 7400 4650 39  0000 C CNN
F 1 "FB" H 7325 4800 60  0001 C CNN
F 2 "" H 7325 4700 60  0001 C CNN
F 3 "" H 7325 4700 60  0000 C CNN
	1    7325 4700
	1    0    0    -1  
$EndComp
Wire Wire Line
	6300 4700 7175 4700
Text GLabel 7000 5300 2    39   Output ~ 0
RFFE_CLK
$Comp
L GND #PWR044
U 1 1 56B0826C
P 6400 5800
F 0 "#PWR044" H 6400 5550 39  0001 C CNN
F 1 "GND" H 6400 5650 39  0001 C CNN
F 2 "" H 6400 5800 50  0000 C CNN
F 3 "" H 6400 5800 50  0000 C CNN
	1    6400 5800
	1    0    0    -1  
$EndComp
Wire Wire Line
	6300 5700 6400 5700
Wire Wire Line
	6400 5700 6400 5800
$Comp
L BNC CL1
U 1 1 56BF7799
P 2800 4300
F 0 "CL1" H 2810 4420 39  0000 C CNN
F 1 "SMA" H 2950 4250 39  0000 C CNN
F 2 "HERMESLITE:SMAEDGE" H 2800 4300 50  0001 C CNN
F 3 "" H 2800 4300 50  0000 C CNN
F 4 "ExtSyncClk" H 2800 4300 60  0001 C CNN "Option"
	1    2800 4300
	-1   0    0    -1  
$EndComp
$Comp
L R R39
U 1 1 56BF7957
P 3800 4300
F 0 "R39" V 3700 4300 39  0000 C CNN
F 1 "120" V 3800 4300 39  0000 C CNN
F 2 "" V 3730 4300 50  0001 C CNN
F 3 "" H 3800 4300 50  0000 C CNN
F 4 "ExtSyncClk" V 3800 4300 60  0001 C CNN "Option"
	1    3800 4300
	0    1    1    0   
$EndComp
$Comp
L R R40
U 1 1 56BF79F4
P 4100 4450
F 0 "R40" H 3950 4450 39  0000 C CNN
F 1 "75" V 4100 4450 39  0000 C CNN
F 2 "" V 4030 4450 50  0001 C CNN
F 3 "" H 4100 4450 50  0000 C CNN
	1    4100 4450
	1    0    0    -1  
$EndComp
Wire Wire Line
	3950 4300 4500 4300
Connection ~ 4100 4300
Wire Wire Line
	3350 4300 3650 4300
$Comp
L GND #PWR045
U 1 1 56BF7B1E
P 4300 4600
F 0 "#PWR045" H 4300 4350 39  0001 C CNN
F 1 "GND" H 4300 4450 39  0001 C CNN
F 2 "" H 4300 4600 50  0000 C CNN
F 3 "" H 4300 4600 50  0000 C CNN
	1    4300 4600
	1    0    0    -1  
$EndComp
Wire Wire Line
	4500 4400 4300 4400
Wire Wire Line
	4300 4400 4300 4600
Wire Wire Line
	4300 4600 4100 4600
Connection ~ 4300 4600
$Comp
L GND #PWR046
U 1 1 56BF7BE2
P 2800 4500
F 0 "#PWR046" H 2800 4250 39  0001 C CNN
F 1 "GND" H 2800 4350 39  0001 C CNN
F 2 "" H 2800 4500 50  0000 C CNN
F 3 "" H 2800 4500 50  0000 C CNN
	1    2800 4500
	1    0    0    -1  
$EndComp
Wire Wire Line
	4200 4000 4500 4000
Wire Wire Line
	4200 3500 4200 4000
$Comp
L C_Small C42
U 1 1 56BF8D13
P 4350 3150
F 0 "C42" V 4250 3025 39  0000 L CNN
F 1 "DNI" V 4400 3200 39  0000 L CNN
F 2 "" H 4350 3150 50  0001 C CNN
F 3 "" H 4350 3150 50  0000 C CNN
	1    4350 3150
	0    1    1    0   
$EndComp
$Comp
L adcosc X2
U 1 1 56BFC48E
P 3750 2750
F 0 "X2" H 3625 3000 60  0000 C CNN
F 1 "38.4MHz" H 3750 2475 60  0000 C CNN
F 2 "" H 3750 2750 60  0001 C CNN
F 3 "" H 3750 2750 60  0000 C CNN
	1    3750 2750
	1    0    0    -1  
$EndComp
$Comp
L C_Small B57
U 1 1 56BFC4F0
P 4200 3400
F 0 "B57" H 4210 3470 39  0000 L CNN
F 1 "0.1uF" H 4210 3320 39  0000 L CNN
F 2 "" H 4200 3400 50  0001 C CNN
F 3 "" H 4200 3400 50  0000 C CNN
	1    4200 3400
	1    0    0    -1  
$EndComp
Wire Wire Line
	4150 2850 4200 2850
Wire Wire Line
	4200 2850 4200 3300
$Comp
L FB FB12
U 1 1 56BFC5FD
P 5650 2650
F 0 "FB12" H 5725 2600 39  0000 C CNN
F 1 "FB" H 5650 2750 60  0001 C CNN
F 2 "" H 5650 2650 60  0001 C CNN
F 3 "" H 5650 2650 60  0000 C CNN
	1    5650 2650
	1    0    0    -1  
$EndComp
$Comp
L C_Small C41
U 1 1 56BFC646
P 5350 2775
F 0 "C41" H 5360 2845 39  0000 L CNN
F 1 "10uF" H 5360 2695 39  0000 L CNN
F 2 "" H 5350 2775 50  0001 C CNN
F 3 "" H 5350 2775 50  0000 C CNN
	1    5350 2775
	1    0    0    -1  
$EndComp
$Comp
L C_Small B55
U 1 1 56BFC693
P 1025 2175
F 0 "B55" H 1035 2245 39  0000 L CNN
F 1 "0.1uF" H 1035 2095 39  0000 L CNN
F 2 "" H 1025 2175 50  0001 C CNN
F 3 "" H 1025 2175 50  0000 C CNN
F 4 "VCO" H 1025 2175 60  0001 C CNN "Option"
	1    1025 2175
	1    0    0    -1  
$EndComp
Connection ~ 5150 2650
$Comp
L GND #PWR047
U 1 1 56BFC8C6
P 5150 3200
F 0 "#PWR047" H 5150 2950 39  0001 C CNN
F 1 "GND" H 5150 3050 39  0001 C CNN
F 2 "" H 5150 3200 50  0000 C CNN
F 3 "" H 5150 3200 50  0000 C CNN
	1    5150 3200
	1    0    0    -1  
$EndComp
$Comp
L GND #PWR048
U 1 1 56BFF78A
P 3200 3100
F 0 "#PWR048" H 3200 2850 39  0001 C CNN
F 1 "GND" H 3200 2950 39  0001 C CNN
F 2 "" H 3200 3100 50  0000 C CNN
F 3 "" H 3200 3100 50  0000 C CNN
	1    3200 3100
	1    0    0    -1  
$EndComp
$Comp
L R R36
U 1 1 56BFF836
P 3200 2450
F 0 "R36" H 3300 2575 39  0000 C CNN
F 1 "DNI" V 3200 2450 39  0000 C CNN
F 2 "" V 3130 2450 50  0001 C CNN
F 3 "" H 3200 2450 50  0000 C CNN
	1    3200 2450
	1    0    0    -1  
$EndComp
$Comp
L R R38
U 1 1 56BFF939
P 3200 2850
F 0 "R38" H 3300 2975 39  0000 C CNN
F 1 "DNI" V 3200 2850 39  0000 C CNN
F 2 "" V 3130 2850 50  0001 C CNN
F 3 "" H 3200 2850 50  0000 C CNN
	1    3200 2850
	1    0    0    -1  
$EndComp
Wire Wire Line
	3200 2600 3200 2700
Wire Wire Line
	2850 2650 3350 2650
Connection ~ 3200 2650
Wire Wire Line
	3200 3000 3200 3100
Wire Wire Line
	3350 2850 3350 3050
Wire Wire Line
	3350 3050 3200 3050
Connection ~ 3200 3050
Wire Wire Line
	3450 4900 4500 4900
Wire Wire Line
	3450 5000 4500 5000
Text Label 4150 4900 0    39   ~ 0
SDA
Text Label 4150 5000 0    39   ~ 0
SCL
Wire Wire Line
	3200 2050 3200 2300
Wire Wire Line
	1025 2050 4350 2050
$Comp
L MCP4716 U5
U 1 1 56C010F3
P 2400 2550
F 0 "U5" H 2575 2300 60  0000 C CNN
F 1 "MCP4716" H 2400 2800 60  0000 C CNN
F 2 "" H 2400 2550 60  0001 C CNN
F 3 "" H 2400 2550 60  0000 C CNN
F 4 "VCO" H 2400 2550 60  0001 C CNN "Option"
	1    2400 2550
	-1   0    0    1   
$EndComp
Wire Wire Line
	2850 2450 2850 2050
Connection ~ 3200 2050
$Comp
L GND #PWR049
U 1 1 56C0155D
P 2900 2550
F 0 "#PWR049" H 2900 2300 39  0001 C CNN
F 1 "GND" H 2900 2400 39  0001 C CNN
F 2 "" H 2900 2550 50  0000 C CNN
F 3 "" H 2900 2550 50  0000 C CNN
	1    2900 2550
	0    -1   -1   0   
$EndComp
Wire Wire Line
	2850 2550 2900 2550
Wire Wire Line
	1950 2450 1600 2450
Wire Wire Line
	1950 2550 1600 2550
Text Label 1600 2450 0    39   ~ 0
SDA
Text Label 1600 2550 0    39   ~ 0
SCL
$Comp
L R R35
U 1 1 56C017C3
P 1350 2450
F 0 "R35" H 1200 2450 39  0000 C CNN
F 1 "3.3K" V 1350 2450 39  0000 C CNN
F 2 "" V 1280 2450 50  0001 C CNN
F 3 "" H 1350 2450 50  0000 C CNN
F 4 "VCO" H 1350 2450 60  0001 C CNN "Option"
	1    1350 2450
	1    0    0    -1  
$EndComp
$Comp
L R R37
U 1 1 56C0188E
P 1350 2850
F 0 "R37" H 1200 2850 39  0000 C CNN
F 1 "10K" V 1350 2850 39  0000 C CNN
F 2 "" V 1280 2850 50  0001 C CNN
F 3 "" H 1350 2850 50  0000 C CNN
F 4 "VCO" H 1350 2850 60  0001 C CNN "Option"
	1    1350 2850
	1    0    0    -1  
$EndComp
Wire Wire Line
	1350 2050 1350 2300
Connection ~ 2850 2050
Wire Wire Line
	1950 2650 1350 2650
Wire Wire Line
	1350 2600 1350 2700
Connection ~ 1350 2650
$Comp
L GND #PWR050
U 1 1 56C01AF9
P 1350 3100
F 0 "#PWR050" H 1350 2850 39  0001 C CNN
F 1 "GND" H 1350 2950 39  0001 C CNN
F 2 "" H 1350 3100 50  0000 C CNN
F 3 "" H 1350 3100 50  0000 C CNN
	1    1350 3100
	1    0    0    -1  
$EndComp
Wire Wire Line
	1350 3000 1350 3100
$Comp
L C_Small B56
U 1 1 56C01E82
P 5150 2775
F 0 "B56" H 5160 2845 39  0000 L CNN
F 1 "0.1uF" H 5160 2695 39  0000 L CNN
F 2 "" H 5150 2775 50  0001 C CNN
F 3 "" H 5150 2775 50  0000 C CNN
	1    5150 2775
	1    0    0    -1  
$EndComp
Wire Wire Line
	5800 2650 5850 2650
Connection ~ 5350 2650
$Comp
L FPGA U?
U 3 1 56C0AFA1
P 3300 4700
AR Path="/56C0AFA1" Ref="U?"  Part="3" 
AR Path="/56B04D05/56C0AFA1" Ref="U2"  Part="3" 
F 0 "U2" H 3600 4650 60  0000 C CNN
F 1 "FPGA" H 3650 5150 60  0000 C CNN
F 2 "HERMESLITE:CYCLONEIV" H 3300 4700 60  0001 C CNN
F 3 "" H 3300 4700 60  0000 C CNN
	3    3300 4700
	-1   0    0    1   
$EndComp
Wire Wire Line
	3600 4300 3600 4350
Connection ~ 3600 4300
Wire Wire Line
	3600 4800 3450 4800
Text Notes 4000 3525 0    60   ~ 0
WJ3
Text Notes 3425 4400 0    60   ~ 0
WJ2
Text Notes 6675 5300 0    60   ~ 0
WJ1
$Comp
L C_Small B58
U 1 1 56C1777C
P 3250 4300
F 0 "B58" V 3200 4150 39  0000 L CNN
F 1 "0.1uF" V 3200 4350 39  0000 L CNN
F 2 "" H 3250 4300 50  0001 C CNN
F 3 "" H 3250 4300 50  0000 C CNN
F 4 "ExtSyncClk" V 3250 4300 60  0001 C CNN "Option"
	1    3250 4300
	0    1    1    0   
$EndComp
Wire Wire Line
	3150 4300 2950 4300
$Comp
L R R43
U 1 1 56C17F7A
P 4000 5350
F 0 "R43" H 3900 5475 39  0000 C CNN
F 1 "4.7K" V 4000 5350 39  0000 C CNN
F 2 "" V 3930 5350 50  0001 C CNN
F 3 "" H 4000 5350 50  0000 C CNN
	1    4000 5350
	1    0    0    -1  
$EndComp
$Comp
L R R44
U 1 1 56C17FED
P 4150 5350
F 0 "R44" H 4250 5475 39  0000 C CNN
F 1 "4.7K" V 4150 5350 39  0000 C CNN
F 2 "" V 4080 5350 50  0001 C CNN
F 3 "" H 4150 5350 50  0000 C CNN
	1    4150 5350
	1    0    0    -1  
$EndComp
$Comp
L C_Small C44
U 1 1 56D2D3FF
P 7050 4825
F 0 "C44" H 7060 4895 39  0000 L CNN
F 1 "10uF" H 7060 4745 39  0000 L CNN
F 2 "" H 7050 4825 50  0001 C CNN
F 3 "" H 7050 4825 50  0000 C CNN
	1    7050 4825
	1    0    0    -1  
$EndComp
Connection ~ 7050 4700
Wire Wire Line
	4150 5200 4150 5000
Connection ~ 4150 5000
Wire Wire Line
	4000 5200 4000 4900
Connection ~ 4000 4900
Wire Wire Line
	4000 5500 4000 5550
Wire Wire Line
	3900 5550 4150 5550
Wire Wire Line
	4150 5550 4150 5500
Text Notes 1325 4350 0    60   ~ 0
Optional external clock\nfor synchronized radios
Text Notes 4550 2400 0    60   ~ 0
Group A to support 2.5x2.0 or \n3.2x2.5 or 7.0x5.0 mm\nstandard 4-lead SMD\npackages\n
Wire Wire Line
	2950 3250 2950 2650
Connection ~ 2950 2650
Wire Wire Line
	2950 3550 2950 4100
Wire Wire Line
	2950 4100 4500 4100
Wire Wire Line
	4200 3150 4250 3150
Connection ~ 4200 3150
Wire Wire Line
	4150 2650 4600 2650
Wire Wire Line
	5150 3150 4450 3150
Wire Wire Line
	4900 2650 5500 2650
Wire Wire Line
	5150 2675 5150 2650
Wire Wire Line
	5350 2675 5350 2650
Wire Wire Line
	5350 2900 5350 2875
Wire Wire Line
	5150 2875 5150 3200
Connection ~ 5150 2900
Wire Wire Line
	4550 2650 4550 2700
Connection ~ 4550 2650
Wire Wire Line
	4550 3150 4550 3000
Connection ~ 4550 3150
Connection ~ 5150 3150
Wire Wire Line
	4350 2050 4350 2650
Connection ~ 4350 2650
$Comp
L R R41
U 1 1 577CF89C
P 6550 5100
F 0 "R41" V 6630 5100 39  0000 C CNN
F 1 "DNI" V 6550 5100 39  0000 C CNN
F 2 "" V 6480 5100 50  0001 C CNN
F 3 "" H 6550 5100 50  0000 C CNN
	1    6550 5100
	0    1    1    0   
$EndComp
Wire Wire Line
	6400 5100 6300 5100
NoConn ~ 6700 5100
Wire Wire Line
	6700 5300 7000 5300
Wire Wire Line
	7475 4700 7975 4700
$Comp
L C_Small C45
U 1 1 577F0CB4
P 7775 4825
F 0 "C45" H 7785 4895 39  0000 L CNN
F 1 "10uF" H 7785 4745 39  0000 L CNN
F 2 "" H 7775 4825 50  0001 C CNN
F 3 "" H 7775 4825 50  0000 C CNN
	1    7775 4825
	1    0    0    -1  
$EndComp
Wire Wire Line
	6450 4725 6450 4700
Wire Wire Line
	6650 4725 6650 4700
Wire Wire Line
	6850 4725 6850 4700
Wire Wire Line
	7050 4725 7050 4700
Wire Wire Line
	7050 4950 7050 4925
Wire Wire Line
	6450 4950 7050 4950
Wire Wire Line
	6450 4950 6450 4925
Wire Wire Line
	6650 4925 6650 4950
Connection ~ 6650 4950
Wire Wire Line
	6850 4925 6850 4975
Connection ~ 6850 4950
Wire Wire Line
	7775 4725 7775 4700
Connection ~ 7775 4700
Wire Wire Line
	7575 4600 7575 4725
Connection ~ 7575 4700
Wire Wire Line
	7775 4950 7775 4925
Wire Wire Line
	7575 4950 7775 4950
Wire Wire Line
	7575 4950 7575 4925
Wire Wire Line
	7675 4950 7675 4975
Connection ~ 7675 4950
Wire Wire Line
	6300 4100 7275 4100
Wire Wire Line
	6300 4200 7425 4200
Wire Wire Line
	6450 4200 6450 4225
Wire Wire Line
	6650 4225 6650 4100
Connection ~ 6650 4100
Wire Wire Line
	6850 4225 6850 4000
Wire Wire Line
	6300 4000 7425 4000
Text GLabel 7975 4700 2    39   Input ~ 8
Vclk
$Comp
L +3V3 #PWR051
U 1 1 577F37ED
P 7275 4100
F 0 "#PWR051" H 7275 3950 50  0001 C CNN
F 1 "+3V3" V 7275 4300 50  0000 C CNN
F 2 "" H 7275 4100 50  0000 C CNN
F 3 "" H 7275 4100 50  0000 C CNN
	1    7275 4100
	0    1    1    0   
$EndComp
Text GLabel 7425 4000 2    39   Input ~ 8
Vc0
Text GLabel 7425 4200 2    39   Input ~ 8
Vc1
Connection ~ 6850 4000
Connection ~ 6450 4200
$Comp
L GND #PWR052
U 1 1 577F4566
P 6650 4475
F 0 "#PWR052" H 6650 4225 39  0001 C CNN
F 1 "GND" H 6650 4325 39  0001 C CNN
F 2 "" H 6650 4475 50  0000 C CNN
F 3 "" H 6650 4475 50  0000 C CNN
	1    6650 4475
	1    0    0    -1  
$EndComp
Wire Wire Line
	6450 4425 6450 4450
Wire Wire Line
	6450 4450 6850 4450
Wire Wire Line
	6850 4450 6850 4425
Wire Wire Line
	6650 4425 6650 4475
Connection ~ 6650 4450
Text GLabel 3900 5550 0    39   Input ~ 8
Vclk
Connection ~ 4000 5550
Text GLabel 5850 2650 2    39   Input ~ 8
Vclk
Wire Wire Line
	6325 4900 6300 4900
Wire Wire Line
	6325 4700 6325 4900
Connection ~ 6325 4700
Wire Wire Line
	6300 4800 6325 4800
Connection ~ 6325 4800
Wire Wire Line
	6300 4600 7575 4600
$Comp
L JNO J4
U 1 1 5782A6C2
P 2950 3400
F 0 "J4" H 3050 3325 39  0000 C CNN
F 1 "JNO" V 2950 3400 39  0000 C CNN
F 2 "" V 2880 3400 50  0001 C CNN
F 3 "" H 2950 3400 50  0000 C CNN
	1    2950 3400
	1    0    0    -1  
$EndComp
$Comp
L JNO J5
U 1 1 5782B954
P 3600 4500
F 0 "J5" H 3675 4500 39  0000 C CNN
F 1 "JNO" V 3600 4500 39  0000 C CNN
F 2 "" V 3530 4500 50  0001 C CNN
F 3 "" H 3600 4500 50  0000 C CNN
	1    3600 4500
	1    0    0    -1  
$EndComp
Wire Wire Line
	3600 4650 3600 4800
$Comp
L JNC J2
U 1 1 5782EB08
P 4750 2650
F 0 "J2" V 4675 2650 39  0000 C CNN
F 1 "JNC" V 4750 2650 39  0000 C CNN
F 2 "" V 4680 2650 50  0001 C CNN
F 3 "" H 4750 2650 50  0000 C CNN
	1    4750 2650
	0    1    1    0   
$EndComp
$Comp
L JNO J3
U 1 1 5782ED21
P 4550 2850
F 0 "J3" H 4650 2825 39  0000 C CNN
F 1 "JNO" V 4550 2850 39  0000 C CNN
F 2 "" V 4480 2850 50  0001 C CNN
F 3 "" H 4550 2850 50  0000 C CNN
	1    4550 2850
	1    0    0    -1  
$EndComp
$Comp
L RFD4d DB1
U 1 1 5782FD26
P 3300 6850
F 0 "DB1" H 3250 6450 39  0000 C CNN
F 1 "RFD4d" H 3300 7350 39  0001 C CNN
F 2 "" H 3300 6500 60  0001 C CNN
F 3 "" H 3300 6500 60  0000 C CNN
F 4 "CN4S" H 3300 6850 60  0001 C CNN "Key"
F 5 "DBRX" H 3300 6850 60  0001 C CNN "Option"
	1    3300 6850
	-1   0    0    -1  
$EndComp
Text Label 3100 6750 0    39   ~ 0
SDA
Text Label 3100 6950 0    39   ~ 0
SCL
Text GLabel 3075 6550 0    39   Input ~ 8
Vclk
$Comp
L GND #PWR053
U 1 1 5783036E
P 3175 7175
F 0 "#PWR053" H 3175 6925 39  0001 C CNN
F 1 "GND" H 3175 7025 39  0001 C CNN
F 2 "" H 3175 7175 50  0000 C CNN
F 3 "" H 3175 7175 50  0000 C CNN
	1    3175 7175
	1    0    0    -1  
$EndComp
Wire Wire Line
	3200 7150 3175 7150
Wire Wire Line
	3175 7150 3175 7175
Text Notes 3475 6875 0    60   ~ 0
Daughter board I2C.
Text GLabel 3050 6750 0    39   BiDi ~ 0
SDA
Wire Wire Line
	3050 6750 3200 6750
Text GLabel 3050 6950 0    39   Input ~ 0
SCL
Wire Wire Line
	3050 6950 3200 6950
Wire Wire Line
	3075 6550 3200 6550
$Comp
L BNC CL2
U 1 1 578D434B
P 6875 5500
F 0 "CL2" H 6885 5620 39  0000 C CNN
F 1 "SMA" H 7025 5450 39  0000 C CNN
F 2 "" H 6875 5500 50  0001 C CNN
F 3 "" H 6875 5500 50  0000 C CNN
F 4 "IntSyncClkOut" H 6875 5500 60  0001 C CNN "Option"
	1    6875 5500
	1    0    0    -1  
$EndComp
Wire Wire Line
	6725 5500 6700 5500
$Comp
L GND #PWR054
U 1 1 578D45DB
P 6875 5725
F 0 "#PWR054" H 6875 5475 39  0001 C CNN
F 1 "GND" H 6875 5575 39  0001 C CNN
F 2 "" H 6875 5725 50  0000 C CNN
F 3 "" H 6875 5725 50  0000 C CNN
	1    6875 5725
	1    0    0    -1  
$EndComp
Wire Wire Line
	6875 5700 6875 5725
Text Notes 3900 2525 0    60   ~ 12
A
Text Notes 3075 2425 0    60   ~ 12
B
Text Notes 3075 2825 0    60   ~ 12
C
Text Notes 1400 2550 0    60   ~ 12
D
Text Notes 1400 2950 0    60   ~ 12
D
Text Notes 2575 2350 0    60   ~ 12
D
Text Notes 4050 3375 0    60   ~ 12
A
Text Notes 4850 2600 0    60   ~ 12
A
Text Notes 2850 3400 0    60   ~ 12
E
Text Notes 4375 3125 0    60   ~ 12
C
Text Notes 4450 2850 0    60   ~ 12
E
Text Notes 1325 875  0    60   ~ 12
Build Options
Text Notes 1325 1525 0    60   ~ 0
Versa with oscillator: Include A, include B and/or C with adjusted values per oscillator's spec, exclude D and E\nVersa with VCO: Include A and D, exclude B, C and E\nVersa with crystal: Include E, E jumpers shorted, exclude A except oscillator footprint is now stuffed with crystal, include C as 15pF capacitor, exclude B and D\nVersa with second output for synchronized slave: Build one of the Versa options above, include F\nNo Versa but oscillator to AD9866: Exclude all Versa components, build for oscillator, connect WJ3 to WJ1\nNo Versa but external clock to AD9866: Exclude all Versa components, A, B, C, D, and E, wire from WJ2 to WJ1\nSee RF Frontend sheet for additional AD9866 clock options 
Text Notes 6675 5625 0    60   ~ 12
F
Text Notes 6975 5500 0    60   ~ 12
F
Wire Wire Line
	5350 2900 5150 2900
Wire Wire Line
	1025 2050 1025 2075
Connection ~ 1350 2050
$Comp
L GND #PWR055
U 1 1 578A03E0
P 1025 2300
F 0 "#PWR055" H 1025 2050 39  0001 C CNN
F 1 "GND" H 1025 2150 39  0001 C CNN
F 2 "" H 1025 2300 50  0000 C CNN
F 3 "" H 1025 2300 50  0000 C CNN
	1    1025 2300
	1    0    0    -1  
$EndComp
Wire Wire Line
	1025 2275 1025 2300
Text Notes 875  2225 0    60   ~ 12
D
$EndSCHEMATC
