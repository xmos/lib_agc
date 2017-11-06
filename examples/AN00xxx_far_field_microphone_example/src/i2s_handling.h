#ifndef _i2s_handling_h_
#define _i2s_handling_h_

#include "i2s.h"
#include "i2c.h"

extern void i2s_main(chanend c_agc_to_i2s);

[[distributable]] void i2s_handler_no_buffer(server i2s_callback_if i2s,
                                             client i2c_master_if i2c, 
                                             chanend need_more,
                                             out port p_rst);

#endif
