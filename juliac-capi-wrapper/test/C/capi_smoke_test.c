#include <stdio.h>
#include <stdint.h>

#ifdef _WIN32
#define API __declspec(dllimport)
#else
#define API
#endif

API int32_t clapeyron_init(void);
API int32_t clapeyron_shutdown(void);
API uint64_t clapeyron_create_model(const char* spec_json);
API int32_t clapeyron_free_model(uint64_t handle);
API int32_t clapeyron_eval_eos_res(uint64_t handle, double V, double T, const double* z, size_t nz, double* out_val);

int main(void) {
    int32_t rc = clapeyron_init();
    if (rc != 0) {
        printf("init failed: %d\n", rc);
        return 1;
    }

    const char* eos_spec =
        "{\"kind\":\"eos\",\"model\":\"PR\",\"components\":[\"methane\",\"ethane\"],\"userlocations\":[]}";
    uint64_t h_eos = clapeyron_create_model(eos_spec);
    if (h_eos == 0) {
        printf("create eos failed\n");
        clapeyron_shutdown();
        return 2;
    }

    double z[2] = {0.5, 0.5};
    double out = 0.0;
    rc = clapeyron_eval_eos_res(h_eos, 0.002, 300.0, z, 2, &out);
    printf("eval eos_res rc=%d, val=%.12g\n", rc, out);

    rc = clapeyron_free_model(h_eos);
    printf("free eos rc=%d\n", rc);

    const char* acm_spec =
        "{\"kind\":\"activity\",\"model\":\"Wilson\",\"components\":[\"ethanol\",\"water\"],\"userlocations\":[]}";
    uint64_t h_acm = clapeyron_create_model(acm_spec);
    if (h_acm == 0) {
        printf("create activity failed\n");
        clapeyron_shutdown();
        return 3;
    }

    rc = clapeyron_free_model(h_acm);
    printf("free activity rc=%d\n", rc);

    rc = clapeyron_shutdown();
    printf("shutdown rc=%d\n", rc);
    return (rc == 0) ? 0 : 4;
}