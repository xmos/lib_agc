Automatic gain control library
==============================

Summary
-------

This library implements an adaptive gain control algorithm. Given a stream
of audio samples in the time domain (in block floating point format), it
dynamically adapts the gain so that it has a reasonably constant output level.

Features
........

  * Settable desired output energy
  * Settable minimum and maximum gain
  * Settable up and down rates for the gain
  * Settable delay before increasing gain
  * Settable window size, look-ahead, and history
  * Multiple instances supported

Typical Resource Usage
......................

  .. resusage:: 
     ...

Software version and dependencies
.................................

  .. libdeps:: lib_dsp

Related application notes
.........................

The following application notes use this library:

  * ANxxxx - Example use of gain control and noise suppression
