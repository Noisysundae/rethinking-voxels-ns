//////////////////////////////////
// Complementary Base by EminGT //
//////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

flat in int blockId;
int blockEntityId = blockId;

in vec2 texCoord;
in vec2 lmCoord;

flat in vec3 upVec, sunVec, northVec, eastVec;
in vec3 normal;

in vec4 glColor;

#if defined GENERATED_NORMALS || COATED_TEXTURES > 0
	in vec2 signMidCoordPos;
	flat in vec2 absMidCoordPos;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	flat in vec3 binormal, tangent;
#endif

//Uniforms//
uniform int isEyeInWater;
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

uniform ivec2 atlasSize;

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
#if BL_SHADOW_MODE == 1
uniform float near, far;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
#endif

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D tex;

#if defined PP_BL_SHADOWS || defined PP_SUN_SHADOWS || (defined HELD_LIGHT_OCCLUSION_CHECK && HELD_LIGHTING_MODE > 0)
	#define ATLASTEX tex
#endif

#if COATED_TEXTURES > 0
	uniform sampler2D noisetex;
#endif

#ifdef CLOUD_SHADOWS
	uniform sampler2D gaux3;
#endif

#if HELD_LIGHTING_MODE >= 1
	uniform int heldItemId;
	uniform int heldItemId2;
#endif

#ifdef CUSTOM_PBR
	uniform sampler2D normals;
	uniform sampler2D specular;
#endif

//Pipeline Constants//

//Common Variables//
float NdotU = dot(normal, upVec);
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

#ifdef OVERWORLD
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
	vec3 lightVec = sunVec;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	mat3 tbnMatrix = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);
#endif

//Common Functions//

//Includes//
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/lighting/mainLighting.glsl"

#ifdef TAA
	#include "/lib/util/jitter.glsl"
#endif

#if defined GENERATED_NORMALS || COATED_TEXTURES > 0
	#include "/lib/util/miplevel.glsl"
#endif

#ifdef GENERATED_NORMALS
	#include "/lib/materials/materialMethods/generatedNormals.glsl"
#endif

#if COATED_TEXTURES > 0
	#include "/lib/materials/materialMethods/coatedTextures.glsl"
#endif

#ifdef CUSTOM_PBR
	#include "/lib/materials/materialHandling/customMaterials.glsl"
#endif

//Program//
void main() {
	vec4 color = texture2D(tex, texCoord);
	#ifdef GENERATED_NORMALS
		vec3 colorP = color.rgb;
	#endif
	color *= glColor;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
		vec3 viewPos = ScreenToView(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
		vec3 viewPos = ScreenToView(screenPos);
    #endif
	float lViewPos = length(viewPos);
	vec3 playerPos = ViewToPlayer(viewPos);

	bool noSmoothLighting = false, noDirectionalShading = false;
	
	float smoothnessD = 0.0, skyLightFactor = 0.0, materialMask = 0.0;
	float smoothnessG = 0.0, highlightMult = 1.0, emission = 0.0, noiseFactor = 1.0;
	vec2 lmCoordM = lmCoord;
	vec3 normalM = normal, shadowMult = vec3(1.0);
	#ifdef IPBR
		#include "/lib/materials/materialHandling/blockEntityMaterials.glsl"
	#else
		#ifdef CUSTOM_PBR
			GetCustomMaterials(normalM, NdotU, smoothnessG, smoothnessD, highlightMult, emission, materialMask);
		#endif

		if (blockEntityId == 60000) { // End Portal, End Gateway
			#include "/lib/materials/specificMaterials/others/endPortalEffect.glsl"
		} else if (blockEntityId == 60004) { // Signs
			noSmoothLighting = true;
			if (glColor.r + glColor.g + glColor.b <= 2.99 || lmCoord.x > 0.999) { // Sign Text
				#include "/lib/materials/specificMaterials/others/signText.glsl"
			}
		} else {	
			noSmoothLighting = true;
		}
	#endif

	#ifdef GENERATED_NORMALS
		GenerateNormals(normalM, colorP);
	#endif

	#if COATED_TEXTURES > 0
		CoatTextures(color.rgb, noiseFactor, playerPos);
	#endif

	DoLighting(color.rgb, shadowMult, playerPos, viewPos, lViewPos, normalM, lmCoordM,
	           noSmoothLighting, noDirectionalShading, false, false, 0,
			   smoothnessG, highlightMult, emission, blockEntityId);

	/* DRAWBUFFERS:01 */
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(smoothnessD, materialMask, skyLightFactor, 1.0);

	#if REFLECTION_QUALITY >= 3 && RP_MODE >= 2 || BL_SHADOW_MODE == 1
		/* DRAWBUFFERS:015 */
		gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, 1.0);
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;
out vec2 lmCoord;

flat out int blockId;

flat out vec3 upVec, sunVec, northVec, eastVec;
out vec3 normal;

out vec4 glColor;

#if defined GENERATED_NORMALS || COATED_TEXTURES > 0
	out vec2 signMidCoordPos;
	flat out vec2 absMidCoordPos;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	flat out vec3 binormal, tangent;
#endif

//Uniforms//
#ifdef TAA
	uniform float viewWidth, viewHeight;
#endif

uniform int blockEntityId;

#if defined GENERATED_NORMALS || COATED_TEXTURES > 0

	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;
#endif

//Attributes//
#if defined GENERATED_NORMALS || COATED_TEXTURES > 0
	attribute vec4 mc_midTexCoord;
#endif

#if defined GENERATED_NORMALS || defined CUSTOM_PBR
	attribute vec4 at_tangent;
#endif

//Common Variables//

//Common Functions//

//Includes//
#ifdef TAA
	#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	gl_Position = ftransform();
	#ifdef TAA
		gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord  = GetLightMapCoordinates();

	glColor = gl_Color;

	blockId = 10000 * (blockEntityId / 10000) + + 4 * ((blockEntityId % 2000) / 4);

	normal = normalize(gl_NormalMatrix * gl_Normal);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	sunVec = GetSunVector();

	if (normal != normal) normal = -upVec; // Mod Fix: Fixes Better Nether Fireflies

	#if defined GENERATED_NORMALS || COATED_TEXTURES > 0
		if (blockEntityId == 60008) { // Chest
			float fractWorldPosY = fract((gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).y + cameraPosition.y);
			if (fractWorldPosY > 0.56 && 0.57 > fractWorldPosY) gl_Position.z -= 0.0001;
		}
		
		vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
		vec2 texMinMidCoord = texCoord - midCoord;
		signMidCoordPos = sign(texMinMidCoord);
		absMidCoordPos  = abs(texMinMidCoord);
	#endif

	#if defined GENERATED_NORMALS || defined CUSTOM_PBR
		binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
		tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	#endif
}

#endif
