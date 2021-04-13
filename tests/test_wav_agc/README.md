# test_wav_agc test application

This example builds the test_wav_agc.xe application

## Prerequisites for building

[XMOS Toolchain 15.0.3](https://www.xmos.com/software/tools/) or newer.

Install [CMake](https://cmake.org/download/) version 3.13 or newer.

## Building for xCORE

Set environment variable for lib_agc path:

    > export AGC_PATH=<path to lib_agc>

cd to lib_agc/tests/test_wav_agc

Run cmake and build

    > cmake . -B build
    > cd build
    > make

## Run on hardware

Ensure your XCORE AI EXPLORER board is powered up and connected to the XTAG debugger.
Make sure the input.wav file is copied into the build directory

    > xrun --xscope test_wav_agc.xe


You should see an output.wav file generated with the test_wav_agc output. 
