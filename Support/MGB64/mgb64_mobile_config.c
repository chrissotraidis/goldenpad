#include <stddef.h>

/* Mobile-owned defaults for game-side NATIVE_PORT settings. UIKit/Swift may
 * replace these values later; keeping ownership here avoids platform_sdl.c. */

float g_pcAdsBobFloor = 0.15f;
int g_pcAdsCenterCrosshair = 1;
int g_pcAdsEnabled = 0;
int g_pcAdsFaithfulZoom = 0;
int g_pcAdsFovCoupleSens = 1;
int g_pcAdsModelPose = 1;
int g_pcAdsModernReticle = 1;
int g_pcAdsMovePenalty = 1;
float g_pcAdsMoveScale = 1.0f;
float g_pcAdsRecoilReduce = 0.0f;
float g_pcAdsSensitivity = 1.0f;
int g_pcAdsSpreadEnabled = 1;
int g_pcAdsSteadyView = 1;
float g_pcAdsStrafeScale = 1.0f;

float g_pcCamPitch = 0.0f;
float g_pcCamX = 0.0f;
float g_pcCamY = 50.0f;
float g_pcCamYaw = 0.0f;
float g_pcCamZ = -400.0f;
int g_pcCrouchRequest = 0;
float g_pcCutsceneFovY = 60.0f;
int g_pcDebugFlyCamera = 0;
int g_pcDirectBootLevelActive = 0;
int g_pcEnvSmoothNormals = 0;
int g_pcFaithfulSim = 0;
int g_pcFireRateAuthentic = 1;
int g_pcFireRateN64FrameCost = 3;
float g_pcFogDensity = 1.0f;
int g_pcFontUpscale = 3;
float g_pcFovY = 50.0f;
int g_pcFpsOverlay = 1;

float g_pcGamepadDeadzone = 0.15f;
int g_pcGamepadFpsScale = 1;
float g_pcGamepadLookCurve = 1.5f;
float g_pcGamepadLookSpeed = 8.0f;
int g_pcGamepadRadialDeadzone = 1;
int g_pcHitMarkers = 1;
int g_pcIntroSkipStyle = 0;
int g_pcInvertY = 0;

int g_pcMinimapEnabled = 1;
int g_pcMinimapEnemyFireReveal = 1;
int g_pcMinimapMode = 0;
int g_pcMinimapObjectives = 1;
int g_pcMinimapSharpOverlay = 1;
int g_pcMinimapShowAllEnemies = 0;
int g_pcModernCrosshair = 1;
float g_pcMouseSensAim = 0.05f;
float g_pcMouseSensitivity = 0.15f;
int g_pcPerPixelLight = 0;
int g_pcReticleTargetFeedback = 1;
int g_pcSceneDecor = 0;
char g_pcSceneDecorDir[1024] = "assets/decor";
int g_pcSmoothSky = 0;

int g_pcStartDifficulty = 0;
int g_pcStartLevel = -1;
int g_pcStartMpPlayers = 2;
int g_pcStartMpScenario = 0;
int g_pcStartMpStage = 0;
int g_pcStartMpTimeLimitSecs = 0;
int g_pcStartMultiplayer = 0;
const char *g_pcStartRamrom = NULL;

int g_pcSteadyView = 1;
float g_pcSunShadowRadius = 500.0f;
int g_pcTextureAnisotropy = 16;
float g_pcViewmodelFov = 50.0f;
float g_pcViewmodelSway = 1.0f;
int g_pcWeaponCycleBack = 0;
int g_pcWeaponCycleForward = 0;

int goldenpad_mgb64_mobile_config_probe(void) {
    return g_pcAdsEnabled == 0 && g_pcFovY == 50.0f &&
           g_pcStartLevel == -1 && g_pcStartRamrom == NULL &&
           g_pcFaithfulSim == 0;
}
