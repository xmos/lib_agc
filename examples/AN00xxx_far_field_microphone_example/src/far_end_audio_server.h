#ifndef _far_end_audio_server_h
#define _far_end_audio_server_h

typedef enum {
    FAR_END_MUSIC,
    FAR_END_WHITE_NOISE,
    FAR_END_PINK_NOISE
} far_end_t;

extern void far_end_audio_server(streaming chanend audio_out,
                                 far_end_t type);

#endif
