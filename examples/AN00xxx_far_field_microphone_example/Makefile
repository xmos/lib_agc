TARGET = SMART-MIC-4-TILE-1V0
APP_NAME =
USED_MODULES = lib_i2c lib_i2s lib_mic_array \
               lib_mic_array_board_support lib_src \
               lib_agc lib_noise_suppression_newnew \
               lib_beamsteering lib_vad

XCC_FLAGS = -O2 -g -fxscope -Wunused -Wno-timing -report
XCORE_ARM_PROJECT = 0
VERBOSE = 0

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
