## start with python -i capture_ex1.py

from CaptureData import CaptureData

## Create CaptureData object
cd = CaptureData()

## Create synthetic data
cd.createsynthetic(7.123456,18.987654,3.989898,noise=0.38)

## Save
cd.save("syn2")

## ctrl-d to exit
