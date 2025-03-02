const float packSizeNT = COATED_TEXTURES;

void CoatTextures(inout vec3 color, float noiseFactor, vec3 playerPos) {
    #ifndef SAFER_GENERATED_NORMALS
        vec2 noiseCoord = floor(midCoordPos / 16.0 * packSizeNT * atlasSizeM) / packSizeNT / 3.0;
    #else
        vec2 offsetR = max(absMidCoordPos.x, absMidCoordPos.y) * vec2(float(atlasSizeM.y) / float(atlasSizeM.x), 1.0);
        vec2 noiseCoord = floor(midCoordPos / 2.0 * packSizeNT / offsetR) / packSizeNT / 3.0;
    #endif

    #if !defined GBUFFERS_ENTITIES && !defined GBUFFERS_HAND
        vec3 floorWorldPos = floor(playerPos + cameraPosition + 0.001);
        noiseCoord += 0.84 * (floorWorldPos.xz + floorWorldPos.y);
    #endif
    
    float noiseTexture = texture2D(noisetex, noiseCoord).r;
    noiseTexture = noiseTexture + 0.6;
    float colorBrightness = dot(color, color) * 0.3;
    noiseFactor *= 0.27 * max0(1.0 - colorBrightness);
    noiseFactor *= max(1.0 - miplevel * 0.25, 0.0);
    noiseTexture = pow(noiseTexture, noiseFactor);
    color.rgb *= noiseTexture;
}