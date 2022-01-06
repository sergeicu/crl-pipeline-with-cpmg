#!/usr/bin/python

# Arguments: multiple text files, to plot in the same graph

import sys
from numpy import *
import matplotlib.pyplot as plt


for arg in sys.argv[2:]:
    print arg
    data = genfromtxt(arg)

    x=data[:,0]
    y=data[:,1]

    plt.plot(x,y,'ro')
    plt.plot(x,y,'k--')

plt.savefig(sys.argv[1]);
#plt.show()
