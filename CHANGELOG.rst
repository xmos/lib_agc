AGC library change log
======================

8.2.0
-----

  * ADDED: AGC loss-control commands
  * CHANGED: Use XMOS Public Licence Version 1

8.1.0
-----

  * CHANGED: updated hard-coded values used in loss control algorithm
  * ADDED: Support for building and running tests on XS3 target

8.0.0
-----

  * ADDED: Control commands map and handler
  * ADDED: Control parameters for min gain, adapt on vad and soft clipping

7.0.2
-----

  * CHANGED: Pin Python package versions
  * REMOVED: not necessary cpanfile

7.0.1
-----

  * CHANGED: Use virtualenv instead of pipenv.

7.0.0
-----

  * CHANGED: Loss control requires an AEC correlation value.
  * CHANGED: Removed unnecessary internal state in agc_ch_state_t.
  * CHANGED: Switch from pipenv to virtualenv
  * CHANGED: Update Jenkins shared library to 0.14.1

6.0.2
-----

  * CHANGED: Further updates to loss control parameters.

6.0.1
-----

  * CHANGED: Updated loss control parameters for communications channel.

6.0.0
-----

  * ADDED: support for loss control.
  * UPDATED: API updated to accept reference audio frame power.
  * CHANGED: Update dependency on lib_dsp to v6.0.0

  * Changes to dependencies:

    - lib_logging: Added dependency 3.0.0

5.1.0
-----

  * CHANGED: Update .json config for test_wav_agc due to lib_vtb v7.1.0

5.0.0
-----

  * CHANGED: Build files updated to support new "xcommon" behaviour in xwaf.

4.1.0
-----

  * CHANGED: Use pipenv to set up python environment.
  * CHANGED: Get wavfile processing related functions from audio_wav_utils in
    audio_test_tools

  * Changes to dependencies:

    - lib_ai: Added dependency 0.0.1

    - lib_vad: Added dependency 0.4.2

4.0.0
-----

  * ADDED: support for JSON config file
  * UPDATED: Removed VAD threshold. API updated to accept VAD flag instead.

3.1.1
-----

  * CHANGED: VAD threshold increased to 80%.

3.1.0
-----

  * CHANGED: upper and lower threshold parameters in python from dB to non-dB.

3.0.0
-----

  * ADDED: Range constrainer like functionality within AGC.
  * ADDED: Parameters for upper and lower desired voice level thresholds.

2.3.0
-----

  * ADDED: Pipfile + setup.py for pipenv support
  * ADDED: Python 3 support

2.2.0
-----

  * CHANGED: Updated lib_voice_toolbox dependency to v5.0.0

2.1.0
-----

  * CHANGE: Fixed channel index bug.
  * CHANGE: Extended unit tests.

2.0.0
-----

  * CHANGED: AGC adaptive algorithm.
  * CHANGED: Processing a frame requires VAD.
  * CHANGED: Renamed AGC_CHANNELS to AGC_INPUT_CHANNELS.
  * ADDED: Parameter get and set functions.
  * ADDED: Initial AGC config structure.

1.0.0
-----

  * ADDED: Multiple channel support
  * ADDED: Gain and adaption control

0.0.3
-----

  * ADDED: Unit tests
  * ADDED: Python and XC implementations
  * ADDED: Jenkinsfile

0.0.2
-----

  * ADDED: Support for xmake
  * Copyrights, licences and dependencies

  * Changes to dependencies:

    - lib_dsp: Added dependency 4.1.0

    - lib_voice_toolbox: Added dependency 1.0.2

0.0.1
-----

  * Initial version

