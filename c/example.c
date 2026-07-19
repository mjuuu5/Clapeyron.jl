#include <stdio.h>
#include "api.h"

int main(void)
{
    if (clapeyron_init() != 0) {
        fprintf(stderr, "clapeyron_init failed\n");
        return 1;
    }

    const char *spec = "{\"note\": \"placeholder model spec\"}";
    uint64_t h = clapeyron_create_model(spec);
    if (h == 0) {
        fprintf(stderr, "create_model failed\n");
        clapeyron_shutdown();
        return 1;
    }

    double z[1] = {1.0};
    double outv = 0.0;
    int err = clapeyron_eval_eos(h, 1.0, 300.0, z, 1, &outv);
    if (err == 0) {
        printf("eos = %g\n", outv);
    } else {
        printf("eos eval returned error %d\n", err);
    }

    clapeyron_free_model(h);
    clapeyron_shutdown();
    return 0;
}
