smoothnessG = pow2(pow2(color.g)) * 0.75;
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.66;
#endif