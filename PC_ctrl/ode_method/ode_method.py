import numpy as np

'''
Runge-Kutta parameters are taken from
https://en.wikipedia.org/wiki/List_of_Runge%E2%80%93Kutta_methods
'''

def abc_to_rram(k,A,B,B_,C,bit):
    if bit == 0:
        rram = np.transpose(np.row_stack((A,B,B)))
    else: 
        rram = np.transpose(np.row_stack((A,B,B-B_)))
    return rram

def quant(A, B, B_, C, bit):
    if bit == 0:
        return A, B, B_, C
    else:
        qmax = max(A.max(), B.max(), B_.max(), C.max())
        qmin = min(A.min(), B.min(), B_.min(), C.min())
        upper = 2**bit - 1
        slope = upper/(qmax - qmin)
        intercept = - (upper * qmin)/(qmax - qmin)
        A = (np.floor(A * slope + intercept) - intercept)/slope
        B = (np.floor(B * slope + intercept) - intercept)/slope
        B_ = (np.floor(B_ * slope + intercept) - intercept)/slope
        C = (np.floor(C * slope + intercept) - intercept)/slope
    return A, B, B_, C

def ex_Euler(rram = True, bit = 0):
    order = 1
    k = 1
    mode = 'explicit'

    A = np.array([0.])
    B = np.array([1.])
    B_ = np.array([1.])
    C = np.array([0.])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

def im_Euler(rram = True, bit = 0):
    order = 1
    k = 1
    mode = 'explicit'

    A = np.array([1.])
    B = np.array([1.])
    B_ = np.array([1.])
    C = np.array([1.])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

def ex_Heun(rram = True, bit = 0):
    order = 2
    k = 2
    mode = 'explicit'

    A = np.array([[0.,0.],[1.,0.]])
    B = np.array([0.5,0.5])
    B_ = np.array([1.,0.])
    C = np.array([0.,1.])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

def im_Heun(rram = True, bit = 0): # Lobatto IIIA
    order = 2
    k = 2
    mode = 'implicit'
    
    A = np.array([[0.,0.],[0.5,0.5]])
    B = np.array([0.5,0.5])
    B_ = np.array([1.,0.])
    C = np.array([0.,1.])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram= abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

# The Bogacki–Shampine method
def ode23(rram = True, bit = 0):
    order = 3
    k = 4
    mode = 'explicit'

    A = np.zeros((k, k))
    A[1][0] = 1./2.     # a21
    A[2][1] = 3./4.     # a32
    A[3][0] = 2./9.     # a41
    A[3][1] = 1./3.     # a42
    A[3][2] = 4./9.     # a43
    B = np.array([2./9.,1./3.,4./9.,0.])
    B_ = np.array([7./24.,1./4.,1./3.,1./8.])
    C = np.array([0.,1./2.,3./4.,1.])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

# The Dormand–Prince method
def ode45(rram = True, bit = 0):
    order = 5
    k = 7
    mode = 'explicit'
    
    A = np.zeros((k, k))
    A[1][0] = 1./5.         # a21
    A[2][0] = 3./40.        # a31
    A[2][1] = 9./40.        # a32
    A[3][0] = 44./45.       # a41
    A[3][1] = -56./15.      # a42
    A[3][2] = 32./9.        # a43
    A[4][0] = 19372./6561.  # a51
    A[4][1] = -25360./2187. # a52
    A[4][2] = 64448./6561.  # a53
    A[4][3] = -212./729.    # a54
    A[5][0] = 9017./3168.   # a61
    A[5][1] = -355./33.     # a62
    A[5][2] = 46732./5247.  # a63
    A[5][3] = 49./176.      # a64
    A[5][4] = -5103./18656. # a65
    A[6][0] = 35./384.      # a71
    A[6][1] = 0.            # a72
    A[6][2] = 500./1113.    # a73
    A[6][3] = 125./192.     # a74
    A[6][4] = -2187./6784.  # a75
    A[6][5] = 11./84.       # a76  
    B = np.array([35./384.,0.,500./1113.,125./192.,-2187./6784.,11./84.,0.])
    B_ = np.array([5179./57600.,0.,7571./16695.,393./640.,-92097./339200.,187./2100.,1./40.])
    C = np.array([0.,1./5.,3./10.,4./5.,8./9.,1.,1.])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

# Gauss–Legendre method, order=4, but stage=2
def GL2(rram = True, bit = 0):
    order = 4
    k = 2
    mode = 'implicit'
    
    A = np.array([[1/4, 1./4.-1./6.*(3.**0.5)], [1./4.+1./6.*(3.**0.5), 1/4]])
    B = np.array([1/2,1/2])
    B_ = np.array([1./2.+1./2.*(3.**0.5), 1./2.-1./2.*(3.**0.5)])
    C = np.array([1./2.-1./6.*(3.**0.5), 1./2.+1./6.*(3.**0.5)])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode
    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode

def GL3(rram = True, bit = 0):
    order = 6
    k = 3  
    mode = 'implicit'
         
    A = np.array([[5/36, 2/9-1/15*(15**0.5), 5/36-1/30*(15**0.5)], 
                  [5/36+1/24*(15**0.5), 2/9,5/36-1/24*(15**0.5)], 
                  [5/36+1/30*(15**0.5), 2/9+1/15*(15**0.5),5/36]])
    B = np.array([5/18,4/9,5/18])
    B_ = np.array([-5/6,8/3,-5/6])
    C = np.array([1/2-1/10*(15**0.5), 1/2, 1/2+1/10*(15**0.5)])
    if not rram:
        A, B, B_, C = quant(A, B, B_, C, bit)
        return k, order, A, B, B_, C, mode

    else:
        rram = abc_to_rram(k,A,B,B_,C,bit)
        return k, order, rram, C, mode
