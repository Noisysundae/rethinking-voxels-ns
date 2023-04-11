materialMask = OSIEBCA * 5.0; // Redstone Fresnel

float factor = pow2(color.r);
smoothnessG = 0.4;
highlightMult = factor + 0.2;

smoothnessD = factor * 0.5 + 0.1;

#if COATED_TEXTURES > 0
    noiseFactor = 0.77;
#endif