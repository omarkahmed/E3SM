#pragma once

#include "pam_coupler.h"

// Compute horizontal means for feedback tendencies of variables that are not forced
inline void pam_output_compute_means( pam::PamCoupler &coupler ) {
  using yakl::c::parallel_for;
  using yakl::c::SimpleBounds;
  using yakl::atomicAdd;
  auto &dm_device = coupler.get_data_manager_device_readwrite();
  auto &dm_host   = coupler.get_data_manager_host_readwrite();
  int crm_nz      = dm_device.get_dimension_size("z"   );
  int crm_ny      = dm_device.get_dimension_size("y"   );
  int crm_nx      = dm_device.get_dimension_size("x"   );
  int nens        = dm_device.get_dimension_size("nens");
  int gcm_nlev    = coupler.get_option<int>("gcm_nlev");
  //------------------------------------------------------------------------------------------------
  // Get current CRM state
  auto nc      = dm_device.get<real,4>("cloud_water_num");
  auto ni      = dm_device.get<real,4>("ice_num");
  auto qr      = dm_device.get<real,4>("rain");
  auto nr      = dm_device.get<real,4>("rain_num");
  auto qm      = dm_device.get<real,4>("ice_rime");
  auto bm      = dm_device.get<real,4>("ice_rime_vol");
  //------------------------------------------------------------------------------------------------
  // Create arrays to hold the current column average of the CRM internal columns
  dm_device.register_and_allocate<real>("nc_mean", "domain mean nc", {gcm_nlev,nens},{"gcm_lev","nens"});
  dm_device.register_and_allocate<real>("ni_mean", "domain mean ni", {gcm_nlev,nens},{"gcm_lev","nens"});
  dm_device.register_and_allocate<real>("qr_mean", "domain mean qr", {gcm_nlev,nens},{"gcm_lev","nens"});
  dm_device.register_and_allocate<real>("nr_mean", "domain mean nr", {gcm_nlev,nens},{"gcm_lev","nens"});
  dm_device.register_and_allocate<real>("qm_mean", "domain mean qm", {gcm_nlev,nens},{"gcm_lev","nens"});
  dm_device.register_and_allocate<real>("bm_mean", "domain mean bm", {gcm_nlev,nens},{"gcm_lev","nens"});
  auto nc_mean = dm_device.get<real,2>("nc_mean");
  auto ni_mean = dm_device.get<real,2>("ni_mean");
  auto qr_mean = dm_device.get<real,2>("qr_mean");
  auto nr_mean = dm_device.get<real,2>("nr_mean");
  auto qm_mean = dm_device.get<real,2>("qm_mean");
  auto bm_mean = dm_device.get<real,2>("bm_mean");
  //------------------------------------------------------------------------------------------------
  // We will be essentially reducing a summation to these variables, so initialize them to zero
  parallel_for("Initialize horzontal means", SimpleBounds<2>(gcm_nlev,nens), YAKL_LAMBDA (int k_gcm, int iens) {
    nc_mean       (k_gcm,iens) = 0;
    ni_mean       (k_gcm,iens) = 0;
    qr_mean       (k_gcm,iens) = 0;
    nr_mean       (k_gcm,iens) = 0;
    qm_mean       (k_gcm,iens) = 0;
    bm_mean       (k_gcm,iens) = 0;
  });
  //------------------------------------------------------------------------------------------------
  // Compute horizontal means
  real r_nx_ny  = 1._fp / (crm_nx*crm_ny);  // precompute reciprocal to avoid costly divisions
  parallel_for("Horz mean of CRM state", SimpleBounds<4>(crm_nz,crm_ny,crm_nx,nens), YAKL_LAMBDA (int k_crm, int j, int i, int iens) {
    int k_gcm = gcm_nlev-1-k_crm;
    // yakl::atomicAdd ensures only one thread performs an update at a time to avoid data races and wrong answers
    atomicAdd( nc_mean        (k_gcm,iens), nc        (k_crm,j,i,iens) * r_nx_ny );
    atomicAdd( ni_mean        (k_gcm,iens), ni        (k_crm,j,i,iens) * r_nx_ny );
    atomicAdd( qr_mean        (k_gcm,iens), qr        (k_crm,j,i,iens) * r_nx_ny );
    atomicAdd( nr_mean        (k_gcm,iens), nr        (k_crm,j,i,iens) * r_nx_ny );
    atomicAdd( qm_mean        (k_gcm,iens), qm        (k_crm,j,i,iens) * r_nx_ny );
    atomicAdd( bm_mean        (k_gcm,iens), bm        (k_crm,j,i,iens) * r_nx_ny );
  });
  //------------------------------------------------------------------------------------------------
}


inline void pam_output_copy_to_host( pam::PamCoupler &coupler ) {
  using yakl::c::parallel_for;
  using yakl::c::SimpleBounds;
  using yakl::atomicAdd;
  auto &dm_device = coupler.get_data_manager_device_readwrite();
  auto &dm_host   = coupler.get_data_manager_host_readwrite();
  //------------------------------------------------------------------------------------------------
  auto nc_mean = dm_device.get<real,2>("nc_mean");
  auto ni_mean = dm_device.get<real,2>("ni_mean");
  auto qr_mean = dm_device.get<real,2>("qr_mean");
  auto nr_mean = dm_device.get<real,2>("nr_mean");
  auto qm_mean = dm_device.get<real,2>("qm_mean");
  auto bm_mean = dm_device.get<real,2>("bm_mean");
  //------------------------------------------------------------------------------------------------
  auto output_nc_mean   = dm_host.get<real,2>("output_nc_mean");
  auto output_ni_mean   = dm_host.get<real,2>("output_ni_mean");
  auto output_qr_mean   = dm_host.get<real,2>("output_qr_mean");
  auto output_nr_mean   = dm_host.get<real,2>("output_nr_mean");
  auto output_qm_mean   = dm_host.get<real,2>("output_qm_mean");
  auto output_bm_mean   = dm_host.get<real,2>("output_bm_mean");
  //------------------------------------------------------------------------------------------------
  // Copy the data to host
  nc_mean       .deep_copy_to(output_nc_mean);
  ni_mean       .deep_copy_to(output_ni_mean);
  qr_mean       .deep_copy_to(output_qr_mean);
  nr_mean       .deep_copy_to(output_nr_mean);
  qm_mean       .deep_copy_to(output_qm_mean);
  bm_mean       .deep_copy_to(output_bm_mean);
  //------------------------------------------------------------------------------------------------
}

