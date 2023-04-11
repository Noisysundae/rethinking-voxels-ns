smoothnessG = pow2(pow2(color.r)) * 0.65;
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.5;
#endif