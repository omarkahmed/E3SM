#include "atmosphere_dynamics.hpp"

namespace scream
{

AtmosphereDynamics::AtmosphereDynamics (const ParameterList& /* params */) {
}

void AtmosphereDynamics::initialize (const Comm& comm)
{
  m_dynamics_comm = comm;
}

void AtmosphereDynamics::run (/* what inputs? */)
{

}

void AtmosphereDynamics::finalize (/* what inputs? */)
{

}

} // namespace scream
