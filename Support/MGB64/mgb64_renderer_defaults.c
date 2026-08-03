#include "gfx_uniforms.h"

/* Mobile-owned renderer settings. These conservative defaults keep the first
 * lifecycle probe identity-only; GoldenPad settings can replace them later. */
float g_pcVideoGamma = 1.0f;
int g_pcMsaaSamples = 0;
float g_pcVideoSaturation = 1.0f;
float g_pcVideoContrast = 1.0f;
float g_pcVideoBrightness = 0.0f;
int g_pcOutputDither = 0;
float g_pcVignette = 0.0f;

int g_pcBloom = 0;
float g_pcBloomThreshold = 0.8f;
float g_pcBloomIntensity = 0.0f;

int g_pcSsao = 0;
int g_pcSsaoMode = 1;
float g_pcSsaoRadius = 0.5f;
float g_pcSsaoIntensity = 0.0f;
float g_pcSsaoBias = 0.15f;
float g_pcSsaoPower = 3.0f;
float g_pcSsaoFarCutoff = 800.0f;
float g_pcSsaoNearCut = 0.02f;
float g_pcSsaoSkyCut = 0.9999f;
int g_pcSsaoHalfRes = 0;
int g_pcSsaoBlur = 0;
float g_pcSsaoBlurDepthSharp = 8.0f;

float g_pcEnvRelightBlend = 0.0f;
int g_pcSmaa = 0;
int g_pcSunShadow = 0;
int g_pcSunShadowRes = 2048;
float g_pcSunShadowBias = 0.0015f;
float g_pcSunShadowUmbra = 0.55f;

int g_pcFxaa = 0;
float g_pcSharpen = 0.0f;
int g_pcGradePresets = 0;
int g_pcTonemap = 0;
int g_pcRemasterFX = 0;
float g_pcGradeLevelSat = 1.0f;
float g_pcGradeLevelCon = 1.0f;
float g_pcGradeLevelTintR = 1.0f;
float g_pcGradeLevelTintG = 1.0f;
float g_pcGradeLevelTintB = 1.0f;

/* The minimap queue is not active before validated game data starts. Keep this
 * lifecycle-only closure ROM-free; the real overlay remains a gameplay gate. */
void minimap_overlay_draw_queued_frames_metal(int width, int height) {
    (void)width;
    (void)height;
}
