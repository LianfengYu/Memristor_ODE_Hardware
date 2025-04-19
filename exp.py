import numpy as np
import math
from integrator.integrator import *
from integrator.rram_integrator import *
from parallel.parallel_integrator import *
from base.error import *
import matplotlib as mpl
import matplotlib.pyplot as plt

def exponent(t, x):
    
    '''
    The Exponent Function (dx/dt = x)
    '''
    
    return x

def xy_plot(ax, integrator, t1):
    y, e, step, trace = integrator.integrate(t1)
    mse = calculate_mse(y, np.array([np.exp(t1)]))
    ax.plot(step, trace[0], label = "{}:\nmse = {:.4e}".format(integrator.method, mse))
    return mse

def main():
    
    plt.rcParams['font.size'] = 25
    plt.rcParams['axes.labelsize'] = 25
    plt.rcParams['axes.titlesize'] = 25
    plt.rcParams['xtick.labelsize'] = 20
    plt.rcParams['ytick.labelsize'] = 20
    plt.rcParams['legend.fontsize'] = 25
    
    t0 = -2
    t1 = 2
    h0 = 0.1
    x0 = np.array([math.exp(t0)])
      
    integrator0 = rram_integrator(exponent, 'im_Heun', t0, x0, h0, bit = 0) 
    integrator1 = integrator(exponent, 'im_Heun', t0, x0, h0) 
    
    fig = plt.figure(figsize=(15, 15))
    ax = fig.add_subplot(111)

    xy_plot(ax, integrator0, t1)
    xy_plot(ax, integrator1, t1)

    ax.set_xlabel("x-coordinate")
    ax.set_ylabel("y-coordinate")
    ax.set_title("Visualization of Exponent Function\n")
    ax.legend(loc="upper left")
    plt.show()
    
    
    return

main()
