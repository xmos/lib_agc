import numpy as np
import scipy.io.wavfile
#import matplotlib.pyplot as plt
import utils.audio_utils as au
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("x", help="point_noise wav file")
    parser.add_argument("e", help="voice wav file")
    parser.add_argument("-g", default='30.0', help="Gain value in dB")
    parser.parse_args()
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()

    frame_advance = 240

    rate, mix_wav_file = scipy.io.wavfile.read(args.x, 'r')
    mix_wav_data, channel_count, file_length = au.parse_audio(mix_wav_file)
        
    frame_count = file_length/frame_advance

    output = np.zeros((len(mix_wav_data), file_length), dtype=np.int16)

    gc = agc.automatic_gain_control(frame_advance, automatic = False, gain_db = float(args.g))

    for frame_start in range(0, file_length-frame_advance, frame_advance):
        x_mix = au.get_frame(mix_wav_data, frame_start, frame_advance)
        o = gc.process_frame(x_mix)
        output[:, frame_start: frame_start + frame_advance] = o

    scipy.io.wavfile.write(args.e, rate, output.T)

