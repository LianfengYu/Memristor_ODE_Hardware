import numpy as np

safety = 0.8
facmax = 2
facmin = 0.5

def step_ctrl(y0, y1, e, rtol, atol, order):
    
    '''
    Adaptive stepsize control
    '''
    
    dimension = len(y0)
    sc = np.zeros(dimension)
    for i in range(dimension):
        sc[i] = atol + max(y0[i], y1[i]) * rtol
    err = 0
    for i in range(dimension):
        err += (e[i]/sc[i])**2
    err = (err/dimension)**0.5
    
    factor = max(facmin, safety * (1/err)**(1/(order)))
    factor = min(facmax, factor)
    
    if err <= 1:
        accept = True
    else:
        accept = False
    
    return factor, accept

def start_step(x, y0, func, atol, rtol, order):
    
    '''
    Choose the right start step
    '''
    
    dimension = len(y0)
    sc = np.zeros(dimension)
    for i in range(dimension):
        sc[i] = atol + abs(y0[i]) * rtol
    f0 = func(x, y0)
    d0 = 0
    d1 = 0
    for i in range(dimension):
        d0 += (y0[i]/sc[i])**2
        d1 += (f0[i]/sc[i])**2
    d0 = (d0/dimension)**0.5
    d1 = (d1/dimension)**0.5   
    if d0 < 1e-5 or d1 < 1e-5:
        h0 = 1e-6
    else:
        h0 = 0.01 * (d0/d1)
    
    y1 = y0 + h0 * f0 
    f1 = func(x + h0, y1)    
    d2 = 0
    for i in range(dimension):
        d2 += ((f1[i]-f0[i])/sc[i])**2
    d2 = (d2/dimension)**0.5 / h0
    if max(d1, d2) <= 1e-15:
        h1 = max(1e-6, h0 * 1e-3)
    else:
        h1 = (0.01/max(d1, d2))**(1/(order+1))
    
    h = min(100 * h0, h1)
    
    return h

            
                
                
        
        
            
            
        