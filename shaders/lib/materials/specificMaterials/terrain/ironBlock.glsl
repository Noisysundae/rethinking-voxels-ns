materialMask = OSIEBCA; // Intense Fresnel
smoothnessG = pow2(pow2(color.r));
highlightMult = smoothnessG * 3.0;
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.33;
#endif