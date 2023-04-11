smoothnessG = pow2(color.g) * 0.7;
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.77;
#endif