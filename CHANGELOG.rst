AGC library change log
======================

4.0.0
-----

  * ADDED: support for JSON config file
  * UPDATED: Removed VAD threshold. API updated to accept VAD flag instead.

3.1.1
-----

  * CHANGED: VAD threshold increased to 80%.

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

