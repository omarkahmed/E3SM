// Copyright (C) 2023 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause

#include "configurations-fft.hpp"

using namespace bbfft;

std::vector<configuration> configurations() {
  auto cfgs = std::vector<configuration>{};
#if defined(CRM_NX)
  unsigned long fft_size = CRM_NX;
#else
  unsigned long fft_size = 32;
#endif
  unsigned long batch_size = 11200;
  
  configuration cfg_template_forward = {
    1, {1, fft_size, batch_size}, precision::f64, direction::forward, transform_type::r2c
  };
  configuration cfg_template_inverse = {
    1, {1, fft_size, batch_size}, precision::f64, direction::backward, transform_type::c2r
  };
  cfg_template_forward.set_strides_default(true);
  cfgs.push_back(cfg_template_forward);
  cfg_template_inverse.set_strides_default(true);
  cfgs.push_back(cfg_template_inverse);

#if defined(CRM_NY)
  cfg_template_forward.shape[1] = CRM_NY;
  cfg_template_forward.set_strides_default(true);
  cfgs.push_back(cfg_template_forward);
  cfg_template_inverse.shape[1] = CRM_NY;
  cfg_template_inverse.set_strides_default(true);
  cfgs.push_back(cfg_template_inverse);
#endif
  // add some power of 2 FFT sizes
  for (unsigned int i = 16; i < 256; i *= 2) {
    if (i != fft_size) {
      cfg_template_forward.shape[1] = i;
      cfg_template_forward.set_strides_default(true);
      cfgs.push_back(cfg_template_forward);
      cfg_template_inverse.shape[1] = i;
      cfg_template_inverse.set_strides_default(true);
      cfgs.push_back(cfg_template_inverse);
    }
  }
  return cfgs;
}
