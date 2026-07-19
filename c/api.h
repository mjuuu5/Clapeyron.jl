#ifndef CLAPEYRON_CAPI_H
#define CLAPEYRON_CAPI_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t clapeyron_err_t;

clapeyron_err_t clapeyron_init(void);
clapeyron_err_t clapeyron_shutdown(void);

uint64_t clapeyron_create_model(const char *spec_json);
clapeyron_err_t clapeyron_free_model(uint64_t handle);

clapeyron_err_t clapeyron_eval_eos(uint64_t handle, double V, double T, const double *z, size_t nz, double *out_value);
clapeyron_err_t clapeyron_eval_eos_res(uint64_t handle, double V, double T, const double *z, size_t nz, double *out_value);

#ifdef __cplusplus
}
#endif

#endif // CLAPEYRON_CAPI_H
