import numpy as np
from .T1R1 import *
from base.step_ctrl import *
from base.error import *

class rram_integrator:
    
    def __init__(self, func, method = 'Euler', x0 = 0, y0 = 0, h0 = 0.01, itr = 0, rtol = 1e-4, atol = 1e-4, bit = 0, test = False):

        '''
        
        Solving the problem dy/dx = f(x,y) using memristor models
        
        Parameters
        ----------
        func : f(x,y)
        method : Runge-Kutta method used
        x0, y0 : Initial conditions
        h0 : Step size setting, 0 for adpative step size
        itr : Number of additional iterations required
        rtol : Relative errors (Usually 1e-2 to 1e-10)
        atol : Absolute errors (Usually 1e-2 to 1e-10)
        bit : Quantization accuracy, 0 for analog conductance

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
        self.test = test
        if self.test:
            self.handle, self.bitrate = Communication_Init()
            self.T1R1 = T1R1(self.method, self.bit, self.test, self.handle, self.bitrate)   
        else:
            self.T1R1 = T1R1(self.method, self.bit, self.test)   
        self.order = self.T1R1.order
        self.itr = self.T1R1.order + itr + 1
        self.mode = self.T1R1.mode        
        self.stepcnt = self.T1R1.stepcnt
        self.stepfac = self.T1R1.stepfac
        self.step_array = np.zeros(self.stepcnt)
        for i in range(self.stepcnt):
            self.step_array[i] = (i+1)*self.stepfac    
        self.max_factor = self.T1R1.max_factor
        self.min_factor = self.T1R1.min_factor
        
    def find_step(self, y, e, h):
        
        '''
        
        Adaptive stepsize control for coarse solver

        '''
        
        err = calculate_mse(y, e)
        step_index = 0
        for i in range(self.stepcnt):
            if self.step_array[i] == h:
                step_index = i
        Accept = True
        if err > self.max_factor:  
            step_index = max(0, step_index-1)
            Accept = False
            return self.step_array[step_index], Accept
        elif err < self.min_factor:
            step_index = min(self.stepcnt-1, step_index+1)
            Accept = True
            return self.step_array[step_index], Accept
        else:
            Accept = True
            return self.step_array[step_index], Accept
        
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
            if self.bit == 0:
                hn0 = self.step_array[0]
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
                
                xb = self.T1R1.mvm_x(np.array([xn0, hn0]))
                kn0 = np.zeros((dimension, self.T1R1.len_k + 1))
                kn0[:, 0] = yn0.copy()
            
                itr_t = 0
                while itr_t < self.T1R1.len_k + 1:                    
                    yb = self.T1R1.mvm_y(kn0, hn0)                    
                    kn1 = np.zeros((dimension, self.T1R1.len_k + 1))
                    for i in range(self.T1R1.len_k):
                        kn1[:, i+1] = self.func(xb[i], yb[:, i])
                    kn1[:, 0] = yn0.copy()          
                    kn0 = kn1
                    itr_t += 1
     
                yn1 = yb[:, self.T1R1.len_k]
                en0 = yb[:, self.T1R1.len_k + 1]
                
                if self.fix_step:
                    xn0 = xn0 + hn0
                    yn0 = yn1
                    hn0 = self.h0
                    step.append(xn0)
                    trace.append(yn0.copy())
                else: 
                    if self.bit == 0:
                        hf, accept = self.find_step(yn1, en0, hn0)                 
                        if accept:
                            xn0 = xn0 + hn0
                            yn0 = yn1
                            hn0 = hf     
                            step.append(xn0)
                            trace.append(yn0.copy())
                        else:
                            xn0 = xn0
                            yn0 = yn0
                            hn0 = hf 
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
                        
                # print(yn0)
                
        elif self.mode == 'implicit':
            while abs(x1 - xn0) > self.atol:
                if xn0 + hn0 > x1:
                    hn0 = x1 - xn0
                xb = self.T1R1.mvm_x(np.array([xn0, hn0]))
                kn0 = np.zeros((dimension, self.T1R1.len_k + 1))
                kn0[:, 0] = yn0.copy()
            
                itr_t = 0
                while itr_t < self.itr:                    
                    yb = self.T1R1.mvm_y(kn0, hn0)                    
                    kn1 = np.zeros((dimension, self.T1R1.len_k + 1))
                    for i in range(self.T1R1.len_k):
                        kn1[:, i+1] = self.func(xb[i], yb[:, i])
                    kn1[:, 0] = yn0.copy()
                    kn0 = kn1
                    itr_t += 1
     
                yn1 = yb[:, self.T1R1.len_k]
                en0 = yb[:, self.T1R1.len_k + 1]
                
                if self.fix_step:
                    xn0 = xn0 + hn0
                    yn0 = yn1
                    hn0 = self.h0
                    step.append(xn0)
                    trace.append(yn0.copy())
                else:   
                    if self.bit == 0:
                        hf, accept = self.find_step(yn1, en0, hn0)                   
                        if accept:
                            xn0 = xn0 + hn0
                            yn0 = yn1
                            hn0 = hf     
                            step.append(xn0)
                            trace.append(yn0.copy())
                        else:
                            xn0 = xn0
                            yn0 = yn0
                            hn0 = hf
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
                        
        step = np.array(step)
        trace = np.transpose(np.array(trace))
            
        return yn0, en0, step, trace
    
            
                
                
        
        
            
            
        