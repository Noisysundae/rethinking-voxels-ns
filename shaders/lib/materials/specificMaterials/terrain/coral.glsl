float lColor = length(color.rgb);
smoothnessG = lColor * 0.2;
smoothnessD = lColor * 0.15;

#if COATED_TEXTURES > 0
    noiseFactor = 0.66;
#endif