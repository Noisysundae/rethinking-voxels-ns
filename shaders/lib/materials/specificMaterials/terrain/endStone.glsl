float factor = pow2(pow2(color.r));
smoothnessG = factor * 0.65;
smoothnessD = smoothnessG;

#if COATED_TEXTURES > 0
    noiseFactor = 0.66;
#endif