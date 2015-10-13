## start with python -i scope_ex1.py

from Scope import Scope


## Create a scope object with the channel you are using
s = Scope(2)
s.setup()

## Apply the signal and then adjust vertical scale so that signal
## just fills scope display.
## 
## Keep horizontal timebase so that sampling rate is 500 MSa/s

## Read capture data
## Sometimes this locks up and you have to do ctrl-c and try again
## cd = s.read()

## You can turn off the signal source once the scope is in the stop state

## Save capture data to file
## cd.save("filename")

## repeat for various measurments

## ctrl-d to exit
