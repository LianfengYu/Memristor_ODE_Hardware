import numpy as np
import math
from integrator.integrator import *
from integrator.rram_integrator import *
from parallel.parallel_integrator import *
import matplotlib as mpl
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
from base.error import *
import time
# from parallel.parallel_integrator import *

def L96_2t(t, x):
    
    F = 10.0  # Focring
    h = 1.0  # Coupling coefficient
    b = 10.0  # ratio of amplitudes
    c = 10.0  # time-scale ratio

    X = x[:36]
    Y = x[36:]
    JK, K = len(Y), len(X)
    J = JK // K
    assert JK == J * K, "X and Y have incompatible shapes"
    Xdot = np.zeros(K)
    hcb = (h * c) / b

    Ysummed = Y.reshape((K, J)).sum(axis=-1)

    Xdot = np.roll(X, 1) * (np.roll(X, -1) - np.roll(X, 2)) - X + F - hcb * Ysummed
    Ydot = (
        -c * b * np.roll(Y, -1) * (np.roll(Y, -2) - np.roll(Y, 1))
        - c * Y
        + hcb * np.repeat(X, J)
    )

    return np.append(Xdot, Ydot)

def s(k, K):
    """A non-dimension coordinate from -1..+1 corresponding to k=0..K"""
    return 2 * (0.5 + k) / K - 1

def main():
    
    K = 36  # Number of globa-scale variables X
    J = 10  # Number of local-scale Y variables per single global-scale X variable

    k = np.arange(K)  # For coordinate in plots
    j = np.arange(J * K)  # For coordinate in plots
    
    # Initial conditions
    X_init = s(k, K) * (s(k, K) - 1) * (s(k, K) + 1)
    Y_init = 0 * s(j, J * K) * (s(j, J * K) - 1) * (s(j, J * K) + 1)
    
    x0 = np.append(X_init, Y_init)
    t0 = 0
    t1 = 5
    h0 = 0  
      
    integrator0 = rram_integrator(L96_2t, 'GL3', t0, x0, h0, bit = 32)   
    integrator1 = integrator(L96_2t, 'GL3', t0, x0, h0) 
    
    yn0, en0, step, trace = integrator0.integrate(t1)   
    t = step
    X = trace[:K].T
    Y = trace[K:].T
 
    plt.figure(figsize=(20, 15))
    plt.subplot(221)
    
    # Snapshot of X[k]
    plt.plot(k, X[-1], label="$X_k(t=5)$")
    plt.plot(j / J, Y[-1], label="$Y_{j,k}(t=5)$")
    plt.plot(k, X_init, "k:", label="$X_k(t=0)$")
    plt.plot(j / J, Y_init, "k:", label="$Y_{j,k}(t=0)$")
    plt.xlabel("k, k + j/J")
    plt.title("$X_k, Y_{j,k}$")
    plt.subplot(222)
    
    # Sample time-series X[0](t), Y[0](t)
    plt.plot(t, X[:, 0], label="$X_0(t)$")
    plt.plot(t, Y[:, 0], label="$Y_{0,0}(t)$")
    plt.xlabel("t")
    plt.subplot(223)
    
    # Full model history of X
    plt.contourf(k, t, X)
    plt.colorbar(orientation="horizontal")
    plt.xlabel("k")
    plt.ylabel("t")
    plt.title("$X_k(t)$")
    plt.subplot(224)
    
    # Full model history of Y
    plt.contourf(j / J, t, Y)
    plt.colorbar(orientation="horizontal")
    plt.xlabel("k + j/J")
    plt.ylabel("t")
    plt.title("$Y_{j,k}(t)$");   
 
    return

main()



