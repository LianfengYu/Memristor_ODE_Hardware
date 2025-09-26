import numpy as np
from ode_method.ode_method import *
from base.step_ctrl import *
import time

class integrator:
    
    def __init__(self, func, method = 'Heun', x0 = 0, y0 = 0, h0 = 0.01, itr = 0, rtol = 1e-4, atol = 1e-4, bit = 0):
        
        '''
        
        Solving the problem dy/dx = f(x,y)
        
        Parameters
        ----------
        func : f(x,y)
        method : Runge-Kutta method used
        x0, y0 : Initial conditions
        h0 : Step size setting, 0 for adpative step size
        itr : Number of additional iterations required
        rtol : Relative errors (Usually 1e-2 to 1e-10)
        atol : Absolute errors (Usually 1e-2 to 1e-10)
        bit : Quantization accuracy, 0 for no quantization

        '''

        self.func = func 
        self.method = method
        self.x0 = x0
        self.y0 = y0
        self.h0 = h0
        if self.h0 == 0:
            self.fix_step = False
        else:
            self.fix_step = True
        self.rtol = rtol
        self.atol = atol
        self.bit = bit
        
        if method == 'ex_Heun':
            self.len_k, self.order, self.A, self.B, self.B_, self.C, self.mode = ex_Heun(False, self.bit)
        elif method == 'im_Heun':
            self.len_k, self.order, self.A, self.B, self.B_, self.C, self.mode = im_Heun(False, self.bit)
        elif method == 'ode23':
            self.len_k, self.order, self.A, self.B, self.B_, self.C, self.mode = ode23(False, self.bit)
        elif method == 'ode45':
            self.len_k, self.order, self.A, self.B, self.B_, self.C, self.mode = ode45(False, self.bit)
        elif method == 'GL2':
            self.len_k, self.order, self.A, self.B, self.B_, self.C, self.mode = GL2(False, self.bit)
        elif method == 'GL3':
            self.len_k, self.order, self.A, self.B, self.B_, self.C, self.mode = GL3(False, self.bit)
        else:
            raise Exception("Error! Unexpected method! Only accept Heun, ode23, ode45, GL2, GL3!")
        
        self.itr = self.order + itr
            
    def integrate(self, x1):
        
        '''
        
        Integrate from x0 to x1
        
        Parameters
        ----------
        x1 : Integral Endpoint

        Returns
        -------
        yn0 : Result
        en0 : Error (y-y*)
        step : Stepsize in the integral
        trace: Integration results at each step
            
        '''
                
        xn0 = self.x0
        yn0 = self.y0.copy()
        dimension = len(yn0)
        
        if self.fix_step:
            hn0 = self.h0
        else:
            hn0 = start_step(xn0, yn0, self.func, self.rtol, self.atol, self.order)
        
        step = []
        step.append(xn0)
        trace = []     
        trace.append(yn0.copy())
        
        
        if self.mode == 'explicit':
            while abs(x1 - xn0) > self.atol:
                if xn0 + hn0 > x1:
                    hn0 = x1 - xn0
                
                kn0 = np.zeros((dimension, self.len_k))
                kn0[:, 0] = self.func(xn0, yn0)
                for i in range(1, self.len_k):
                    yb = yn0.copy()
                    for j in range(i):
                        yb += hn0 * self.A[i][j] * kn0[:, j]
                    kn0[:, i] = self.func(xn0 + hn0 * self.C[i], yb)
                    
                yn1 = yn0.copy()
                en0 = 0
                for i in range(self.len_k):
                    yn1 += hn0 * self.B[i] * kn0[:, i]
                    en0 += hn0 * (self.B[i] - self.B_[i]) * kn0[:, i]
                
                if self.fix_step:
                    xn0 = xn0 + hn0
                    yn0 = yn1
                    hn0 = self.h0
                    step.append(xn0)
                    trace.append(yn0.copy())
                else:                 
                    factor, accept = step_ctrl(yn0, yn1, en0, self.rtol, self.atol, self.order)                   
                    if accept:
                        xn0 = xn0 + hn0
                        yn0 = yn1
                        hn0 = factor * hn0     
                        step.append(xn0)
                        trace.append(yn0.copy())
                    else:
                        #print(factor)
                        xn0 = xn0
                        yn0 = yn0
                        hn0 = factor * hn0 
                    
                # print(xn0)
                # print(yn0)
                
        elif self.mode == 'implicit':
            while abs(x1 - xn0) > self.atol:
                #print(xn0)
                if xn0 + hn0 > x1:
                    hn0 = x1 - xn0
                
                kn0 = np.zeros((dimension, self.len_k))
                itr_t = 0
                
                while itr_t < self.itr:
                    #print(kn0)
                    kn1 = np.zeros((dimension, self.len_k))
                    for i in range(self.len_k):
                        yb = yn0.copy()
                        for j in range(self.len_k):
                            yb += hn0 * self.A[i][j] * kn0[:, j]
                        kn1[:, i] = self.func(xn0 + hn0 * self.C[i], yb)
                    kn0 = kn1
                    itr_t += 1
                
                yn1 = yn0.copy()
                en0 = 0
                for i in range(self.len_k):
                    yn1 += hn0 * self.B[i] * kn0[:, i]
                    en0 += hn0 * (self.B[i] - self.B_[i]) * kn0[:, i]
                
                #print(yn1)
                #print(en0)
                if self.fix_step:
                    xn0 = xn0 + hn0
                    yn0 = yn1
                    hn0 = self.h0
                    step.append(xn0)
                    trace.append(yn0.copy())
                else: 
                    factor, accept = step_ctrl(yn0, yn1, en0, self.rtol, self.atol, self.order)        
                    if accept:
                        xn0 = xn0 + hn0
                        yn0 = yn1
                        hn0 = factor * hn0     
                        step.append(xn0)
                        trace.append(yn0.copy())
                    else:
                        xn0 = xn0
                        yn0 = yn0
                        hn0 = factor * hn0 
        
        step = np.array(step)
        trace = np.transpose(np.array(trace))
        
        return yn0, en0, step, trace
    
            
                
                
        
        
            
            
        