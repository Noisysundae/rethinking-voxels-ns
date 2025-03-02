materialMask = OSIEBCA; // Intense Fresnel

float factor = color.g;
float factor2 = pow2(factor);
float factor4 = pow2(factor2);
float factor8 = pow2(factor4);

smoothnessG = factor - factor8 * 0.5;
highlightMult = 3.5 * factor8;

smoothnessD = factor8;

DoBrightBlockTweaks(color.rgb, 0.5, shadowMult, highlightMult);

#if COATED_TEXTURES > 0
    noiseFactor = 0.5;
#endif