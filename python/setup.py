# Copyright 2019-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import setuptools

# Another repository might depend on python code defined in this one.  The
# procedure to set up a suitable python environment for that repository may
# pip-install this one as editable using this setup.py file.  To minimise the
# chance of version conflicts while ensuring a minimal degree of conformity,
# the 3rd-party modules listed here require the same major version and at
# least the same minor version as specified in the requirements.txt file.
# The same modules should appear in the requirements.txt file as given below.
setuptools.setup(
    name='lib_agc',
    packages=setuptools.find_packages(),
    install_requires=[
        'flake8~=3.8',
        'matplotlib~=3.3',
        'numpy~=1.18',
        'pylint~=2.5',
        'pytest~=6.0',
        'pytest-xdist~=1.34',
        'scipy~=1.4',
        'webrtcvad~=2.0',
        'audio_test_tools',
        'lib_vad',
        'lib_voice_toolbox',
    ],
    dependency_links=[
        './../../audio_test_tools/python#egg=audio_test_tools',
        './../../lib_voice_toolbox#egg=lib_voice_toolbox',
        './../../lib_vad/python#egg=lib_vad',
    ],
)
