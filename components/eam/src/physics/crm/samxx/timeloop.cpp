#include "timeloop.h"

void timeloop() {
  YAKL_SCOPE( crm_output_subcycle_factor , :: crm_output_subcycle_factor );
  YAKL_SCOPE( t                        , :: t );
  YAKL_SCOPE( crm_rad_qrad             , :: crm_rad_qrad );
  YAKL_SCOPE( dtn                      , :: dtn );
  YAKL_SCOPE( ncrms                    , :: ncrms );
  YAKL_SCOPE( na                       , :: na );
  YAKL_SCOPE( dt3                      , :: dt3 );
  YAKL_SCOPE( use_VT                   , :: use_VT );
  YAKL_SCOPE( use_ESMT                 , :: use_ESMT );

  nstep = 0;
  
  float time_init, time_remainder;

  time_init = 0.0;
  time_remainder = 0.0;

  do {
    
    yakl::timer_start("nstep_iteration");
    auto t1 = std::chrono::steady_clock::now();   // Start timin
    nstep = nstep + 1;

    //------------------------------------------------------------------
    //  Check if the dynamical time step should be decreased
    //  to handle the cases when the flow being locally linearly unstable
    //------------------------------------------------------------------
    yakl::timer_start("kurant");
    kurant();
    yakl::timer_stop("kurant");
    
    for(int icyc=1; icyc<=ncycle; icyc++) {
      yakl::timer_start("icycle_iteration");
      icycle = icyc;
      dtn = dt/ncycle;
      parallel_for( 1 , YAKL_LAMBDA ( int i ) {
        dt3(na-1) = dtn;
      });
      dtfactor = dtn/dt;

      parallel_for( ncrms , YAKL_LAMBDA (int icrm) {
        crm_output_subcycle_factor(icrm) = crm_output_subcycle_factor(icrm)+1;
      });

      //---------------------------------------------
      //    the Adams-Bashforth scheme in time
      
      yakl::timer_start("abcoefs");
      abcoefs();
      yakl::timer_stop("abcoefs");
      
      //---------------------------------------------
      //    initialize stuff:
      
      yakl::timer_start("zero");
      zero();
      yakl::timer_stop("zero");
      
      //-----------------------------------------------------------
      //       Buoyancy term:
      yakl::timer_start("buoyancy");
      buoyancy();
      yakl::timer_stop("buoyancy");
      //-----------------------------------------------------------
      // variance transport forcing
      if (use_VT) {
	yakl::timer_start("VT_diagnose");
        VT_diagnose();
	yakl::timer_stop("VT_diagnose");
	yakl::timer_start("VT_forcing");
        VT_forcing();
	yakl::timer_stop("VT_forcing");
      }

      //------------------------------------------------------------
      //       Large-scale and surface forcing:
      yakl::timer_start("forcing");
      forcing();
      yakl::timer_stop("forcing");

      // Apply radiative tendency
      // for (int k=0; k<nzm; k++) {
      //   for (int j=0; j<ny; j++) {
      //     for (int i=0; i<nx; i++) {
      //       for (int icrm=0; icrm<ncrms; icrm++) {
      yakl::timer_start("radiative tendency");
      parallel_for( SimpleBounds<4>(nzm,ny,nx,ncrms) , YAKL_LAMBDA (int k, int j, int i, int icrm) {
        int i_rad = i / (nx/crm_nx_rad);
        int j_rad = j / (ny/crm_ny_rad);
        t(k,j+offy_s,i+offx_s,icrm) = t(k,j+offy_s,i+offx_s,icrm) + crm_rad_qrad(k,j_rad,i_rad,icrm)*dtn;
      });
      yakl::timer_stop("radiative tendency");

      //----------------------------------------------------------
      //    suppress turbulence near the upper boundary (spange):
      if (dodamping) {
	yakl::timer_start("damping"); 
        damping();
	yakl::timer_stop("damping");
      }

      //---------------------------------------------------------
      //   Ice fall-out
      if (docloud) {
	yakl::timer_start("ice_fall"); 
        ice_fall();
	yakl::timer_stop("ice_fall");
      }

      //----------------------------------------------------------
      //     Update scalar boundaries after large-scale processes:
      yakl::timer_start("boundaries(3)");
      boundaries(3);
      yakl::timer_stop("boundaries(3)");

      //---------------------------------------------------------
      //     Update boundaries for velocities:
      yakl::timer_start("boundaries(0)");
      boundaries(0);
      yakl::timer_stop("boundaries(0)");

      //-----------------------------------------------
      //     surface fluxes:
      if (dosurface) {
        yakl::timer_start("crmsurface");
	crmsurface(bflx);
	yakl::timer_stop("crmsurface");
      }

      //-----------------------------------------------------------
      //  SGS physics:
      if (dosgs) {
	yakl::timer_start("sgs_proc");
        sgs_proc();
	yakl::timer_stop("sgs_proc");
      }

      //----------------------------------------------------------
      //     Fill boundaries for SGS diagnostic fields:
      yakl::timer_start("boundaries(4)");
      boundaries(4);
      yakl::timer_stop("boundaries(4)");

      //-----------------------------------------------
      //       advection of momentum:
      yakl::timer_start("advect_mom");
      advect_mom();
      yakl::timer_stop("advect_mom");

      //----------------------------------------------------------
      //  SGS effects on momentum:
      if (dosgs) { 
         yakl::timer_start("sgs_mom");
	 sgs_mom();
	 yakl::timer_stop("sgs_mom");
      }

      //----------------------------------------------------------
      //  Explicit scalar momentum transport scheme (ESMT)
      if (use_ESMT) {
         yakl::timer_start("scalar_momentum_tend");
	 scalar_momentum_tend();
	 yakl::timer_stop("scalar_momentum_tend");
      }

      //-----------------------------------------------------------
      //       Coriolis force:
      if (docoriolis) {
         yakl::timer_start("coriolis");
	 coriolis();
	 yakl::timer_stop("coriolis");
      }

      //---------------------------------------------------------
      //       compute rhs of the Poisson equation and solve it for pressure.
      yakl::timer_start("pressure");
      pressure();
      yakl::timer_stop("pressure");

      //---------------------------------------------------------
      //       find velocity field at n+1/2 timestep needed for advection of scalars:
      //  Note that at the end of the call, the velocities are in nondimensional form.
      yakl::timer_start("adams");
      adams();
      yakl::timer_stop("adams");

      //----------------------------------------------------------
      //     Update boundaries for all prognostic scalar fields for advection:
      yakl::timer_start("boundaries(2)");
      boundaries(2);
      yakl::timer_stop("boundaries(2)");

      //---------------------------------------------------------
      //      advection of scalars :
      yakl::timer_start("advect_all_scalars");
      advect_all_scalars();
      yakl::timer_stop("advect_all_scalars");

      //-----------------------------------------------------------
      //    Convert velocity back from nondimensional form:
      yakl::timer_start("uvw");
      uvw();
      yakl::timer_stop("uvw");

      //----------------------------------------------------------
      //     Update boundaries for scalars to prepare for SGS effects:
      yakl::timer_start("boundaries(3)");
      boundaries(3);
      yakl::timer_stop("boundaries(3)");

      //---------------------------------------------------------
      //      SGS effects on scalars :
      if (dosgs) {
	yakl::timer_start("sgs_scalars"); 
        sgs_scalars();
	yakl::timer_stop("sgs_scalars");
      }

      //-----------------------------------------------------------
      //       Calculate PGF for scalar momentum tendency

      //-----------------------------------------------------------
      //       Cloud condensation/evaporation and precipitation processes:
      if (docloud || dosmoke) {
         yakl::timer_start("micro_proc");
	 micro_proc();
	 yakl::timer_stop("micro_proc");
      }

      //-----------------------------------------------------------
      //       Apply mean-state acceleration
      if (use_crm_accel && !crm_accel_ceaseflag) {
        // Use Jones-Bretherton-Pritchard methodology to accelerate
        // CRM horizontal mean evolution artificially.
         yakl::timer_start("accelerate_crm");
	 accelerate_crm(nstep, nstop, crm_accel_ceaseflag);
	 yakl::timer_stop("accelerate_crm");
      }

      //-----------------------------------------------------------
      //    Compute diagnostics fields:
      yakl::timer_start("diagnose");
      diagnose();
      yakl::timer_stop("diagnose");

      //----------------------------------------------------------
      // Rotate the dynamic tendency arrays for Adams-bashforth scheme:

      int nn=na;
      na=nc;
      nc=nb;
      nb=nn;
      yakl::timer_stop("icycle_iteration");
    } // icycle

    yakl::timer_start("post_icycle");
    post_icycle();
    yakl::timer_stop("post_icycle");

    yakl::timer_stop("nstep_iteration");

    auto t2 = std::chrono::steady_clock::now();   // End timing

    auto step_ms = std::chrono::duration_cast<std::chrono::microseconds>(t2 - t1).count();

    if (nstep == 1) {
	    time_init = (float)step_ms;
    } else {
	    time_remainder += (float)step_ms;
    }

    std::cout << "nstep: " << nstep << ", time (microseconds): " << step_ms << std::endl;

  } while (nstep < nstop);

  std::cout << "first time step (microseconds): " << time_init << std::endl;
  std::cout << "remainder time step (microseconds): " << time_remainder << std::endl;

}
