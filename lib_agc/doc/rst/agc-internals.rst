The Automatic Gain Controller comprises a function that processes a block of
time domain data at a time, changing the gain of the block of data so that
the output energy is fairly constant over longer periods of time.

At the core of the AGC is the ``agc_state_t`` structure that holds data
related to the AGC. For each AGC that is required one of these structures
should be declared, and initialised using the ``agc_init_state`` function.
The initialisation enables a few parameters to be set, including

* The frame length (the number of samples in a block that are operated on
  during each call).

* The desired energy output level (in dB of whole scale),

* The number of future frames to take into account when computing the
  energy.

* The number of past frames to take into account when computing the energy.

After the structure is initialised, each frame is processed using a call to
``agc_process_frame``. This function requires, in addition to the ``agc_state_t``
structure a block of samples of the right length, the number of bits that
the samples have been shifted left by (by other parts of the processing
chain, set to zero if the data is just integers)
and two arrays of integers that are used to store future and historic data.

The AGC has several other parameters that can be set that affect the rate
at which the gain is decreased (if the signal is too strong; this is
sometimes known as the attach), the rate at which the gain is increased (if
the signal is too weak; this is sometimes known as the decay), the grace
period in milliseconds before the gain starts to increase, and limits on
the gain. The default values for those are a good starting point, and
function calls can be made to, statically or dynamically, change these
defaults.

One main trade-off that is to be made is in the time over which the AGC
operates versus the length of the data that is available for computing the
energy. Looking ahead a bit can be quite good when looking at the energy,
as the AGC can start to decrease early when a loud sound appears. But
looking ahead inevitably adds to the latency.

Simple usage
............

In its simplest form the AGC can be used as follows::

  agc_state_t a;

  agc_init_state(a, 128,   // frame size
                    0      // db, initial gain
                    -6     // db, desired energy
                    0, 0); // No lookahead or past energy

  while(1) {
    int32_t samples[128];
    ... get_data(samples) ...
    agc_process_frame(a, samples, // sample data
                      0,          // bits headroom that have been removed
                      null,       // no look ahead
                      null);      // no energy buffer either
    ... put_data(samples) ...
  }


Usage with look-ahead and use of past energy
............................................

A more complex example uses both a look ahead memory and an energy buffer
to remember past frames. The size of the energy buffer should be the number
of look-ahead frames, plus the number of past frames, plus 1. The size of
the sample buffer should be the number of look-ahead frames times the
frame-size plus 1 (it has to store all the look-ahead samples, plus one
shift value for each look-ahead frame). In this case the ``agc_process_frame``
function will delay the signal with two frames; that is, the output data
will be two frames older than the input data to agc_process_frame::

  agc_state_t a;
  uint32_t energy_memory[2 + 1 + 2];
  int32_t  sample_memory[2*(128+1)];

  agc_init_state(a, 128,   // frame size
                    0      // db, initial gain
                    -6     // db, desired energy
                    2,     // two past frames
                    2);    // two future frames

  while(1) {
    int32_t samples[128];
    ... get_data(samples) ...
    agc_process_frame(a, samples,     // sample data
                      0,              // bits headroom that have been removed
                      sample_memory,  // no look ahead
                      energy_memory); // no energy buffer either
    ... put_data(samples) ...
  }

API
...

Creating an AGC instance
''''''''''''''''''''''''

.. doxygenfunction:: agc_init_state

|newpage|

Controlling an AGC instance
'''''''''''''''''''''''''''

.. doxygenfunction:: agc_set_desired_db
.. doxygenfunction:: agc_set_rate_down_dbps
.. doxygenfunction:: agc_set_rate_up_dbps
.. doxygenfunction:: agc_set_wait_for_up_ms
.. doxygenfunction:: agc_set_gain_min_db
.. doxygenfunction:: agc_set_gain_max_db
.. doxygenfunction:: agc_get_gain

|newpage|

Processing time domain data
'''''''''''''''''''''''''''

.. doxygenfunction:: agc_process_frame

|newpage|
