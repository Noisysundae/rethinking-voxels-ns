smoothnessG = pow2(pow2(pow2(color.g))) * 12.0;
smoothnessG = min1(smoothnessG);
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.66;
#endif