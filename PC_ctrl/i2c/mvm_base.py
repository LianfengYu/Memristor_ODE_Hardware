from __future__ import division, with_statement, print_function
# from aardvark_api import *
from i2c.aardvark_py import *
from i2c.base import *
from i2c.mvm_base import *
import matplotlib.pyplot as plt
import numpy as np
import time
# import aardvark_api.python

import math
import time
import csv

TRY_MAX = 1000
BL_LENGTH = 32
WL_LENGTH = 36
ADC_RATE = 4.096/65535
READ_BIAS = 0
READ_SLOPE = 16.56442
READ_INTERCEPT = 2.34346
MVM_SLOPE = 50.36268
MVM_INTERCEPT = 2.26158

scale = 20.5/6.79

def find_start(addr, handle):
    if -4 <= addr <= -1:
        dataTest = array('B', [0x00])
        Fail = Communication_Write(handle=handle, data=dataTest, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
        if Fail:
            print("Error! Find Start Fail.")
        Fail = Communication_Read(handle=handle, data=dataTest, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Find Start Fail.")
        s = list(format(dataTest[0], '#0'+str(6)+'b')[2:])
        s[addr] = str(1-int(s[addr]))  
        s = ''.join(s)
    else:
        aa_close(handle)
        raise Exception("Error! No such addr for start and finish signal.")    
    return s

def find_finish(s, handle):
    t = 0
    finish = [-1]
    while finish[0] != int(s, 2):
        t = t + 1
        finish = array('B', [0x00])
        Fail = Communication_Write(handle=handle, data=finish, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
        if Fail:
            print("Error! Find Finish Fail.")
        Fail = Communication_Read(handle=handle, data=finish, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Find Finish Fail.")
        if t == TRY_MAX:
            aa_close(handle)
            raise Exception("Error! Finish Time Out.")   
    return

def mode_def(m, handle, bitrate):  
    '''
    0 -> wv_read, 1 -> wv_write, 2 -> mvm_a, 3 -> mvm_d (not used), 4 -> p_read, 5 -> mvm_h
    '''      
    if 0 <= m <= 5:
        M = m
    else:
        print("Mode only accept for 0 ~ 5! Mode is set to 0")
        M = 0     
    
    dataInM = array('B', [0x02, M])
    Fail = Communication_Write(handle=handle, data=dataInM, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Mode Write Fail.")  
    return False
 
def chip_def(c, handle, bitrate):    
    if 0 <= c <= 5:
        C = c
    else:
        print("Chip only accept for 0 ~ 5! Chip is set to 0")
        C = 0     
    
    dataInM = array('B', [0x1b, M])
    Fail = Communication_Write(handle=handle, data=dataInM, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Chip Select Fail.")  
    return False
   
def read_def(r, handle, bitrate):  
    '''
    0 -> mvm, 1 -> single cell
    '''      
    if 0 <= r <= 1:
        M = r
    else:
        print("Mode only accept for 0 ~ 1! Mode is set to 0")
        M = 0     
    
    dataInM = array('B', [0x1a, M])
    Fail = Communication_Write(handle=handle, data=dataInM, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Read Mode Write Fail.")  
    return False
    

def wl_def(wl, handle, bitrate):
    if 0 <= wl <= 35:
        WL = wl
    else:
        print("WL only accept for 0 ~ 35! WL is set to 0")
        WL = 0     
        
    dataInWL = array('B', [0x04, WL])    
    Fail = Communication_Write(handle=handle, data=dataInWL, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! WL Write Fail.") 

    return False

def step_def(bl, handle, bitrate):
    if 0 <= bl <= 31:
        BL = bl
    else:
        print("BL only accept for 0 ~ 31! BL is set to 0")
        BL = 0  
        
    dataInBL = array('B', [0x03, BL])
    Fail = Communication_Write(handle=handle, data=dataInBL, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! BL Write Fail.")      
    return

def bl_def(bl, handle, bitrate):
    if type(bl) == int:
        if 0 <= bl <= 31:
            BL = bl
        else:
            print("BL only accept for 0 ~ 31! BL is set to 0")
            BL = 0  
            
        dataInBL = array('B', [0x03, BL])
        Fail = Communication_Write(handle=handle, data=dataInBL, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! BL Write Fail.")      
            
        bl = [bl]

    open_row = len(bl)         
    for i in range(open_row):
        if bl[i] not in range(32):
            raise Exception("Error! Row Addr only accept 0 ~ 31.")
                
    r = list(format(0, '#0'+str(10)+'b')[2:])
    sa = np.zeros(8)  
    for i in range(open_row):
        addr = 7 - math.floor(bl[i] / 4)
        if r[addr] == '0':
            r[addr] = '1'
            sa[7 - addr] = bl[i] % 4
        else:
            print("Error! Only accept 4 choose 1.")
            return
    r = ''.join(r)
    sa1 = ''
    sa2 = ''
    for i in range(4):
        sa1 += format(int(sa[i]), '#0'+str(4)+'b')[2:]
        sa2 += format(int(sa[i+4]), '#0'+str(4)+'b')[2:]
    
    dataInR = array('B', [0x07, int(r, 2)])     # how many rows to open
    Fail = Communication_Write(handle=handle, data=dataInR, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Open Row Fail.")  
        
    dataInSA1 = array('B', [0x08, int(sa1, 2)])     # which row to open
    dataInSA2 = array('B', [0x09, int(sa2, 2)])     # which row to open 
    Fail = Communication_Write(handle=handle, data=dataInSA1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Open First Row Fail.")   
    Fail = Communication_Write(handle=handle, data=dataInSA2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Open Last Row Fail.")  
        
    if open_row == 1:
        input_def(r, [0.2], handle, bitrate)
        
    return r    

def input_def(r, input_list, handle, bitrate):
    bias = 0
    cr = np.zeros(8)
    mode_def(2, handle, bitrate)
    for i in range(8):
        cr[i] = r[7-i]
    if len(input_list) != int(cr.sum()):
        print("Error! Only open {} rows and require {} input.".format(int(cr.sum()), int(cr.sum())))
        return
    
    indac = np.empty(12, dtype='<U10')
    addr = 0
    for i in range(8):
        if cr[i] == 1:
            if input_list[addr] > 0.2:
                odac = 0
                print("Input only accept for 0 ~ 0.2V)! Input is set to 0V")
            else:
                odac = input_list[addr]
            odac = math.floor((odac + bias)/2.5*4096)
            addr += 1
        else:
            odac = math.floor(bias/2.5*4096)
    
        bodac = format(int(odac), '#0'+str(14)+'b')[2:]
        if i % 2 == 0:
            indac[int(1.5*i)] += bodac[0:8]
            indac[int(1.5*i)+1] += bodac[8:12]
        else:
            indac[int(1.5*(i-1)+1)] += bodac[0:4]
            indac[int(1.5*(i-1)+2)] += bodac[4:12]
        
    dataInDAC = []
    #print(indac)
    for i in range(12):
        dataInDAC.append(array('B', [0x0a+i, int(indac[i], 2)]))      
    
    for i in range(12):
        Fail = Communication_Write(handle=handle, data=dataInDAC[i], DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Write in DAC Fail.")   
            
    s = find_start(-2, handle)
    dataInS = array('B', [0x01, int(s, 2)])     # input DAC start
    Fail = Communication_Write(handle=handle, data=dataInS, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Input DAC Start Fail.")   
    
    find_finish(s, handle)
    
    return

'''
mode = 0: mvm   mode = 1: read
'''
def read(handle, bitrate, mode = 1):

    mode_def(0, handle, bitrate)
    read_def(mode, handle, bitrate)
  
    s = find_start(-1, handle)
    dataInS = array('B', [0x01, int(s, 2)])     # read ADC start
    Fail = Communication_Write(handle=handle, data=dataInS, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Start Read Fail.")  
    
    find_finish(s, handle)
    
    read_data1 = array('B', [0x1c])
    read_data2 = array('B', [0x1d])
    Fail = Communication_Write(handle=handle, data=read_data1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
    if Fail:
        print("Error! Read ADC Fail.")
    Fail = Communication_Read(handle=handle, data=read_data1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Read ADC Fail.")
    Fail = Communication_Write(handle=handle, data=read_data2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
    if Fail:
        print("Error! Read ADC Fail.")
    Fail = Communication_Read(handle=handle, data=read_data2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Read ADC Fail.")    

    read_data = (read_data1[0] << 8) + read_data2[0]

    if mode == 1:
        return (read_data * ADC_RATE) * READ_SLOPE + READ_INTERCEPT
    elif mode == 0:
        return (read_data * ADC_RATE) * MVM_SLOPE + MVM_INTERCEPT
    else:
        print("Error! Invalid Read Mode.")  
        return

def parallel_read(handle, bitrate, mode = 1):

    mode_def(4, handle, bitrate)
    read_def(mode, handle, bitrate)
  
    s = find_start(-1, handle)
    dataInS = array('B', [0x01, int(s, 2)])     # read ADC start
    Fail = Communication_Write(handle=handle, data=dataInS, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Start Read Fail.")  
    
    find_finish(s, handle)
    
    read_data = []
    for i in range(8):
        read_data1 = array('B', [0x1c+2*i])
        read_data2 = array('B', [0x1d+2*i+1])
        Fail = Communication_Write(handle=handle, data=read_data1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
        if Fail:
            print("Error! Read ADC Fail.")
        Fail = Communication_Read(handle=handle, data=read_data1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Read ADC Fail.")
        Fail = Communication_Write(handle=handle, data=read_data2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
        if Fail:
            print("Error! Read ADC Fail.")
        Fail = Communication_Read(handle=handle, data=read_data2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Read ADC Fail.")    
    
        read_data.append((read_data1[0] << 8) + read_data2[0]) 

    if mode == 1:
        return (read_data * ADC_RATE) * READ_SLOPE + READ_INTERCEPT
    elif mode == 0:
        return (read_data * ADC_RATE) * MVM_SLOPE + MVM_INTERCEPT
    else:
        print("Error! Invalid Read Mode.")  
        return

def step_read(handle, bitrate, mode = 1):

    mode_def(5, handle, bitrate)
  
    s = find_start(-1, handle)
    dataInS = array('B', [0x01, int(s, 2)])     # read ADC start
    Fail = Communication_Write(handle=handle, data=dataInS, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Start Read Fail.")  
    
    find_finish(s, handle)
    
    read_data = []
    for i in range(8):
        read_data1 = array('B', [0x1c+2*i])
        read_data2 = array('B', [0x1d+2*i+1])
        Fail = Communication_Write(handle=handle, data=read_data1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
        if Fail:
            print("Error! Read ADC Fail.")
        Fail = Communication_Read(handle=handle, data=read_data1, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Read ADC Fail.")
        Fail = Communication_Write(handle=handle, data=read_data2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_STOP)
        if Fail:
            print("Error! Read ADC Fail.")
        Fail = Communication_Read(handle=handle, data=read_data2, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
        if Fail:
            print("Error! Read ADC Fail.")    
    
        read_data.append((read_data1[0] << 8) + read_data2[0]) 

    if mode == 1:
        return (read_data * ADC_RATE - READ_INTERCEPT)/READ_SLOPE
    elif mode == 0:
        return (read_data * ADC_RATE - MVM_INTERCEPT)/MVM_SLOPE
    else:
        print("Error! Invalid Read Mode.")  
        return

def write(direction, pulse_w, pulse_h, handle, bitrate):
    '''
    direction: 1 -> set, 2 -> reset, 3 -> forming
    pulse_w: ns (20ns)
    pulse_h: V
    '''
    mode_def(1, handle, bitrate)
    if 1 <= direction <= 3:
        D = direction
    else:
        print("Direction only accept for 0 ~ 3! Direction is set to 0")
        D = 0
    if pulse_w % 20 == 0 and 0 < pulse_w < 1000:
        W = int(pulse_w / 20)
    else:
        print("Pulse_w only accept for multiples of 20 (20 ~ 980ns)! Pulse_w is set to 20ns")
        W = 1   
    if 0 <= pulse_h < 5:
        H = math.floor(pulse_h/5*256)
    else:
        print("Pulse_h only accept for 0 ~ 5V)! Pulse_h is set to 0V")
        H = 0
    
    dataInW = array('B', [0x06, (D<<6)+W])
    dataInH = array('B', [0x05, H])
    Fail = Communication_Write(handle=handle, data=dataInW, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Pulse_w Write Fail.")      
    Fail = Communication_Write(handle=handle, data=dataInH, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Pulse_h Write Fail.") 
    
    s = find_start(-3, handle)
    dataInS = array('B', [0x01, int(s, 2)])     # write DAC start
    Fail = Communication_Write(handle=handle, data=dataInS, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Write DAC Start Fail.")     
    find_finish(s, handle) 

    s = list(s)
    s[-4] = str(1-int(s[-4]))
    s = ''.join(s)
    dataInS = array('B', [0x01, int(s, 2)])     # pulse start
    Fail = Communication_Write(handle=handle, data=dataInS, DEVICE=DEVICE_COMM, mode=AA_I2C_NO_FLAGS)
    if Fail:
        print("Error! Pulse Start Fail.")  
    find_finish(s, handle) 

    return False