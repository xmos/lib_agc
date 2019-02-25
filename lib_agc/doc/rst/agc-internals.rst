The Automatic Gain Controller (AGC) applies a gain to blocks of time-domain data
across audio channels. The gain value varies such that segments of voice
content on each channel maintain a specified output level.

At the core of the AGC is the ``agc_state_t`` structure, which holds the state
of the AGC for each audio channel to be processed.

The AGC is initialised using the ``agc_init`` function. This function requires
an array of the ``agc_init_config_t`` structure, which contains the user-defined
configuration of the AGC (for each channel) at initialisation. This per-channel
configuration includes the following parameters;

* Whether the channel has a varying gain (normal AGC behaviour) or a fixed gain.

* The channel's initial gain value.

* The desired output level of voice content in the channel.


Users are also required to include a file named ``agc_conf.h`` at compilation,
which must contain the following pre-processor directives:

* AGC_INPUT_CHANNELS - the number of input channels given to the AGC.

* AGC_CHANNEL_PAIRS - the number of input channel pairs given to the AGC.
  Must be equal to or greater than ((AGC_INPUT_CHANNELS+1)/2).

* AGC_PROC_FRAME_LENGTH - the length of the frames to be processed by
  the AGC.


After the structure is initialised, each frame is processed using a call to
``agc_process_frame``. This function requires the ``agc_state_t`` structure,
a frame of samples of the correct length and the output level of a Voice
Activity Detector (VAD). The VAD level indicates the probability that there
is voice content in the block of samples to be processed.


Simple usage
............

In its simplest form the AGC can be used as follows::

  agc_state_t agc_state;
  agc_init_config_t agc_config[AGC_INPUT_CHANNELS] = { // AGC_INPUT_CHANNELS = 1
      {
          1,                                // Gain will adapt
          VTB_UQ16_16(40),                  // Initial gain (linear)
          VTB_UQ16_16(1000),                // Max gain (linear)
          (0.1 * INT32_MAX)                 // Desired voice output level
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


API
...

Supporting types
................

.. doxygenstruct:: agc_state_t

.. doxygenstruct:: agc_init_config_t

|newpage|

Creating an AGC instance
''''''''''''''''''''''''

.. doxygenfunction:: agc_init

|newpage|

Controlling an AGC instance
'''''''''''''''''''''''''''

.. doxygenfunction:: agc_set_channel_gain
.. doxygenfunction:: agc_get_channel_gain
.. doxygenfunction:: agc_set_channel_adapt
.. doxygenfunction:: agc_get_channel_adapt

|newpage|

Processing time domain data
'''''''''''''''''''''''''''

.. doxygenfunction:: agc_process_frame

|newpage|
