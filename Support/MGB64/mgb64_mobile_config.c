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
int g_pcFpsOverlay = 0;

void goldenpad_mgb64_set_fps_overlay(int enabled) {
    g_pcFpsOverlay = enabled != 0;
}

/* Swift applies the user-selected dead zone to physical controllers before
 * merging them with drift-free touch input. Do not apply it a second time. */
float g_pcGamepadDeadzone = 0.0f;
int g_pcGamepadFpsScale = 1;
float g_pcGamepadLookCurve = 1.0f;
float g_pcGamepadLookSpeed = 20.0f;
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
/* The game already reduces right-stick speed to one third while aiming. Keep
 * the sensitivity equal here so touch input is not slowed a second time. */
float g_pcMouseSensAim = 0.15f;
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
char g_pcTexturePack[1024] = "";
/* Match the original 60-degree first-person framing. The desktop remaster's
 * tighter 50-degree default enlarges long weapons enough to crop the sniper
 * rifle against an iPad's bottom/right edges. */
float g_pcViewmodelFov = 60.0f;
float g_pcViewmodelSway = 1.0f;
int g_pcWeaponCycleBack = 0;
int g_pcWeaponCycleForward = 0;

int goldenpad_mgb64_mobile_config_probe(void) {
    return g_pcAdsEnabled == 0 && g_pcFovY == 50.0f &&
           g_pcViewmodelFov == 60.0f &&
           g_pcStartLevel == -1 && g_pcStartRamrom == NULL &&
           g_pcFpsOverlay == 0 &&
           g_pcFaithfulSim == 0 && g_pcTexturePack[0] == '\0' &&
           g_pcGamepadDeadzone == 0.0f && g_pcGamepadLookCurve == 1.0f;
}
