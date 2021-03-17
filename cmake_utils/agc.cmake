file(GLOB_RECURSE LIB_AGC_SOURCES       "$ENV{AGC_PATH}/lib_agc/src/*.xc")
file(GLOB_RECURSE LIB_VAD_SOURCES       "$ENV{AGC_PATH}/../lib_vad/lib_vad/src/*.xc")
file(GLOB_RECURSE LIB_DSP_SOURCES       "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/bfp/*.S"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/bfp/*.xc"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/fft/*.S"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/fft/*.xc"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/dsp_dct.xc"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/dsp_math.c"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/dsp_logistics.S"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/dsp_biquad.S"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/src/dsp_tables.c")
file(GLOB_RECURSE LIB_VTB_SOURCES       "$ENV{AGC_PATH}/../lib_voice_toolbox/lib_voice_toolbox/src/bfp/*.xc"
                                        "$ENV{AGC_PATH}/../lib_voice_toolbox/lib_voice_toolbox/src/bfp/*.S")
set_source_files_properties(${LIB_VTB_SOURCES} PROPERTIES COMPILE_FLAGS -O2)
file(GLOB_RECURSE LIB_AI_SOURCES       "$ENV{AGC_PATH}/../lib_ai/lib_ai/src/*.xc"
                                        "$ENV{AGC_PATH}/../lib_ai/ai/src/*.S"
                                        "$ENV{AGC_PATH}/../lib_ai/ai/src/*.c")
file(GLOB_RECURSE AUDIO_TEST_TOOLS_SOURCES        "$ENV{AGC_PATH}/../audio_test_tools/audio_test_tools/src/*.xc"
    "$ENV{AGC_PATH}/../audio_test_tools/audio_test_tools/src/*.S")

set(AGC_SRCS_ALL                        ${LIB_AGC_SOURCES} 
                                        ${LIB_VAD_SOURCES} 
                                        ${LIB_DSP_SOURCES} 
                                        ${LIB_VTB_SOURCES} 
                                        ${LIB_AI_SOURCES}
                                        ${AUDIO_TEST_TOOLS_SOURCES}) 


set(AGC_INCLUDES_ALL                    "$ENV{AGC_PATH}/lib_agc/api"
                                        "$ENV{AGC_PATH}/lib_agc/src"
                                        "$ENV{AGC_PATH}/../lib_vad/lib_vad/api"
                                        "$ENV{AGC_PATH}/../lib_dsp/lib_dsp/api"
                                        "$ENV{AGC_PATH}/../lib_voice_toolbox/lib_voice_toolbox/api"
                                        "$ENV{AGC_PATH}/../audio_test_tools/audio_test_tools/api"
                                        "$ENV{AGC_PATH}/../lib_ai/lib_ai/api")

#Add all paths from sources to includes. It's a bit overkill but still builds fast :)
FOREACH(SRC ${AGC_SRCS_ALL})
    get_filename_component(DIR ${SRC} DIRECTORY)
    list(APPEND AGC_INCLUDES_ALL ${DIR})
ENDFOREACH()

#message( ${VFE_SRCS_ALL})
#message( ${VFE_INCLUDES_ALL})
