// Copyright (c) 2017, XMOS Ltd, All rights reserved
#include <stdio.h>

static FILE *fd;

void output_init(void) {
    fd = fopen("output-raw-data", "wb");
}

void output_byte(unsigned char x) {
    fwrite(&x, 1, 1, fd);
}

void output_block(unsigned char input_data[], int n) {
    fwrite(input_data, 1, n, fd);
}
