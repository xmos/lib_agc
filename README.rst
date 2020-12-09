Automatic Gain Control Library
==============================

Summary
-------

This library implements an automatic gain control algorithm. Given a stream
of audio samples in the time domain, it dynamically adapts the gain such that
voice content maintains a specified output level.

Features
........

  * Supports multiple audio channels.
  * Configurable adaptive or fixed gain.
  * Configurable initial and maximum gain values.
  * Soft limiter applied to output.

Software version and dependencies
.................................

The CHANGELOG contains information about the current and previous versions.
For a list of direct dependencies, look for DEPENDENT_MODULES in lib_agc/module_build_info.
