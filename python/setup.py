# Copyright (c) 2019-2020, XMOS Ltd, All rights reserved
import setuptools

setuptools.setup(
    name='lib_agc',
    packages=setuptools.find_packages(),
    install_requires=[
        'audio_test_tools',
        'lib_vad',
        'lib_voice_toolbox',
        'numpy',
        'scipy',
        'matplotlib',
        'pytest',
        'pytest-xdist',
        'webrtcvad',
    ],
    dependency_links=[
        './../../audio_test_tools/python#egg=audio_test_tools',
        './../../lib_vad/python#egg=lib_vad',
        './../../lib_voice_toolbox#egg=lib_voice_toolbox',
    ],
)
