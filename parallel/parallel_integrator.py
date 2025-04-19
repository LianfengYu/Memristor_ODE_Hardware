import numpy as np
from base.step_ctrl import *
from integrator.integrator import *
from integrator.rram_integrator import *

class parallel_integrator:
    
    def __init__(self, func, c_method = 'GL3', f_method = 'GL3', x0 = 0, y0 = 0, h_coarse = 0, h_fine = 0, J = 10, itr = 0, loop = 0, rtol = 1e-4, atol = 1e-4, bit = 0, eps = 1e-8, rram = False):
        
        '''
        
        Solving the problem dy/dx = f(x,y) with Parareal method
        
        Parameters
        ----------
        func : f(x,y)
        c_method, f_method : Runge-Kutta method used for coarse/fine solver
        x0, y0 : Initial conditions
        h_coarse, h_fine : Step size setting for coarse/fine solver, 0 for adpative step size
        J : Number of intervals divided
        itr : Number of additional iterations required
        loop: Maximum number of iterations
        rtol : Relative errors (Usually 1e-2 to 1e-10)
        atol : Absolute errors (Usually 1e-2 to 1e-10)
        bit : Quantization accuracy, 0 for no quantization
        eps : Convergence threshold
        rram : Simulation with rram model      

        '''
        
        self.func = func
        self.c_method = c_method
        self.f_method = f_method
        self.x0 = x0
        self.y0 = y0
        self.h_coarse = h_coarse
        self.h_fine = h_fine
        self.J = J
        self.itr = itr
        self.loop = loop
        self.rtol = rtol
        self.atol = atol
        self.bit = bit
        self.eps = eps
        self.rram = rram
        
    def integrate(self, x1):
        
        '''
        
        Integrate from x0 to x1
        
        Parameters
        ----------
        x1 : Integral Endpoint

        Returns
        -------
        Un : Integral results on various intervals
            
        '''
        
        dx = (x1 - self.x0)/self.J  #segmentation
        U = []      #Coarse solution
        Un = []     #Fine solution

        for i in range(self.J+1):   
            U.append(0)
            Un.append(0)
        U[0] = self.y0 
        Un[0] = self.y0
        loop = 0
        
        for i in range(self.J): #Initial Prediction
            if self.rram:
                U[i+1], _, _, _ = rram_integrator(self.func, self.c_method, self.x0+i*dx, U[i], self.h_coarse, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)
            else:
                U[i+1], _, _, _ = integrator(self.func, self.c_method, self.x0+i*dx, U[i], self.h_coarse, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)
        steps = [] 
        
        while True: 
            loop += 1
            
            for i in range(loop):
                Un[i] = U[i]
            if self.rram:
                Un[loop], _, _, _ = rram_integrator(self.func, self.f_method, self.x0+(loop-1)*dx, U[loop-1], self.h_fine, self.itr, self.rtol, self.atol, self.bit).integrate(self.x0+loop*dx)
            else:
                Un[loop], _, _, _ = integrator(self.func, self.f_method, self.x0+(loop-1)*dx, U[loop-1], self.h_fine, self.itr, self.rtol, self.atol).integrate(self.x0+loop*dx)
                
            for i in range(loop, self.J):
                #Coarse solution: Prediction
                if self.rram:
                    pre, _, _, _ = rram_integrator(self.func, self.c_method, self.x0+i*dx, Un[i], self.h_coarse, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)
                else:
                    pre, _, _, _ = integrator_coarse(self.func, self.c_method, self.x0+i*dx, Un[i], self.h_coarse, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)

                #Fine solution: Correction1
                if self.rram:
                    cor1, _, _, _ = rram_integrator(self.func, self.f_method, self.x0+i*dx, U[i], self.h_fine, self.itr, self.rtol, self.atol, self.bit).integrate(self.x0+(i+1)*dx)
                else:
                    cor1, _, _, _ = integrator(self.func, self.f_method, self.x0+i*dx, U[i], self.h_fine, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)
                    
                #Coarse solution: Correction2
                if self.rram:
                    cor2, _, _, _ = rram_integrator(self.func, self.c_method, self.x0+i*dx, U[i], self.h_coarse, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)
                else:
                    cor2, _, _, _ = integrator(self.func, self.c_method, self.x0+i*dx, U[i], self.h_coarse, self.itr, self.rtol, self.atol).integrate(self.x0+(i+1)*dx)
                Un[i+1] = pre + cor1 - cor2
                                           
            if loop >= self.loop:
                break
            
            err = np.abs(np.array(Un) - np.array(U))
            if np.all(err < self.eps):
                break
            else:
                U = Un.copy()

        return Un[self.J]
    
            
                
                
        
        
            
            
        