import numpy as np
from sklearn.metrics import *

def calculate_mse(s1, s2):
    
    '''
    Calculate the mean square error
    '''
    
    if s1.shape != s2.shape:
        raise Exception("Vector must be of the same shape!")
    return mean_squared_error(s1, s2)

def calculate_re(ypre, ytrue):
    
    '''
    Calculate the relative error
    '''
    
    return float((ypre-ytrue)/ytrue)

def calculate_ae(ypre, ytrue):
    
    '''
    Calculate the absolute error
    '''
    
    return float(ypre-ytrue)
