#ifndef CLAPEYRON_CAPI_H
#define CLAPEYRON_CAPI_H

#include <stdint.h>
#include <stddef.h> // size_t

#ifdef _WIN32
  #if defined(CLAPEYRON_CAPI_BUILD)
    #define CLAPEYRON_API __declspec(dllexport)
  #else
    #define CLAPEYRON_API __declspec(dllimport)
  #endif
#else
  #define CLAPEYRON_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* 
 * Unit convention:
 * - All thermodynamic inputs and outputs use SI units unless otherwise stated.
 * - Composition values are dimensionless mole fractions.
 * - Temperature: K
 * - Pressure: Pa
 * - Molar volume: m^3/mol
 * - Enthalpy / entropy / internal energy / heat capacity: SI molar units
 */

typedef uint64_t Handle;

typedef enum ClapeyronStatus {
    CLP_OK = 0,
    CLP_ERR_INVALID_HANDLE = -1,
    CLP_ERR_EVAL_FAILED = -2,
    CLP_ERR_KIND_MISMATCH = -3,
    CLP_ERR_BAD_INPUT = -4,
    CLP_ERR_CREATE_FAILED = -5,
    CLP_ERR_NOT_SUPPORTED = -6
} ClapeyronStatus;

typedef enum ClapeyronPhase {
    CLP_PHASE_GAS = 1,
    CLP_PHASE_LIQUID = 2,
    CLP_PHASE_SOLID = 3
} ClapeyronPhase;

typedef enum ClapeyronProp {
    CLP_PROP_DENSITY = 1,
    CLP_PROP_ENTHALPY = 2,
    CLP_PROP_ENTROPY = 3,
    CLP_PROP_FUGACITY = 4,
    CLP_PROP_FUGACITY_COEF = 5,
    CLP_PROP_CP = 6,
    CLP_PROP_CV = 7,
    CLP_PROP_VISCOSITY = 8,
    CLP_PROP_THERMAL_CONDUCTIVITY = 9,
    CLP_PROP_ZFACTOR = 10
} ClapeyronProp;

/* Input pair semantics:
 * - CLP_INPUT_TP: spec1 = T [K], spec2 = P [Pa]
 * - CLP_INPUT_TV: spec1 = T [K], spec2 = V [m^3/mol]
 * - CLP_INPUT_PV: spec1 = P [Pa], spec2 = V [m^3/mol]
 * - CLP_INPUT_HP: spec1 = H [SI molar units], spec2 = P [Pa]
 * - CLP_INPUT_SP: spec1 = S [SI molar units], spec2 = P [Pa]
 * - CLP_INPUT_UP: spec1 = U [SI molar units], spec2 = P [Pa]
 */
typedef enum ClapeyronInputPair {
    CLP_INPUT_TP = 1,
    CLP_INPUT_TV = 2,
    CLP_INPUT_PV = 3,
    CLP_INPUT_HP = 4,
    CLP_INPUT_SP = 5,
    CLP_INPUT_UP = 6
} ClapeyronInputPair;

typedef enum ClapeyronCompBasis {
    CLP_COMP_OVERALL_Z = 1, /* dimensionless mole fractions */
    CLP_COMP_LIQUID_X = 2,
    CLP_COMP_VAPOR_Y = 3,
    CLP_COMP_SOLID_S = 4
} ClapeyronCompBasis;

typedef struct ClapeyronStateInput {
    uint32_t struct_size;   /* Must be set to sizeof(ClapeyronStateInput) */
    uint32_t reserved0;     /* Reserved for alignment and future use */
    ClapeyronInputPair input_pair;
    ClapeyronCompBasis comp_basis;
    double spec1;
    double spec2;
    const double* comp;     /* Composition vector, length ncomp */
    size_t ncomp;
    uint64_t flags;         /* Reserved feature flags */
    const void* ext;        /* Reserved extension pointer */
} ClapeyronStateInput;

typedef struct ClapeyronDerivRequest {
    int wrt_comp; /* 0 or 1 */
    int wrt_T;    /* 0 or 1 */
    int wrt_P;    /* 0 or 1 */
} ClapeyronDerivRequest;

/* lifecycle */
CLAPEYRON_API int32_t clapeyron_init(void);
CLAPEYRON_API int32_t clapeyron_shutdown(void);

/* model */
CLAPEYRON_API Handle clapeyron_create_model(const char* spec_json);
CLAPEYRON_API int32_t clapeyron_free_model(Handle handle);

/* unified property API */
CLAPEYRON_API int32_t clapeyron_prop_eval(
    Handle handle,
    ClapeyronPhase phase,
    ClapeyronProp prop,
    const ClapeyronStateInput* in,
    double* value_out,
    const ClapeyronDerivRequest* drv, /* may be NULL */
    double* dcomp_out,                /* may be NULL, length ncomp */
    double* dT_out,                   /* may be NULL */
    double* dP_out                    /* may be NULL */
);

#ifdef __cplusplus
}
#endif

#endif // CLAPEYRON_CAPI_H