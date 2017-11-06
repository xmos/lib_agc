VocalFusion VoiceToolBox
========================


VocalFusion VoiceToolBox is a voice pipeline that transforms signals from
multiple PDM microphones into a single voice output. The system is highly
scalable and customisable:

* Support for as little as one microphone, scales up to 8-16 microphones

* Can execute on the smallest xCORE200 silicon available (single tile QF48
  6x6 mm pacakge) for low microphone count

* Customisable AEC quality, trade in package size against tail length

* Customisable Beamsteering, AGC and noise suppression.


Voice pipeline
--------------

The basic voice pipeline is shown below. It comprises the blocks found in a
traditional voice pipeline, controlled by an application program that can
be customised to the product's needs.




Software architecture
---------------------

The software executes on xCORE200 processors, which is a scalable
architecture, enabling more silicon to be deployed for higher quality
solutions.


==== ======== ========= ==== ===== ===== ====== ======== ====== ======
Mics Speakers Resource   PDM   AEC    BS NS/AGC *Totals* TilesU TilesI
==== ======== ========= ==== ===== ===== ====== ======== ====== ======
1    1        Log cores 1(*)     1     0      1      *3*      1      1
              Memory      30    24     0     12     *66*
2    1        Log cores    2     2     1      1      *6*      2      1
              Memory      30    48    24     12    *114*
3    1        Log cores    2     2     1      1      *6*      2      1
              Memory      30    72    36     12    *150*
4    1        Log cores    2   2-4     1      1    *6-8*      2    1-2
              Memory      30    96    48     12    *186*
6    1        Log cores    3     3     1      1      *8*      2      2
              Memory      50   144    72     12    *278*
8    1        Log cores    3     4     1      1      *9*      2      2
              Memory      50   192    96     12    *350*
16   1        Log cores    6     8  1(*)      1      *9*      3      3
              Memory     100   384    96     12    *592*
==== ======== ========= ==== ===== ===== ====== ======== ====== ======

* Task 0, I2S:
  
  - I2S in and out (48 kHz) 10 us per sample
    
  - converts stereo samples IN to 16 kHz (6.224 us every third sample;
    offset two channels by one sample). Blocks them into 240 16 kHz samples
    to be delivered to AEC task.
    
  - converts mono samples OUT from 16 to 48 kHz (2.448 us). Reads blocks of
    240 samples from NS/AGC task
   
* Task 1: PDMtoPCM:
  
  - PDM to 384 kHz PCM conversion, 4-8 microphones, 62.5 MIPS

* Task 2: PCMtoPCM

  - PCM 384 to 16 kHz conversion, 4 microphones, 62.5 MIPS

* Task 3: AEC

  - AEC, inputs from I2S task for reference signal, inputs from PCMtoPCM
    task for microphone signal. Outputs to NS_AGC

* Task 4: Beamsteering

  - BS, inputs 4 x 240 samples from AEC, oututs 1 x 240 signals to NS_AGC
    
* Task 5: NS_AGC

  - Noise suppression, inputs 240 samples from Beamsteering, then performs

  - Automatic Gain Control, outputs frames of 240 samples to Task 0.

* Task 6: I2C

  - I2C slave

  - Sundry.

Task 6 is strictly speaking unneccesary - there is limited setup that can
be performed whilst the system is running - one could consider it to be ok
for the system to not be in performance mode whilst writing over I2C. For
development purposes it is probably essential to ahve some form of control
over the system.

That leaves a fair amount of slack in the system to add more AEC tasks to a
single tile.

The critical operation will be to phase synchronision between the PDM
microphones and the I2S thread - they are clocked of the same master-clock,
but the I2S microphones should deliver their frame in sync with the PDM
microphones. Adding a third buffer will increase the delay by
another 15 ms (gulp).

Buffering costs:

Task 0: 240 samples @ 32 bits x 3 (Stereo in, mono out): 2.8 kByte

Task 1: 
