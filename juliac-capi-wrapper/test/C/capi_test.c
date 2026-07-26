#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <windows.h>

typedef int32_t (*fn_clapeyron_init)(void);
typedef int32_t (*fn_clapeyron_shutdown)(void);
typedef uint64_t (*fn_clapeyron_create_model)(const char* spec_json);
typedef int32_t (*fn_clapeyron_free_model)(uint64_t handle);
typedef int32_t (*fn_clapeyron_eval_eos_res)(uint64_t handle, double V, double T, const double* z, size_t nz, double* out_val);

int main(void) {
    HMODULE lib = LoadLibraryA("Clapeyron.dll");
    if (!lib) {
        printf("failed to load Clapeyron.dll\n");
        return 10;
    }

    fn_clapeyron_init clapeyron_init = (fn_clapeyron_init)GetProcAddress(lib, "clapeyron_init");
    fn_clapeyron_shutdown clapeyron_shutdown = (fn_clapeyron_shutdown)GetProcAddress(lib, "clapeyron_shutdown");
    fn_clapeyron_create_model clapeyron_create_model = (fn_clapeyron_create_model)GetProcAddress(lib, "clapeyron_create_model");
    fn_clapeyron_free_model clapeyron_free_model = (fn_clapeyron_free_model)GetProcAddress(lib, "clapeyron_free_model");
    fn_clapeyron_eval_eos_res clapeyron_eval_eos_res = (fn_clapeyron_eval_eos_res)GetProcAddress(lib, "clapeyron_eval_eos_res");

    if (!clapeyron_init || !clapeyron_shutdown || !clapeyron_create_model || !clapeyron_free_model || !clapeyron_eval_eos_res) {
        printf("failed to resolve one or more C API symbols\n");
        FreeLibrary(lib);
        return 11;
    }

    int32_t rc = clapeyron_init();
    if (rc != 0) {
        printf("init failed: %d\n", rc);
        FreeLibrary(lib);
        return 1;
    }

    const char* eos_spec =
        "{\"kind\":\"eos\",\"family\":\"cubic\",\"model\":{\"name\":\"ceos\",\"variant\":\"PR\"},\"components\":[{\"name\":\"methane\"},{\"name\":\"ethane\"}],\"options\":{\"idealmodel\":\"BasicIdeal\",\"alpha\":\"PRAlpha\",\"mixing_rule\":\"vdW1fRule\",\"translation\":\"NoTranslation\",\"verbose\":false},\"metadata\":{\"spec_version\":\"1.0\"}}";
    uint64_t h_eos = clapeyron_create_model(eos_spec);
    if (h_eos == 0) {
        printf("create eos failed\n");
        clapeyron_shutdown();
        FreeLibrary(lib);
        return 2;
    }

    double z[2] = {0.5, 0.5};
    double out = 0.0;
    rc = clapeyron_eval_eos_res(h_eos, 0.002, 300.0, z, 2, &out);
    printf("eval eos_res rc=%d, val=%.12g\n", rc, out);

    rc = clapeyron_free_model(h_eos);
    printf("free eos rc=%d\n", rc);

    const char* acm_spec =
        "{\"kind\":\"activity\",\"family\":\"activity\",\"model\":{\"name\":\"Wilson\"},\"components\":[{\"name\":\"ethanol\"},{\"name\":\"water\"}],\"options\":{},\"metadata\":{\"spec_version\":\"1.0\"}}";
    uint64_t h_acm = clapeyron_create_model(acm_spec);
    if (h_acm == 0) {
        printf("create activity failed\n");
        clapeyron_shutdown();
        FreeLibrary(lib);
        return 3;
    }

    rc = clapeyron_free_model(h_acm);
    printf("free activity rc=%d\n", rc);

    rc = clapeyron_shutdown();
    printf("shutdown rc=%d\n", rc);
    FreeLibrary(lib);
    return (rc == 0) ? 0 : 4;
}