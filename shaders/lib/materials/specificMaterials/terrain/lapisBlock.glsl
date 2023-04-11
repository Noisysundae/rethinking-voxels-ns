smoothnessG = pow2(color.b) * 0.8;
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.5;
#endif