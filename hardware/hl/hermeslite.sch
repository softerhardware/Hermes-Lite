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
Sheet 1 7
Title "Hermes-Lite"
Date "2016-07-17"
Rev "2.0-pre2"
Comp "SofterHardware"
Comment1 "KF7O Steve Haynal"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 1025 1125 2700 1700
U 56C9CAA0
F0 "Power and FPGA" 60
F1 "Power.sch" 60
$EndSheet
$Sheet
S 4125 1125 2700 1700
U 569C3E05
F0 "Ethernet" 60
F1 "Ethernet.sch" 60
$EndSheet
$Sheet
S 7225 1125 2700 1700
U 56B04D05
F0 "Clock" 60
F1 "Clock.sch" 60
$EndSheet
$Sheet
S 1025 3575 2700 1700
U 56AAFEF4
F0 "RF Frontend" 60
F1 "RFFrontend.sch" 60
$EndSheet
$Sheet
S 4125 3575 2700 1700
U 56C6CB95
F0 "Input Output" 60
F1 "InputOutput.sch" 60
$EndSheet
$Sheet
S 7225 3600 2700 1700
U 577F7295
F0 "PA" 60
F1 "PA.sch" 60
$EndSheet
$Comp
L JNO PB1
U 1 1 57AC2594
P 4450 6100
F 0 "PB1" V 4530 6100 39  0000 C CNN
F 1 "PCB" V 4450 6100 39  0000 C CNN
F 2 "" V 4380 6100 50  0001 C CNN
F 3 "" H 4450 6100 50  0000 C CNN
F 4 "PCB" V 4450 6100 60  0001 C CNN "Key"
	1    4450 6100
	0    1    1    0   
$EndComp
$Comp
L JNO EN1
U 1 1 57AC2611
P 4450 6350
F 0 "EN1" V 4530 6350 39  0000 C CNN
F 1 "CASE" V 4450 6350 39  0000 C CNN
F 2 "" V 4380 6350 50  0001 C CNN
F 3 "" H 4450 6350 50  0000 C CNN
F 4 "CASE" V 4450 6350 60  0001 C CNN "Key"
	1    4450 6350
	0    1    1    0   
$EndComp
$Comp
L JNO PG1
U 1 1 57AC2656
P 4450 6600
F 0 "PG1" V 4530 6600 39  0000 C CNN
F 1 "PROG" V 4450 6600 39  0000 C CNN
F 2 "" V 4380 6600 50  0001 C CNN
F 3 "" H 4450 6600 50  0000 C CNN
F 4 "PROG" V 4450 6600 60  0001 C CNN "Key"
	1    4450 6600
	0    1    1    0   
$EndComp
$EndSCHEMATC
