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
Mics Speakers Resource   PDM   AEC    BF NS/AGC *Totals* TilesU TilesI
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


