At the core of the AGC is the ``agc_state_t`` structure, which holds the state
of the AGC for each audio channel to be processed.

The AGC is initialised using the ``agc_init`` function. This function requires
an array of the ``agc_init_config_t`` structure, which contains the user-defined
configuration of the AGC (for each channel) at initialisation. This per-channel
configuration includes;

* Whether the channel has adaptive gain (normal AGC behaviour) or fixed gain.

* The channel's initial gain value.

* The desired output level of voice content in the channel.


Users are also required to include a file named ``agc_conf.h`` at compilation,
which must contain the following pre-processor directives:

* AGC_INPUT_CHANNELS - the number of input channels given to the AGC.

* AGC_CHANNEL_PAIRS - the number of input channel pairs given to the AGC. The
  first AGC_INPUT_CHANNELS channels within this number of pairs will be operated
  on. Must be equal to or greater than ((AGC_INPUT_CHANNELS+1)/2).

* AGC_PROC_FRAME_LENGTH - the length of the frames to be processed by
  the AGC.


After the structure is initialised, each frame is processed using a call to
``agc_process_frame``. This function requires the ``agc_state_t`` structure,
a frame of samples of the correct length and the output level of a Voice
Activity Detector (VAD). The VAD level indicates the probability that there
is voice content in the frame of samples to be processed and is required for
adaptive gain.


The AGC state can be configured to apply a fixed gain to a channel. In these
cases the gain will remain it's initial value. This fixed gain can be adjusted
by the ``agc_set_channel_gain`` function. A channel can be switched between
adaptive and fixed gain behaviour by the ``agc_set_channel_adapt`` function.


A limiter is applied to the output of the AGC through the use of a gain
compressor. If applying gain to a frame results in sample values greater than
INT_MAX/2 or less than -INT_MAX/2 (i.e. greater than -6dBFS) then the gain is
reduced. This removes hard clipping in the AGC output.


|newpage|

Example Usage
.............

In its simplest form the AGC can be used as follows::

  agc_state_t agc_state;
  agc_init_config_t agc_config[AGC_INPUT_CHANNELS] = { // AGC_INPUT_CHANNELS = 2
      {
          1,                    // Adaptive gain.
          VTB_UQ16_16(40),      // Initial gain value (linear).
          VTB_UQ16_16(1000),    // Max gain value (linear).
          (0.1 * INT32_MAX)     // Desired voice output level
      }.
      {
          0,                    // Fixed gain.
          VTB_UQ16_16(40),      // Gain value (linear).
          VTB_UQ16_16(1000),    // Max gain (linear). No impact whilst gain is fixed.
          0                     // Desired voice output level. No impact whilst gain is fixed.
      }
  };

  agc_init_state(agc_state, agc_config);

  while(1) {
    dsp_complex_t samples[AGC_CHANNEL_PAIRS][AGC_PROC_FRAME_LENGTH];
    int32_t vad_output;

    ... get_data(samples) ...
    ... get_vad_output(vad_output) ...

    agc_process_frame(agc_state, samples, vad_output);

    ... put_data(samples) ...
  }


|newpage|

API
...

Supporting Types
................

.. doxygenstruct:: agc_state_t

.. doxygenstruct:: agc_init_config_t

|newpage|

Creating an AGC Instance
''''''''''''''''''''''''

.. doxygenfunction:: agc_init


Processing Time Domain Data
'''''''''''''''''''''''''''

.. doxygenfunction:: agc_process_frame

|newpage|

Controlling an AGC instance
'''''''''''''''''''''''''''

.. doxygenfunction:: agc_set_channel_gain
.. doxygenfunction:: agc_get_channel_gain
.. doxygenfunction:: agc_set_channel_max_gain
.. doxygenfunction:: agc_get_channel_max_gain
.. doxygenfunction:: agc_set_channel_adapt
.. doxygenfunction:: agc_get_channel_adapt
.. doxygenfunction:: agc_set_channel_desired_level
.. doxygenfunction:: agc_get_channel_desired_level

|newpage|
