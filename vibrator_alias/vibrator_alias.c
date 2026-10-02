// Preloaded into the SM8850 vibrator HAL. TWRP looks the HAL up by the
// instance name fixed at build time (SM8750's IVibrator/vibratorfeature),
// while the SM8850 service registers IVibrator/default; registering the same
// binder under both names lets both images share one recovery binary.

#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

typedef struct AIBinder AIBinder;
typedef int32_t (*add_service_fn)(AIBinder*, const char*);

static const char kInstance[] = "android.hardware.vibrator.IVibrator/default";
static const char kAlias[] = "android.hardware.vibrator.IVibrator/vibratorfeature";

int32_t AServiceManager_addService(AIBinder* binder, const char* instance) {
    add_service_fn next = (add_service_fn)dlsym(RTLD_NEXT, "AServiceManager_addService");
    if (next == NULL) return -1;
    int32_t status = next(binder, instance);
    if (status == 0 && instance != NULL && strcmp(instance, kInstance) == 0) next(binder, kAlias);
    return status;
}
