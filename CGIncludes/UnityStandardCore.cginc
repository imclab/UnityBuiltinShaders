#ifndef UNITY_STANDARD_CORE_INCLUDED
#define UNITY_STANDARD_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityStandardBRDF.cginc"

#include "AutoLight.cginc"
#include "Lighting.cginc"


half4		_Color;
half		_AlphaTestRef;

sampler2D	_MainTex;
float4		_MainTex_ST;

sampler2D	_DetailAlbedoMap;
float4		_DetailAlbedoMap_ST;

sampler2D	_BumpMap;
half		_BumpScale;

sampler2D	_DetailMask;
sampler2D	_DetailNormalMap;
half		_DetailNormalMapScale;

sampler2D	_SpecGlossMap;
sampler2D	_MetallicGlossMap;
half		_Metallic;
half		_Glossiness;

sampler2D	_OcclusionMap;
half		_OcclusionStrength;

sampler2D	_ParallaxMap;
half		_Parallax;
half		_UVSec;

half4 		_EmissionColor;
sampler2D	_EmissionMap;

float4		unity_LightmapST;

#ifdef DYNAMICLIGHTMAP_ON
	float4		unity_DynamicLightmapST;
#endif

//---------------------------------------
// Directional lightmaps & Parallax require tangent space too
#if (_NORMALMAP || !DIRLIGHTMAP_OFF || _PARALLAXMAP)
	#define _TANGENT_TO_WORLD 1 
#endif

#if (_DETAIL_MULX2 || _DETAIL_MUL || _DETAIL_ADD || _DETAIL_LERP)
	#define _DETAIL 1
#endif


#ifndef UNITY_SETUP_BRDF_INPUT
	#define UNITY_SETUP_BRDF_INPUT SpecularSetup
#endif

//-------------------------------------------------------------------------------------
// Input functions

struct VertexInput
{
	float4 vertex	: POSITION;
	half3 normal	: NORMAL;
	float2 uv0		: TEXCOORD0;
	float2 uv1		: TEXCOORD1;
#ifdef DYNAMICLIGHTMAP_ON
	float2 uv2		: TEXCOORD2;
#endif
#ifdef _TANGENT_TO_WORLD
	half4 tangent	: TANGENT;
#endif
};

float4 TexCoords(VertexInput v)
{
	float4 texcoord;
	texcoord.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
	texcoord.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
	return texcoord;
}		

half DetailMask(float2 uv)
{
	return tex2D (_DetailMask, uv).a;
}

half3 Albedo(float4 texcoords)
{
	half3 albedo = _Color.rgb * tex2D (_MainTex, texcoords.xy).rgb;
#if _DETAIL
	#if (SHADER_TARGET < 30)
		half mask = 1; // no detail mask on SM2.0
	#else
		half mask = DetailMask(texcoords.xy);
	#endif
	half3 detailAlbedo = tex2D (_DetailAlbedoMap, texcoords.zw).rgb;
	#if _DETAIL_MULX2
		albedo *= LerpWhiteTo (detailAlbedo * unity_ColorSpaceDouble.rgb, mask);
	#elif _DETAIL_MUL
		albedo *= LerpWhiteTo (detailAlbedo, mask);
	#elif _DETAIL_ADD
		albedo += detailAlbedo * mask;
	#elif _DETAIL_LERP
		albedo = lerp (albedo, detailAlbedo, mask);
	#endif
#endif
	return albedo;
}

half Alpha(float2 uv)
{
	return tex2D(_MainTex, uv).a * _Color.a;
}		

half Occlusion(float2 uv)
{
#if (SHADER_TARGET < 30)
	return tex2D(_OcclusionMap, uv).g; // simpler occlusion on SM2.0
#else
	half occ = tex2D(_OcclusionMap, uv).g;
	return LerpOneTo (occ, _OcclusionStrength);
#endif
}

half4 SpecularGloss(float2 uv)
{
	half4 sg;
#ifdef _SPECGLOSSMAP
	sg = tex2D(_SpecGlossMap, uv.xy);
#else
	sg = half4(_SpecColor.rgb, _Glossiness);
#endif
	return sg;
}

half2 MetallicGloss(float2 uv)
{
	half2 mg;
#ifdef _METALLICGLOSSMAP
	mg = tex2D(_MetallicGlossMap, uv.xy).ra;
#else
	mg = half2(_Metallic, _Glossiness);
#endif
	return mg;
}

half3 Emission(float2 uv)
{
#ifndef _EMISSION
	return 0;
#else
	return tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb;
#endif
}

#ifdef _NORMALMAP
half3 NormalInTangentSpace(float4 texcoords)
{
	half3 normalTangent = UnpackScaleNormal(tex2D (_BumpMap, texcoords.xy), _BumpScale);
#if _DETAIL && !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30)
	half mask = DetailMask(texcoords.xy);
	half3 detailNormalTangent = UnpackScaleNormal(tex2D (_DetailNormalMap, texcoords.zw), _DetailNormalMapScale);
	#if _DETAIL_LERP
		normalTangent = lerp(
			normalTangent,
			detailNormalTangent,
			mask);
	#else				
		normalTangent = lerp(
			normalTangent,
			BlendNormals(normalTangent, detailNormalTangent),
			mask);
	#endif
#endif
	return normalTangent;
}
#endif

float4 Parallax (float4 texcoords, half3 viewDir)
{
#if !defined(_PARALLAXMAP) || (SHADER_TARGET < 30)
	return texcoords;
#else
	half h = tex2D (_ParallaxMap, texcoords.xy).g;
	float2 offset = ParallaxOffset1Step (h, _Parallax, viewDir);
	return float4(texcoords.xy + offset, texcoords.zw + offset);
#endif
}

half4 OutputForward (half3 color, half alpha, half fresnel)
{
	#if defined(_ALPHABLEND_ON)

		#if UNITY_PROPER_PBS_TRANSPARENCY
			alpha = alphaOverride; // or what is called 'fresnel' now
		#else
			alpha += fresnel;
		#endif
	#else
		alpha = 1;
		UNITY_OPAQUE_ALPHA(alpha);
	#endif
	return half4(color, alpha);
}

//-------------------------------------------------------------------------------------
// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
half3 NormalizePerVertexNormal (half3 n)
{
	#if (SHADER_TARGET < 30)
		return normalize(n);
	#else
		return n; // will normalize per-pixel instead
	#endif
}

half3 NormalizePerPixelNormal (half3 n)
{
	#if (SHADER_TARGET < 30)
		return n;
	#else
		return normalize(n);
	#endif
}

//-------------------------------------------------------------------------------------
// Common fragment setup
half3 WorldNormal(half4 tan2world[3])
{
	return normalize(tan2world[2].xyz);
}

#ifdef _TANGENT_TO_WORLD
	half3x3 TangentToWorld(half4 tan2world[3])
	{
		half3 t = tan2world[0].xyz;
		half3 b = tan2world[1].xyz;
		half3 n = NormalizePerPixelNormal(tan2world[2].xyz);
		
	#ifdef UNITY_TANGENT_ORTHONORMALIZE
		// ortho-normalize Tangent
		t = normalize (t - n * dot(t, n));

		// recalculate Binormal
		half3 newB = cross(n, t);
		b = newB * sign (dot (newB, b));
	#endif

		return half3x3(t, b, n);
	}
#else
	half3x3 TangentToWorld(half4 tan2world[3])
	{
		return half3x3(0,0,0,0,0,0,0,0,0);
	}
#endif

#ifdef _PARALLAXMAP
	#define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndParallax[0].w,i.tangentToWorldAndParallax[1].w,i.tangentToWorldAndParallax[2].w))
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
	#define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

#define FRAGMENT_SETUP(x) FragmentCommonData x = \
	FragmentSetup(i.tex, i.eyeVec, WorldNormal(i.tangentToWorldAndParallax), IN_VIEWDIR4PARALLAX(i), TangentToWorld(i.tangentToWorldAndParallax));

#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
	FragmentSetup(i.tex, i.eyeVec, WorldNormal(i.tangentToWorldAndLightDir), IN_VIEWDIR4PARALLAX_FWDADD(i), TangentToWorld(i.tangentToWorldAndLightDir));

struct FragmentCommonData
{
	half3 diffColor, specColor;
	// Note: oneMinusRoughness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
	// Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
	half oneMinusReflectivity, oneMinusRoughness;
	half3 normalWorld, normalWorldVertex, eyeVec;
	half alpha;
};

inline FragmentCommonData SpecularSetup (float4 i_tex)
{
	half4 specGloss = SpecularGloss(i_tex.xy);
	half3 specColor = specGloss.rgb;
	half oneMinusReflectivity = 1 - SpecularStrength(specColor);
	half oneMinusRoughness = specGloss.a;

	// Diffuse/Spec Energy conservation
	half3 diffColor = Albedo(i_tex) * oneMinusReflectivity;

	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
}

inline FragmentCommonData MetallicSetup (float4 i_tex)
{
	half3 baseColor = Albedo(i_tex);
	half2 metallicGloss = MetallicGloss(i_tex.xy);
	half metallic = metallicGloss.x;

	// We'll need oneMinusReflectivity, so lerp in the "opposite" direction by metallic factor to get it.
	half4 specOneMinusReflectivity = lerp (half4(0.04, 0.04, 0.04, 1.0), half4(baseColor, 0.04), metallic);
	
	half oneMinusReflectivity = specOneMinusReflectivity.a;
	half3 diffColor = baseColor * oneMinusReflectivity;
	half3 specColor = specOneMinusReflectivity.rgb;
	half oneMinusRoughness = metallicGloss.y;

	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
} 

inline FragmentCommonData FragmentSetup (float4 i_tex, half3 i_eyeVec, half3 i_normalWorld, half3 i_viewDirForParallax, half3x3 i_tanToWorld)
{
	i_tex = Parallax(i_tex, i_viewDirForParallax);

	half alpha = Alpha(i_tex.xy);
	#ifdef _ALPHATEST_ON
		clip (alpha - _AlphaTestRef);
	#endif

	#ifdef _NORMALMAP
		half3 normalWorld = NormalizePerPixelNormal(mul(NormalInTangentSpace(i_tex), i_tanToWorld)); // @TODO: see if we can squeeze this normalize on SM2.0 as well
	#else
		// Should get compiled out, isn't being used in the end.
	 	half3 normalWorld = i_normalWorld;
	#endif
	
	half3 eyeVec = i_eyeVec;
	eyeVec = NormalizePerPixelNormal(eyeVec);


	FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (i_tex);
	o.normalWorld = normalWorld;
	o.normalWorldVertex = i_normalWorld;
	o.eyeVec = eyeVec;
	o.alpha = alpha;
	return o;
}

	

	
float4 unity_SpecCube_BoxMax;
float4 unity_SpecCube_BoxMin;
float4 unity_SpecCube_ProbePosition;
half4 unity_SpecCube_HDR;

float4 unity_SpecCube_BoxMax1;
float4 unity_SpecCube_BoxMin1;
float4 unity_SpecCube_ProbePosition1;
half4 unity_SpecCube_HDR1;

half4 unity_SpecCube_Lerp;

inline void FragmentGI (
	float3 worldPos, 
	half occlusion, half3 i_giData, float2 i_dynLightmapUV, half atten, half roughness, half3 normalWorld, half3 normalWorldVertex, half3 eyeVec,
	inout UnityGI o_gi)
{
	UnityGIInputData d;
	d.worldPos = worldPos;
	d.worldViewDir = -eyeVec;
	d.worldVertexNormal = normalWorldVertex;
	d.atten = atten;
	d.giData = i_giData;
	d.dynLightmapUV = i_dynLightmapUV;
	d.boxMax[0] = unity_SpecCube_BoxMax;
	d.boxMin[0] = unity_SpecCube_BoxMin;
	d.probePosition[0] = unity_SpecCube_ProbePosition;
	d.probeHDR[0] = unity_SpecCube_HDR;

	d.boxMax[1] = unity_SpecCube_BoxMax1;
	d.boxMin[1] = unity_SpecCube_BoxMin1;
	d.probePosition[1] = unity_SpecCube_ProbePosition1;
	d.probeHDR[1] = unity_SpecCube_HDR1;

	d.blendLerp = unity_SpecCube_Lerp;

	UnityStandardGlobalIllumination (
		d, occlusion, roughness, normalWorld, o_gi);
}

// ------------------------------------------------------------------
//  Base forward pass (directional light, emission, lightmaps, ...)

struct VertexOutputForwardBase
{
	float4 pos							: SV_POSITION;
	float4 tex							: TEXCOORD0;
	half3 eyeVec 						: TEXCOORD1;
	half4 tangentToWorldAndParallax[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]
	half3 giData						: TEXCOORD5;	// SH or Static Lightmap UV
	SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#ifdef DYNAMICLIGHTMAP_ON
		float2 dynLightmapUV			: TEXCOORD8;	// Dynamic Lightmap UV
	#endif
	#ifdef _GLOSSYENV_BOX_PROJECTION
		float3 worldPos					: TEXCOORD9;
	#endif
};

VertexOutputForwardBase vertForwardBase (VertexInput v)
{
	VertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);

	float4 posWorld = mul(_Object2World, v.vertex);
	#ifdef _GLOSSYENV_BOX_PROJECTION
		o.worldPos = posWorld.xyz;
	#endif
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.tex = TexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		float3x3 tangentToWorld = TangentToWorld(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndParallax[0].xyz = 0;
		o.tangentToWorldAndParallax[1].xyz = 0;
		o.tangentToWorldAndParallax[2].xyz = normalWorld;
	#endif
	//We need this for shadow receving
	TRANSFER_SHADOW(o);

	// Static lightmaps
	#ifndef LIGHTMAP_OFF
		o.giData.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		o.giData.z = 0;
	// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
	#elif SHOULD_SAMPLE_SH_PROBE
		#if (SHADER_TARGET < 30)
			o.giData = ShadeSH9(half4(normalWorld, 1.0));
		#else
			// Optimization: L2 per-vertex, L0..L1 per-pixel
			o.giData = ShadeSH3Order(half4(normalWorld, 1.0));
		#endif
		// Add approximated illumination from non-important point lights
		#ifdef VERTEXLIGHT_ON
			o.giData += Shade4PointLights (
				unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
				unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
				unity_4LightAtten0, posWorld, normalWorld);
		#endif
	#endif
	

	#ifdef DYNAMICLIGHTMAP_ON
		o.dynLightmapUV = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif
	
	#ifdef _PARALLAXMAP
		TANGENT_SPACE_ROTATION;
		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	#endif
	
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

half4 fragForwardBase (VertexOutputForwardBase i) : SV_Target
{
	FRAGMENT_SETUP(s)

	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	
	#ifdef LIGHTMAP_OFF
		gi.light.color = _LightColor0.rgb + _LightColor0.rgb;
		gi.light.dir = _WorldSpaceLightPos0.xyz;
		gi.light.ndotl = LambertTerm (s.normalWorld, gi.light.dir);
	#else
		//  initialise values that can be referenced by FragmentGI and UNITY_BRDF_PBS
		gi.light.color = half3(0.f, 0.f, 0.f);
		gi.light.ndotl  = 0.f;
		gi.light.dir = half3(0.f, 0.f, 0.f);
	#endif

	half atten = SHADOW_ATTENUATION(i);
	
	float2 dynLightmapUV = 0;
	#ifdef DYNAMICLIGHTMAP_ON
		dynLightmapUV = i.dynLightmapUV;
	#endif
    float3 worldPos = 0;
	#ifdef _GLOSSYENV_BOX_PROJECTION
		worldPos = i.worldPos;
	#endif

	half occlusion = Occlusion(i.tex.xy);
	FragmentGI (
		worldPos, occlusion, i.giData, dynLightmapUV, atten, 1-s.oneMinusRoughness, s.normalWorld, s.normalWorldVertex, s.eyeVec, // in
		gi); // out

	half4 colorFresnel = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.environment);
	#ifdef DIRLIGHTMAP_SEPARATE
		colorFresnel += DirectionalLightmapsIndirectBRDF (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi);
	#endif
	half3 color = colorFresnel.rgb;
	half fresnel = colorFresnel.a;
	color += Emission(i.tex.xy);

	UNITY_APPLY_FOG(i.fogCoord, color);
	return OutputForward (color, s.alpha, fresnel);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)
struct VertexOutputForwardAdd
{
	float4 pos							: SV_POSITION;
	float4 tex							: TEXCOORD0;
	half3 eyeVec 						: TEXCOORD1;
	half4 tangentToWorldAndLightDir[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:lightDir]
	LIGHTING_COORDS(5,6)
	UNITY_FOG_COORDS(7)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
#if defined(_PARALLAXMAP)
	half3 viewDirForParallax			: TEXCOORD8;
#endif
};

VertexOutputForwardAdd vertForwardAdd (VertexInput v)
{
	VertexOutputForwardAdd o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);

	float4 posWorld = mul(_Object2World, v.vertex);
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.tex = TexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		float3x3 tangentToWorld = TangentToWorld(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndLightDir[0].xyz = 0;
		o.tangentToWorldAndLightDir[1].xyz = 0;
		o.tangentToWorldAndLightDir[2].xyz = normalWorld;
	#endif
	//We need this for shadow receving
	TRANSFER_VERTEX_TO_FRAGMENT(o);

	float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
	#ifndef USING_DIRECTIONAL_LIGHT
		lightDir = NormalizePerVertexNormal(lightDir);
	#endif
	o.tangentToWorldAndLightDir[0].w = lightDir.x;
	o.tangentToWorldAndLightDir[1].w = lightDir.y;
	o.tangentToWorldAndLightDir[2].w = lightDir.z;

	#ifdef _PARALLAXMAP
		TANGENT_SPACE_ROTATION;
		o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
	#endif
	
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

half4 fragForwardAdd (VertexOutputForwardAdd i) : SV_Target
{
	FRAGMENT_SETUP_FWDADD(s)

	UnityLight light;
	UNITY_INITIALIZE_OUTPUT(UnityLight, light);
	light.color = _LightColor0.rgb + _LightColor0.rgb;
	light.dir = IN_LIGHTDIR_FWDADD(i);
	light.ambient = 0;

	half atten = LIGHT_ATTENUATION(i);
	
	#ifndef USING_DIRECTIONAL_LIGHT
		light.dir = NormalizePerPixelNormal(light.dir);
	#endif
	
	light.color *= atten; // Shadow the light
	
	light.ndotl = LambertTerm (s.normalWorld, light.dir);
	half4 colorFresnel = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, light, 0);
	half3 color = colorFresnel.rgb;
	half fresnel = colorFresnel.a;

	UNITY_APPLY_FOG_COLOR(i.fogCoord, color, half4(0,0,0,0)); // fog towards black in additive pass
	return OutputForward (color, s.alpha, fresnel);
}

// ------------------------------------------------------------------
//  Deferred pass

struct VertexOutputDeferred
{
	float4 pos							: SV_POSITION;
	float4 tex							: TEXCOORD0;
	half3 eyeVec 						: TEXCOORD1;
	half4 tangentToWorldAndParallax[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]
	half3 giData						: TEXCOORD5;	// SH or Lightmap UV			
	#ifdef DYNAMICLIGHTMAP_ON
		float2 dynLightmapUV				: TEXCOORD6;	// Dynamic Lightmap UV
	#endif
	#ifdef _GLOSSYENV_BOX_PROJECTION
		float3 worldPos						: TEXCOORD7;
	#endif
};


VertexOutputDeferred vertDeferred (VertexInput v)
{
	VertexOutputDeferred o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);

	float4 posWorld = mul(_Object2World, v.vertex);
	#ifdef _GLOSSYENV_BOX_PROJECTION
		o.worldPos = posWorld;
	#endif
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.tex = TexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		float3x3 tangentToWorld = TangentToWorld(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndParallax[0].xyz = 0;
		o.tangentToWorldAndParallax[1].xyz = 0;
		o.tangentToWorldAndParallax[2].xyz = normalWorld;
	#endif

	#ifndef LIGHTMAP_OFF
		o.giData.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		o.giData.z = 0;
	#elif SHOULD_SAMPLE_SH_PROBE
		#if (SHADER_TARGET < 30)
			o.giData = ShadeSH9(half4(normalWorld, 1.0));
		#else
			// Optimization: L2 per-vertex, L0..L1 per-pixel
			o.giData = ShadeSH3Order(half4(normalWorld, 1.0));
		#endif
	#endif
	
	#ifdef DYNAMICLIGHTMAP_ON
		o.dynLightmapUV = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif
	
	#ifdef _PARALLAXMAP
		TANGENT_SPACE_ROTATION;
		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	#endif
	
	return o;
}

void fragDeferred (
	VertexOutputDeferred i,
	out half4 outDiffuse : SV_Target0,			// RT0: diffuse color (rgb), --unused-- (a)
	out half4 outSpecSmoothness : SV_Target1,	// RT1: spec color (rgb), smoothness (a)
	out half4 outNormal : SV_Target2,			// RT2: normal (rgb), --unused-- (a)
	out half4 outEmission : SV_Target3			// RT3: emission (rgb), --unused-- (a)
)
{
	#if (SHADER_TARGET < 30)
		outDiffuse = 1;
		outSpecSmoothness = 1;
		outNormal = 0;
		outEmission = 0;
		return;
	#endif

	FRAGMENT_SETUP(s)

	// no analytic lights in this pass
	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.light.color = 0;
	gi.light.dir = half3 (0,1,0);
	gi.light.ndotl = LambertTerm (s.normalWorld, gi.light.dir);

	half atten = 1;

	// only GI
	float2 dynLightmapUV = 0;
	#ifdef DYNAMICLIGHTMAP_ON
		dynLightmapUV = i.dynLightmapUV;
	#endif
    float3 worldPos = 0;
	#ifdef _GLOSSYENV_BOX_PROJECTION
		worldPos = i.worldPos;
	#endif

	half occlusion = Occlusion(i.tex.xy);
	FragmentGI (
		worldPos, occlusion, i.giData, dynLightmapUV, atten, 1-s.oneMinusRoughness, s.normalWorld, s.normalWorldVertex, s.eyeVec, // in
		gi); // out

	half3 color = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.environment).rgb;
	#ifdef DIRLIGHTMAP_SEPARATE
		color += DirectionalLightmapsIndirectBRDF (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi).rgb;
	#endif

	#ifdef _EMISSION
		color += Emission (i.tex.xy);
	#endif

	#ifndef UNITY_HDR_ON
		color.rgb = exp2(-color.rgb);
	#endif

	outDiffuse = half4(s.diffColor, 1);
	outSpecSmoothness = half4(s.specColor, s.oneMinusRoughness);
	outNormal = half4(s.normalWorld*0.5+0.5,1);
	outEmission = half4(color, 1);
}					
			
#endif // UNITY_STANDARD_CORE_INCLUDED
