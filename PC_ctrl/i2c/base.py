from __future__ import division, with_statement, print_function
# from aardvark_api import *
from i2c.aardvark_py import *
# import aardvark_api.python

I2C_BITRATE =  100
DEVICE_COMM = 0x6C

def Communication_Init(mode = AA_CONFIG_GPIO_I2C, pullup = AA_I2C_PULLUP_NONE, bitrate = I2C_BITRATE):
    (num, ports, unique_ids) = aa_find_devices_ext(16, 16)
    port = ports[num - 1]
    handle = aa_open(port)
    aa_configure(handle,  mode)
    aa_i2c_pullup(handle, pullup)
    bitrate = aa_i2c_bitrate(handle, bitrate)
    return handle, bitrate

def Communication_Write(handle, data, DEVICE, mode, Limit = 10):
    TryCount = 0
    result = 0
    while result <= 0 and TryCount <= Limit:
        result = aa_i2c_write(handle, DEVICE, mode, data)
        TryCount += 1
        # aa_sleep_ms(1)
    if TryCount >= Limit:
        print("Write Error!")
    return TryCount >= Limit

def Communication_Read(handle, data, DEVICE, mode, Limit = 10):
    TryCount = 0
    result = 0
    while result <= 0 and TryCount <= Limit:
        result, read_byte = aa_i2c_read(handle, DEVICE, mode, data)
        TryCount += 1
    if TryCount >= Limit:
        print("Read Error!")
    return TryCount >= Limit

