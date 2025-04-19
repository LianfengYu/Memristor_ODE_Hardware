from __future__ import division, with_statement, print_function
import numpy as np
from ode_method.ode_method import *
from model.model import model_map, read, stepcnt, stepfac, max_factor, min_factor

class T1R1:

    def __init__(self, method = 'ex_Heun', bit = 0):
        
        '''
        
        Behavioral-level modele of 1T1R arrays
        
        Parameters
        ----------
        method : Runge-Kutta method used
        bit : Quantization accuracy, 0 for analog conductance

        '''  
        
        self.method = method
        self.bit = bit
        
        self.stepcnt = stepcnt
        self.stepfac = stepfac
        self.max_factor = max_factor
        self.min_factor = min_factor
        
        if method == 'ex_Heun':
            self.len_k, self.order, self.rram, self.c, self.mode = ex_Heun(bit = self.bit)
        elif method == 'im_Heun':
            self.len_k, self.order, self.rram, self.c, self.mode = im_Heun(bit = self.bit)
        elif method == 'ode23':
            self.len_k, self.order, self.rram, self.c, self.mode = ode23(bit = self.bit)
        elif method == 'ode45':
            self.len_k, self.order, self.rram, self.c, self.mode = ode45(bit = self.bit)
        elif method == 'GL2':
            self.len_k, self.order, self.rram, self.c, self.mode = GL2(bit = self.bit)
        elif method == 'GL3':
            self.len_k, self.order, self.rram, self.c, self.mode = GL3(bit = self.bit)
        else:
            raise Exception("Error! Unexpected method! Only accept Heun, ode23, ode45, GL2, GL3!")
        
        '''
        Map A and B to our memristor model 
        '''
        
        self.rram, self.scale = model_map(self.rram, self.bit)
      
      
    def mvm_y(self, in_y, h = 1):
        
        '''
        Calculate A and B
        '''
        
        dimension = len(in_y)
        if len(in_y[0]) != self.len_k + 1:
            raise Exception("Error! Unexpected y input! Expect input length {}!".format(self.len_k + 1))    
        y0 = in_y[:, 0]
        k0 = in_y[:, 1:]
        out_y = np.zeros((dimension, self.len_k + 2))

        for i in range(self.len_k + 2):
            for j in range(self.len_k):
                out_y[:, i] += k0[:, j] * read(self.rram[j][i]) * h / self.scale
            if i < self.len_k + 1:
                out_y[:, i] += y0[:]

        return out_y
    
    def mvm_x(self, in_x):        
        if len(in_x) != 2:
            raise Exception("Error! Unexpected x input! Expect input length 2!")    
        
        out_x = np.zeros(self.len_k)
        for i in range(self.len_k):
            out_x[i] = in_x[0] + in_x[1] * self.c[i]
                   
        return out_x
    
            
            
            
            
            
            
            
            