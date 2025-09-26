import numpy as np
import math
from integrator.integrator import *
from integrator.rram_integrator import *
from parallel.parallel_integrator import *
import matplotlib as mpl
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from base.error import *


def lorenz(t, x):
    
    '''
    The lorenz strange attractor
    '''
    
    sigma = 10
    rho = 28
    beta = 8/3
    
    dx = np.zeros(3)
    
    dx[0] = sigma*(x[1]-x[0])
    dx[1] = x[0]*(rho-x[2])-x[1]
    dx[2] = x[0]*x[1]-beta*x[2]
    
    return dx

def plot3d_lorenz(ax, integrator, t1):
    y, e, step, trace = integrator.integrate(t1)    
    ax.plot(trace[0], trace[1], trace[2], label = "{}".format(integrator.method))
    print(y)
    return  

def main():
    
    plt.rcParams['font.size'] = 25
    plt.rcParams['axes.labelsize'] = 25
    plt.rcParams['axes.titlesize'] = 25
    plt.rcParams['xtick.labelsize'] = 20
    plt.rcParams['ytick.labelsize'] = 20
    plt.rcParams['legend.fontsize'] = 25
    
    t0 = 0   
    t1 = 20
    h0 = 0
    x0 = np.array([5., 10., 10.])  
    
    fig = plt.figure(figsize=(15, 15))
    ax = fig.add_subplot(111, projection="3d")
    
    integrator0 = rram_integrator(lorenz, 'GL3', t0, x0, h0, bit = 32)   
    plot3d_lorenz(ax, integrator0, t1)
    
    integrator1 = integrator(lorenz, 'GL3', t0, x0, h0)   
    plot3d_lorenz(ax, integrator1, t1)
    
    ax.set_xlabel("x-coordinate", fontsize=10, labelpad=5)
    ax.set_ylabel("y-coordinate", fontsize=10, labelpad=5)
    ax.set_zlabel("z-coordinate", fontsize=10, labelpad=5)
    ax.set_title("Visualization of Lorentz Attractor\n", fontsize=25)
    ax.legend(loc="upper left", fontsize=25)
    ax.view_init(elev=20, azim=120)
    plt.show()
       
    return

main()



