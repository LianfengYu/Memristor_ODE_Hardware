import numpy as np
import math
from integrator.integrator import *
from integrator.rram_integrator import *
from parallel.parallel_integrator import *
import matplotlib as mpl
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from base.error import *


def three_body(t, x):
    
    '''
    The three body problem
    '''
    
    # Define universal gravitation constant
    G = 6.67408e-11  # N-m2/kg2

    # Reference quantities
    m_nd = 1.989e+30  # kg #mass of the sun
    r_nd = 5.326e+12  # m #distance between stars in Alpha Centauri
    v_nd = 30000  # m/s #relative velocity of earth around the sun
    t_nd = 79.91 * 365 * 24 * 3600 * 0.51  # s #orbital period of Alpha Centauri
    # Net constants
    K1 = G * t_nd * m_nd / (r_nd ** 2 * v_nd)
    K2 = v_nd * t_nd / r_nd
    
    # Define masses
    m1 = 1.1  # Alpha Centauri A
    m2 = 1.1  # Alpha Centauri B
    m3 = 0.90  # Third Star
       
    u1 = x[0:3]
    u2 = x[3:6]
    u3 = x[6:9]
    u4 = x[9:12]
    u5 = x[12:15]
    u6 = x[15:18]
    
    du1 = K2*u2
    du2 = K1*(m2*(u3-u1)/(np.linalg.norm(u3-u1))**3+m3*(u5-u1)/(np.linalg.norm(u5-u1))**3)
    du3 = K2*u4
    du4 = K1*(m3*(u5-u3)/(np.linalg.norm(u5-u3))**3+m1*(u1-u3)/(np.linalg.norm(u1-u3))**3)
    du5 = K2*u6
    du6 = K1*(m1*(u1-u5)/(np.linalg.norm(u1-u5))**3+m2*(u3-u5)/(np.linalg.norm(u3-u5))**3)

    dx = np.append(du1, du2)
    dx = np.append(dx, du3)
    dx = np.append(dx, du4)
    dx = np.append(dx, du5)
    dx = np.append(dx, du6)
    
    return dx

def plot3d_separate(ax, bx, integrator, t1):
    y, e, step, trace = integrator.integrate(t1)    
    ax.plot(trace[0], trace[1], trace[2], label = "Star A")
    ax.plot(trace[6], trace[7], trace[8], label = "Star B")
    ax.plot(trace[12], trace[13], trace[14], label = "Star C")
    bx.plot(trace[3], trace[4], trace[5], label = "Star A")
    bx.plot(trace[9], trace[10], trace[11], label = "Star B")
    bx.plot(trace[15], trace[16], trace[17], label = "Star C")  
    return    

def main():
    
    plt.rcParams['font.size'] = 20
    plt.rcParams['axes.labelsize'] = 20
    plt.rcParams['axes.titlesize'] = 25
    plt.rcParams['xtick.labelsize'] = 15
    plt.rcParams['ytick.labelsize'] = 15
    plt.rcParams['legend.fontsize'] = 20
    
    pi = 3.1415926
    
    # Define initial conditions  
    r1 = np.array([0.0, 0.2, 0.])  
    r2 = np.array([0.5, 0., 0.5])  
    r3 = np.array([0., 0., 0.5])  
    
    v1 = np.array([0.0, 0.1, 0.0])  
    v2 = np.array([-0.0, 0., 0.1]) 
    v3 = np.array([0.1, 0., 0.])
       
    x0 = np.append(r1, v1)
    x0 = np.append(x0, r2)
    x0 = np.append(x0, v2)
    x0 = np.append(x0, r3)
    x0 = np.append(x0, v3)
    
    t0 = 0
    t1 = 1
    hc = 0
    hf = 0
    Jt = 5
    loopt = 3
   
    integrator0 = parallel_integrator(three_body, 'GL3', 'GL3', t0, x0, hc, hf, Jt, loop = loopt, rtol=1e-4, atol=1e-4, bit = 32, rram = True)

    integrator1 = integrator(three_body, 'GL3', t0, x0, hf) 
     
    fig = plt.figure(figsize=(25, 10))
    ax = fig.add_subplot(121, projection="3d")       
    bx = fig.add_subplot(122, projection="3d")       
    
    #plot3d_separate(ax, ay, az, bx, by, bz, integrator0, t1)
    plot3d_separate(ax, bx, integrator1, t1)

    ax.set_xlabel("x-coordinate", labelpad = 20)
    ax.set_ylabel("y-coordinate", labelpad = 20)
    ax.set_zlabel("z-coordinate", labelpad = 20)
    bx.set_xlabel("vx-coordinate", labelpad = 20)
    bx.set_ylabel("vy-coordinate", labelpad = 20)
    bx.set_zlabel("vz-coordinate", labelpad = 20)
    
    ax.set_title("Visualization of orbits of stars in a three-body system\n")
    ax.legend(loc="upper left")
    bx.set_title("Visualization of velocities of stars in a three-body system\n")
    bx.legend(loc="upper left")
    plt.show()

    return

main()



