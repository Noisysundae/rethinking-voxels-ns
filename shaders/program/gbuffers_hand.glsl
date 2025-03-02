////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

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

uniform float viewWidth;
uniform float viewHeight;
uniform float nightVision;

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform ivec2 atlasSize;

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
	uniform int frameCounter;
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
float NdotU = dot(normal, vec3(0.0, 1.0, 0.0)); // NdotU is different here to improve held map visibility
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
#include "/lib/lighting/mainLighting.glsl"

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

	float smoothnessD = 0.0, skyLightFactor = 0.0, materialMask = OSIEBCA * 254.0; // No SSAO, No TAA
	vec3 normalM = normal;
	if (color.a > 0.00001) {
		#ifdef GENERATED_NORMALS
			vec3 colorP = color.rgb;
		#endif
		color.rgb *= glColor.rgb;
		
		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z + 0.38);
		vec3 viewPos = ScreenToView(screenPos);
		vec3 playerPos = ViewToPlayer(viewPos);

		if (color.a < 0.75) materialMask = 0.0;

		float smoothnessG = 0.0, highlightMult = 0.0, emission = 0.0, noiseFactor = 0.6;
		#ifdef IPBR
			#ifdef GENERATED_NORMALS
				GenerateNormals(normalM, colorP);
			#endif

			#if COATED_TEXTURES > 0
				CoatTextures(color.rgb, noiseFactor, playerPos);
			#endif
		#else
			#ifdef CUSTOM_PBR
				GetCustomMaterials(normalM, NdotU, smoothnessG, smoothnessD, highlightMult, emission, materialMask);
			#endif
		#endif

		vec3 shadowMult = vec3(0.4);
		DoLighting(color.rgb, shadowMult, playerPos, viewPos, 0.0, normalM, lmCoord,
				true, false, false, false, 0,
				smoothnessG, highlightMult, emission, 0);
	}

	/* DRAWBUFFERS:01 */
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(smoothnessD, materialMask, skyLightFactor, 1.0);

	#if REFLECTION_QUALITY >= 3 && RP_MODE >= 2
		/* DRAWBUFFERS:015 */
		gl_FragData[2] = vec4(mat3(gbufferModelViewInverse) * normalM, 1.0);
	#endif
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;
out vec2 lmCoord;

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
#if HAND_SWAYING > 0
	uniform float frameTimeCounter;
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

//Program//
void main() {
	gl_Position = ftransform();

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord  = GetLightMapCoordinates();

	glColor = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	sunVec = GetSunVector();
	
	#if defined GENERATED_NORMALS || COATED_TEXTURES > 0
		vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).st;
		vec2 texMinMidCoord = texCoord - midCoord;
		signMidCoordPos = sign(texMinMidCoord);
		absMidCoordPos  = abs(texMinMidCoord);
	#endif

	#if defined GENERATED_NORMALS || defined CUSTOM_PBR
		binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
		tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	#endif

	#if HAND_SWAYING > 0
		#include "/lib/misc/handSway.glsl"
	#endif
}

#endif
