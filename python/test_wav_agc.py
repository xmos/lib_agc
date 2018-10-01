import numpy as np
import scipy.io.wavfile
import audio_utils as au
import agc 
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="inpout wav file")
    parser.add_argument("output", help="output wav file")
    parser.parse_args()
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_arguments()

    frame_advance = 240

    rate, mix_wav_file = scipy.io.wavfile.read(args.input, 'r')
    wav_data, channel_count, file_length = au.parse_audio(mix_wav_file)
        
    frame_count = file_length/frame_advance

    output = np.zeros((channel_count, file_length))

    gc = agc.agc(frame_advance, gain_db = 20.0)

    for frame_start in range(0, file_length-frame_advance, frame_advance):
        x = au.get_frame(wav_data, frame_start, frame_advance)
        output[:, frame_start: frame_start + frame_advance] = gc.process_frame(x)

    scipy.io.wavfile.write(args.output, rate, output.T)

