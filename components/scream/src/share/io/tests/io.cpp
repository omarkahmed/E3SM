#include <catch2/catch.hpp>

#include "scream_config.h"
#include "share/scream_types.hpp"

#include "share/io/output_manager.hpp"
#include "share/io/scorpio_output.hpp"
#include "share/io/scorpio_input.hpp"
#include "share/io/scream_scorpio_interface.hpp"

#include "share/grid/user_provided_grids_manager.hpp"
#include "share/grid/point_grid.hpp"

#include "share/field/field_identifier.hpp"
#include "share/field/field_header.hpp"
#include "share/field/field.hpp"
#include "share/field/field_repository.hpp"

#include "ekat/ekat_parameter_list.hpp"
namespace {
using namespace scream;
using namespace ekat::units;
using input_type = AtmosphereInput;

std::shared_ptr<FieldRepository<Real>> get_test_repo(const Int num_lcols, const Int num_levs);
std::shared_ptr<UserProvidedGridsManager>            get_test_gm(const ekat::Comm& io_comm, const Int num_gcols, const Int num_levs);
ekat::ParameterList                                  get_om_params(const Int casenum, const ekat::Comm& comm);
ekat::ParameterList                                  get_in_params(const std::string type, const ekat::Comm& comm);

TEST_CASE("input_output_basic","io")
{

  ekat::Comm io_comm(MPI_COMM_WORLD);  // MPI communicator group used for I/O set as ekat object.
  Int num_gcols = 2*io_comm.size();
  Int num_levs = 3;

  // Initialize the pio_subsystem for this test:
  MPI_Fint fcomm = MPI_Comm_c2f(io_comm.mpi_comm());  // MPI communicator group used for I/O.  In our simple test we use MPI_COMM_WORLD, however a subset could be used.
  scorpio::eam_init_pio_subsystem(fcomm);   // Gather the initial PIO subsystem data creater by component coupler

  // First set up a field manager and grids manager to interact with the output functions
  std::shared_ptr<UserProvidedGridsManager> grid_man   = get_test_gm(io_comm,num_gcols,num_levs);
  Int num_lcols = grid_man->get_grid("Physics")->get_num_local_dofs();
  std::shared_ptr<FieldRepository<Real>>    field_repo = get_test_repo(num_lcols,num_levs);

  // Create an Output manager for testing output
  OutputManager m_output_manager;
  auto output_params = get_om_params(1,io_comm);
  m_output_manager.set_params(output_params);
  m_output_manager.set_comm(io_comm);
  m_output_manager.set_grids(grid_man);
  m_output_manager.set_repo(field_repo);
  m_output_manager.init();

  // Construct a timestamp
  util::TimeStamp time (0,0,0,0);

  //  Cycle through data and write output
  const auto& out_fields = field_repo->get_groups_info().at("output");
  Int max_steps = 10;
  Real dt = 1.0;
  for (Int ii=0;ii<max_steps;++ii) {
    for (const auto& fname : out_fields->m_fields_names) {
      auto& f  = field_repo->get_field(fname,"Physics");
      auto f_host = f.get_view<Host>();
      f.sync_to_host();
      for (size_t jj=0;jj<f_host.size();++jj) {
        f_host(jj) += dt;
      }
      f.sync_to_dev();
    }
    time += dt;
    m_output_manager.run(time);
  }
  m_output_manager.finalize();
  // Because the next test for input in this sequence relies on the same fields.  We set all field values
  // to nan to ensure no false-positive tests if a field is simply not read in as input.
  for (const auto& fname : out_fields->m_fields_names)
  {
    auto f_dev  = field_repo->get_field(fname,"Physics").get_view();
    Kokkos::deep_copy(f_dev,std::nan(""));
  }

  // At this point we should have 4 files output:
  // 1 file each for averaged, instantaneous, min and max data.
  // Cycle through each output and make sure it is correct.
  // We can use the produced output files to simultaneously check output quality and the
  // ability to read input.
  auto ins_params = get_in_params("Instant",io_comm);
  auto avg_params = get_in_params("Average",io_comm);
  auto min_params = get_in_params("Min",io_comm);
  auto max_params = get_in_params("Max",io_comm);
  Real tol = pow(10,-6);
  // Check instant output
  input_type ins_input(io_comm,ins_params,field_repo,grid_man);
  ins_input.pull_input();
  auto f1 = field_repo->get_field("field_1","Physics");
  auto f2 = field_repo->get_field("field_2","Physics");
  auto f3 = field_repo->get_field("field_3","Physics");
  auto f4 = field_repo->get_field("field_packed","Physics");
  auto f1_host = f1.get_view<Host>();
  auto f2_host = f2.get_view<Host>();
  auto f3_host = f3.get_reshaped_view<Real**,Host>();
  auto f4_host = f4.get_reshaped_view<Real**,Host>();
  f1.sync_to_host();
  f2.sync_to_host();
  f3.sync_to_host();
  f4.sync_to_host();

  int view_cnt = 0;
  for (int ii=0;ii<num_lcols;++ii) {
    REQUIRE(std::abs(f1_host(ii)-(max_steps*dt+ii))<tol);
    for (int jj=0;jj<num_levs;++jj) {
      view_cnt += 1;
      REQUIRE(std::abs(f3_host(ii,jj)-(ii+max_steps*dt + (jj+1)/10.))<tol);
      REQUIRE(std::abs(f4_host(ii,jj)-(ii+max_steps*dt + (jj+1)/10.))<tol);
    }
  }
  for (int jj=0;jj<num_levs;++jj) {
    REQUIRE(std::abs(f2_host(jj)-(max_steps*dt + (jj+1)/10.))<tol);
  }

  // Check average output
  input_type avg_input(io_comm,avg_params,field_repo,grid_man);
  avg_input.pull_input();
  f1.sync_to_host();
  f2.sync_to_host();
  f3.sync_to_host();
  Real avg_val;
  for (int ii=0;ii<num_lcols;++ii) {
    avg_val = (max_steps+1)/2.0*dt + ii; // Sum(x0+i*dt,i=1...N) = N*x0 + dt*N*(N+1)/2, AVG = Sum/N, note x0=ii in this case
    REQUIRE(std::abs(f1_host(ii)-avg_val)<tol);
    for (int jj=0;jj<num_levs;++jj) {
      avg_val = (max_steps+1)/2.0*dt + (jj+1)/10.+ii;  //note x0=(jj+1)/10+ii in this case.
      REQUIRE(std::abs(f3_host(ii,jj)-avg_val)<tol);
    }
  }
  for (int jj=0;jj<num_levs;++jj) {
    avg_val = (max_steps+1)/2.0*dt + (jj+1)/10.;  //note x0=(jj+1)/10 in this case.
    REQUIRE(std::abs(f2_host(jj)-avg_val)<tol);
  }

  // Check max output
  // The max should be equivalent to the instantaneous because this function is monotonically increasing.
  input_type max_input(io_comm,max_params,field_repo,grid_man);
  max_input.pull_input();
  f1.sync_to_host();
  f2.sync_to_host();
  f3.sync_to_host();
  for (int ii=0;ii<num_lcols;++ii) {
    REQUIRE(std::abs(f1_host(ii)-(max_steps*dt+ii))<tol);
    for (int jj=0;jj<num_levs;++jj) {
      REQUIRE(std::abs(f3_host(ii,jj)-(ii+max_steps*dt + (jj+1)/10.))<tol);
    }
  }
  for (int jj=0;jj<num_levs;++jj) {
    REQUIRE(std::abs(f2_host(jj)-(max_steps*dt + (jj+1)/10.))<tol);
  }
  // Check min output
  // The min should be equivalent to the first step because this function is monotonically increasing.
  input_type min_input(io_comm,min_params,field_repo,grid_man);
  min_input.pull_input();
  f1.sync_to_host();
  f2.sync_to_host();
  f3.sync_to_host();
  for (int ii=0;ii<num_lcols;++ii) {
    REQUIRE(std::abs(f1_host(ii)-ii)<tol);
    for (int jj=0;jj<num_levs;++jj) {
      REQUIRE(std::abs(f3_host(ii,jj)-(ii + (jj+1)/10.))<tol);
    }
  }
  for (int jj=0;jj<num_levs;++jj) {
    REQUIRE(std::abs(f2_host(jj)-((jj+1)/10.))<tol);
  }
  
  // Test pulling input without the field manager:
  using view_2d = typename KokkosTypes<DefaultDevice>::template view_2d<Real>;
  view_2d loc_field_3("field_3",num_lcols,num_levs);
  std::string filename = ins_params.get<std::string>("FILENAME");
  std::string var_name = loc_field_3.label();
  std::vector<std::string> var_dims = {"VL","COL"};
  bool has_columns = true;
  std::vector<int> dim_lens = {num_lcols,num_levs};
  int padding = 0;
  input_type loc_input(io_comm,"Physics",grid_man);
  loc_input.pull_input(filename, var_name, var_dims, has_columns, dim_lens, padding, loc_field_3.data());

  // All Done 
  scorpio::eam_pio_finalize();
  (*grid_man).clean_up();
} // TEST_CASE output_instance
/* ----------------------------------*/

/*===================================================================================================================*/
std::shared_ptr<FieldRepository<Real>> get_test_repo(const Int num_lcols, const Int num_levs)
{
  // Create a repo
  std::shared_ptr<FieldRepository<Real>>  repo = std::make_shared<FieldRepository<Real>>();
  // Create some fields for this repo
  std::vector<FieldTag> tag_h  = {FieldTag::Column};
  std::vector<FieldTag> tag_v  = {FieldTag::VerticalLevel};
  std::vector<FieldTag> tag_2d = {FieldTag::Column,FieldTag::VerticalLevel};

  std::vector<Int>     dims_h  = {num_lcols};
  std::vector<Int>     dims_v  = {num_levs};
  std::vector<Int>     dims_2d = {num_lcols,num_levs};

  using FL = FieldLayout;
  const std::string gn = "Physics";
  FieldIdentifier fid1("field_1",FL{tag_h,dims_h},m,gn);
  FieldIdentifier fid2("field_2",FL{tag_v,dims_v},kg,gn);
  FieldIdentifier fid3("field_3",FL{tag_2d,dims_2d},kg/m,gn);
  FieldIdentifier fid4("field_packed",FL{tag_2d,dims_2d},kg/m,gn);

  // Register fields with repo
  using Spack        = ekat::Pack<Int,SCREAM_SMALL_PACK_SIZE>;
  // Make sure packsize isn't bigger than the packsize for this machine, but not so big that we end up with only 1 pack.
  const int packsize = 2;
  using Pack         = ekat::Pack<Real,packsize>;
  repo->registration_begins();
  repo->register_field(fid1,{"output"});
  repo->register_field(fid2,{"output","restart"});
  repo->register_field(fid3,{"output","restart"});
  repo->register_field<Pack>(fid4,{"output","restart"}); // Register field as packed
  repo->registration_ends();

  // Make sure that field 4 is in fact a packed field
  auto field4 = repo->get_field(fid4);
  auto fid4_padding = field4.get_header().get_alloc_properties().get_padding();
  REQUIRE(fid4_padding > 0);

  // Initialize these fields
  auto f1 = repo->get_field(fid1);
  auto f2 = repo->get_field(fid2);
  auto f3 = repo->get_field(fid3);
  auto f4 = repo->get_field(fid4);
  auto f1_host = f1.get_view<Host>(); 
  auto f2_host = f2.get_view<Host>(); 
  auto f3_host = f3.get_reshaped_view<Real**,Host>();
  auto f4_host = f4.get_reshaped_view<Pack**,Host>(); 
  f1.sync_to_host();
  f2.sync_to_host();
  f3.sync_to_host();
  f4.sync_to_host();
  for (int ii=0;ii<num_lcols;++ii) {
    f1_host(ii) = ii;
    for (int jj=0;jj<num_levs;++jj) {
      f2_host(jj) = (jj+1)/10.0;
      f3_host(ii,jj) = (ii) + (jj+1)/10.0;
      int ipack = jj / packsize;
      int ivec  = jj % packsize;
      f4_host(ii,ipack)[ivec] = (ii) + (jj+1)/10.0;
    }
  }
  f1.sync_to_dev();
  f2.sync_to_dev();
  f3.sync_to_dev();
  f4.sync_to_dev();

  return repo;
}
/*===================================================================================================================*/
std::shared_ptr<UserProvidedGridsManager> get_test_gm(const ekat::Comm& io_comm, const Int num_gcols, const Int num_levs)
{

  auto& gm_factory = GridsManagerFactory::instance();
  gm_factory.register_product("User Provided",create_user_provided_grids_manager);
  auto dummy_grid = create_point_grid("Physics",num_gcols,num_levs,io_comm);
  auto upgm = std::make_shared<UserProvidedGridsManager>();
  upgm->set_grid(dummy_grid);

  return upgm;
}
/*===================================================================================================================*/
ekat::ParameterList get_om_params(const Int casenum, const ekat::Comm& comm)
{
  ekat::ParameterList om_params("Output Manager");
  om_params.set<Int>("PIO Stride",1);
  if (casenum == 1) {
    std::vector<std::string> fileNames = { "io_test_instant","io_test_average",
                                            "io_test_max",    "io_test_min" };
    for (auto& name : fileNames) {
      name += "_np" + std::to_string(comm.size()) + ".yaml";
    }

    om_params.set("Output YAML Files",fileNames);
  } else if (casenum == 2) {
    std::vector<std::string> fileNames = { "io_test_restart_np" + std::to_string(comm.size()) + ".yaml" };
    om_params.set("Output YAML Files",fileNames);
    auto& res_sub = om_params.sublist("Restart Control");
    auto& freq_sub = res_sub.sublist("FREQUENCY");
    freq_sub.set<Int>("OUT_N",5);
    freq_sub.set<std::string>("OUT_OPTION","Steps");
  } else {
    EKAT_REQUIRE_MSG(false,"Error, incorrect case number for get_om_params");
  }

  return om_params;  
}
/*===================================================================================================================*/
ekat::ParameterList get_in_params(const std::string type, const ekat::Comm& comm)
{
  ekat::ParameterList in_params("Input Parameters");
  in_params.set<std::string>("FILENAME","io_output_test_np" + std::to_string(comm.size()) +"."+type+".Steps_x10.0000-01-01.000010.nc");
  in_params.set<std::string>("GRID","Physics");
  auto& f_list = in_params.sublist("FIELDS");
  f_list.set<Int>("Number of Fields",4);
  for (int ii=1;ii<=3+1;++ii) {
    f_list.set<std::string>("field "+std::to_string(ii),"field_"+std::to_string(ii));
  }
  f_list.set<std::string>("field 4","field_packed");
  return in_params;
}
/*===================================================================================================================*/
} // undefined namespace
