#!/usr/bin/env python
import argparse
import os.path
import numpy as np
import random
from array import array
from scipy.io import wavfile

sample_rate, data = wavfile.read("/Users/henk/sound_sample.wav")

#data = data[:48000]

if sample_rate != 48000:
    print "Error - not 48000 Hz"

error = 0
for insample in data:
    thesample = insample / 65536.0 + error
    sample = thesample
    if sample < 0:
        sample = -sample
        sign = 128
    else:
        sign = 0
    if sample == 32768:
        sample = 32767
    if sample >= 16384:
        exp = 7
        sample /= 128.0
    elif sample >= 8192:
        exp = 6
        sample /= 64.0
    elif sample >= 4096:
        exp = 5
        sample /= 32.0
    elif sample >= 2048:
        exp = 4
        sample /= 16.0
    elif sample >= 1024:
        exp = 3
        sample /= 8.0
    elif sample >= 512:
        exp = 2
        sample /= 4.0
    elif sample >= 256:
        exp = 1
        sample /= 2.0
    else:
        exp = 0
        sample /= 1.0
    sample /= 8.0

    outsample = int(sample + random.triangular(-1.0, 1.0, 0.0))

    if outsample > 31:
        outsample = 31
    elif outsample < 16:
        outsample = 16

    encoded = sign + exp * 16 + (outsample - 16)

    outencoded = encoded
    outnegative = encoded >= 128
    if outnegative:
        encoded -= 128
    outexp = encoded >> 4
    outmant = (encoded & 15) + 16
    outval = outmant << (outexp+3)
    if outnegative:
        outval = -outval
        
    error = thesample - outval;
                
    print outsample, insample, outval*65536, outencoded
    
