#!/usr/bin/env python3
# Copyright (c) 2019, XMOS Ltd, All rights reserved
from pathlib import Path
from json_utils import JsonHandler

print("IN generate_config.py")
module_dir = Path(__file__).parent
file_conv = JsonHandler(str((module_dir / 'config/agc_2ch.json').resolve()),
                        False)
file_conv.create_header_file(
    str((module_dir / 'api/agc.h').resolve()),
    [str((module_dir / '../tests/test_wav_agc/src/agc_conf.h').resolve())]
)
