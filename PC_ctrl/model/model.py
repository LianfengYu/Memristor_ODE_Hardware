import numpy as np
import random

stepcnt = 6
stepfac = 0.05
max_factor = 5e-5
min_factor = 1e-8
ber = 0

gmax = 50
gmin = 0

def model_map(rram, bit):
    if bit == 0:
        wmax = rram.max()
        wmin = rram.min()
        wm = max(abs(wmax), abs(wmin))
        scale = (gmax - gmin) / wm
        rram1 = rram.copy()
        rram2 = rram.copy()
        
        rram1[rram1>=0] = gmax
        rram1[rram1<0] = gmax * (1+rram1[rram1<0]/wm)
        rram2[rram2>=0] = gmax * (1-rram2[rram2>=0]/wm)
        rram2[rram2<0] = gmax
        
        rram = (rram1 - rram2)
        return rram, scale
    else:
        qmax = rram.max()
        qmin = rram.min()
        upper = 2**bit - 1
        slope = upper/(qmax - qmin)
        intercept = - (upper * qmin)/(qmax - qmin)
        rram = np.floor(rram * slope + intercept) - 2**(bit-1)
        for i in range(rram.shape[0]):
            for j in range(rram.shape[1]):             
                bits = int2bin(int(rram[i][j]), bit)
                flipped_bits = flip_bits(bits, ber)
                rv = bin2int(flipped_bits)
                rram[i][j] = (rv + 2**(bit-1) - intercept)/slope
        return rram, 1

def read(rram, bit):
    if bit == 0:
        with open("./model/read_noise.txt", "r") as f:
            lines = f.readlines()
        rram += float(random.choice(lines).strip())
        return rram
    else:
        return rram

def int2bin(v, width):
    if v < 0:
        v = (1 << width) + v
    v = v % (1 << width)
    return format(v, f'0{width}b')

def bin2int(bits):
    width = len(bits)
    val = int(bits, 2)
    if bits[0] == '1':
        val -= (1 << width)
    return val

def flip_bits(bits, e):
    flipped = []
    for bit in bits:
        if random.random() < e:
            flipped.append('1' if bit == '0' else '0')
        else:
            flipped.append(bit)
    return ''.join(flipped)
