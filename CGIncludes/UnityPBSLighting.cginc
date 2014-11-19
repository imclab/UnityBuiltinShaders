#ifndef UNITY_PBS_LIGHTING_INCLUDED
#define UNITY_PBS_LIGHTING_INCLUDED


// --------------------------------
// Default BRDF to use:

#if (SHADER_TARGET < 30)
	// Fallback to low fidelity one for pre-SM3.0
	#define UNITY_BRDF_PBS BRDF3_Unity_PBS
#elif defined(SHADER_API_MOBILE)
	// Somewhat simplified for mobile
	#define UNITY_BRDF_PBS BRDF2_Unity_PBS
#else
	// Full quality for SM3+ PC / consoles
	#define UNITY_BRDF_PBS BRDF1_Unity_PBS
#endif


// --------------------------------
// BRDF for lights extracted from *indirect* directional lightmaps (baked and realtime).
// Baked directional lightmap with *direct* light uses UNITY_BRDF_PBS.
// For better quality change to BRDF1_Unity_PBS.
// No directional lightmaps in SM2.0.

#define UNITY_BRDF_PBS_LIGHTMAP_INDIRECT BRDF2_Unity_PBS


// --------------------------------


struct UnityLight
{
	half3 color;
	half3 dir;
	half3 ambient;
	half  ndotl;
};

struct UnityGI
{
	UnityLight light;
	#ifdef DIRLIGHTMAP_SEPARATE
		#ifdef LIGHTMAP_ON
			UnityLight light2;
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
			UnityLight light3;
		#endif
	#endif
	half3 environment;
};

// --------------------------------


#include "UnityStandardBRDF.cginc"
#include "UnityStandardUtils.cginc"

// Surface shader output structure to be used with physically
// based shading model.
struct SurfaceOutputStandard
{
	fixed3 Albedo;		// diffuse color
	fixed3 Specular;	// specular color
	fixed3 Normal;		// tangent space normal, if written
	half3 Emission;
	half Smoothness;	// 0=rough, 1=smooth
	half Occlusion;
	fixed Alpha;
};



inline half4 LightingStandard (SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
{
	s.Normal = normalize(s.Normal);

	// energy conservation
	half oneMinusReflectivity = 1 - SpecularStrength(s.Specular);
	half oneMinusRoughness = s.Smoothness;
	s.Albedo = s.Albedo * oneMinusReflectivity;
	half4 c = UNITY_BRDF_PBS (s.Albedo, s.Specular, oneMinusReflectivity, oneMinusRoughness, s.Normal, viewDir, gi.light, gi.environment);
	#if defined(DIRLIGHTMAP_SEPARATE)
		c += DirectionalLightmapsIndirectBRDF (s.Albedo, s.Specular, oneMinusReflectivity, oneMinusRoughness, s.Normal, viewDir, gi);
	#endif
	return c;
}

inline half4 LightingStandard_Deferred (SurfaceOutputStandard s, half3 viewDir, UnityGI gi, out half4 outDiffuse, out half4 outSpecSmoothness, out half4 outNormal)
{
	// energy conservation
	half oneMinusReflectivity = 1 - SpecularStrength(s.Specular);
	half oneMinusRoughness = s.Smoothness;
	s.Albedo = s.Albedo * oneMinusReflectivity;

	half4 c = UNITY_BRDF_PBS (s.Albedo, s.Specular, oneMinusReflectivity, oneMinusRoughness, s.Normal, viewDir, gi.light, gi.environment);
	#if defined(DIRLIGHTMAP_SEPARATE)
		c += DirectionalLightmapsIndirectBRDF (s.Albedo, s.Specular, oneMinusReflectivity, oneMinusRoughness, s.Normal, viewDir, gi);
	#endif

	outDiffuse = half4(s.Albedo, s.Alpha);
	outSpecSmoothness = half4(s.Specular, s.Smoothness);
	outNormal = half4(s.Normal * 0.5 + 0.5, 1);
	half4 emission = half4(s.Emission + c.rgb, 1);
	return emission;
}


inline void LightingStandard_GI (
	SurfaceOutputStandard s,
	UnityGIInputData data,
	inout UnityGI gi)
{
	UnityStandardGlobalIllumination (data, s.Occlusion, (1-s.Smoothness), s.Normal, gi);
}


#endif // UNITY_PBS_LIGHTING_INCLUDED
