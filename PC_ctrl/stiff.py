import numpy as np
import math
from integrator.integrator import *
from integrator.rram_integrator import *
import matplotlib as mpl
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt


def stiff(t, x):
    
    '''
    The Stiff Function
    '''
    
    dx = np.zeros(2)
    
    dx[0] = -x[0]
    dx[1] = 999*x[0]-1000.*x[1]

    return dx

def xy_plot(ax, integrator, t1):
    y, e, step, trace = integrator.integrate(t1)
    ax.plot(step, trace[0], label = "y1 {}".format(integrator.method))
    ax.plot(step, trace[1], label = "y2 {}".format(integrator.method))
    return

def main():
    
    plt.rcParams['font.size'] = 25
    plt.rcParams['axes.labelsize'] = 25
    plt.rcParams['axes.titlesize'] = 25
    plt.rcParams['xtick.labelsize'] = 20
    plt.rcParams['ytick.labelsize'] = 20
    plt.rcParams['legend.fontsize'] = 25
    
    fig = plt.figure(figsize=(15, 15))
    ax = fig.add_subplot(111)
    
    t0 = 0   
    t1 = 1
    h0 = 0.00199
    x0 = np.array([1., 2.])

    integrator0 = integrator(stiff, 'ex_Heun', t0, x0, h0, rtol = 1e-4, atol = 1e-4,)
    xy_plot(ax, integrator0, t1)
    
    integrator1 = integrator(stiff, 'im_Heun', t0, x0, h0, itr = 10, rtol = 1e-4, atol = 1e-4)
    xy_plot(ax, integrator1, t1)
     
    ax.set_xlabel("x-coordinate")
    ax.set_ylabel("y-coordinate")
    ax.set_title("Visualization of Stiff Function\n")
    ax.legend(loc="upper left")
    plt.show()

    return

main()



