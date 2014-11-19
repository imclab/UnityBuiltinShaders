#ifndef UNITY_UNIVERSAL_CORE_INCLUDED
#define UNITY_UNIVERSAL_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityUniversalUtils.cginc"
#include "UnityUniversalBRDF.cginc"

#include "AutoLight.cginc"
#include "Lighting.cginc"


half4		_Color;
half4		_SpecularColor;
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
half		_Glossiness;

sampler2D	_Occlusion;
half		_OcclusionStrength;

sampler2D	_ParallaxMap;
half		_Parallax;
half		_UVSec;

half4 		_EmissionColor;
sampler2D	_EmissionMap;

float4		unity_LightmapST;
sampler2D	unity_Lightmap;
sampler2D	unity_LightmapInd;
sampler2D	unity_LightmapLightInd;
sampler2D	unity_LightmapDirInd;

#ifdef DYNAMICLIGHTMAP_ON
	float4		unity_DynamicLightmapST;
	sampler2D	unity_DynamicLightmap;
	float4		unity_LightmapIndScale;
#endif

//---------------------------------------
// Directional lightmaps & Parallax require tangent space too
#if (_NORMALMAP || !DIRLIGHTMAP_OFF || _PARALLAXMAP)
	#define _TANGENT_TO_WORLD 1 
#endif

#if (_DETAIL_MULX2 || _DETAIL_MUL || _DETAIL_ADD || _DETAIL_LERP)
	#define _DETAIL 1
#endif

#if !defined(SHADER_API_MOBILE) && !defined(SHADER_API_SM2) && !defined(SHADER_API_D3D11_9X)
	#define _GLOSSYENV_BOX_PROJECTION 1
#endif

// dynamic & static lightmaps will contain the ligthing, thus ignore sh
#define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )

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
	#ifdef SHADER_API_SM2
		half mask = 1;
	#else
		half mask = DetailMask(texcoords.xy);
	#endif
	half3 detailAlbedo = tex2D (_DetailAlbedoMap, texcoords.zw).rgb;
	#if _DETAIL_MULX2
		albedo *= LerpWhiteTo (detailAlbedo * unity_ColorSpaceDouble, mask);
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
#ifdef SHADER_API_SM2
	return tex2D(_Occlusion, uv).g;
#else
	half occ = tex2D(_Occlusion, uv).g;
	return LerpOneTo (occ, _OcclusionStrength);
#endif
}

half4 SpecularGloss(float2 uv)
{
	half4 sg;
#ifdef _SPECGLOSSMAP
	sg = tex2D(_SpecGlossMap, uv.xy);
#else
	sg = half4(_SpecularColor.rgb, _Glossiness);
#endif
	return sg;
}

half3 Emission(float2 uv)
{
#ifndef _EMISSIONMAP
	return 0;
#else
	return tex2D(_EmissionMap, uv).rgb * _EmissionColor.rgb;
#endif
}

#ifdef _NORMALMAP
half3 NormalInTangentSpace(float4 texcoords)
{
	half3 normalTangent = UnpackScaleNormal(tex2D (_BumpMap, texcoords.xy), _BumpScale);
#if _DETAIL && !defined(SHADER_API_MOBILE) && !defined(SHADER_API_SM2)
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
#if !defined(_PARALLAXMAP) || defined(SHADER_API_SM2)
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
		//NOTE(ROD): This will destroy alpha-to-blend, think e.g. decals
		// TBD: @Rod: alpha > 1 makes surfaces shine crazy in case of Realtime probes
		alpha += fresnel;
	#else
		alpha = 1;
	#endif
	return half4(color, alpha);
}

//-------------------------------------------------------------------------------------
// Common fragment setup
#define IN_NORMALWORLD(tan2world) normalize(tan2world[2].xyz)

#ifdef _TANGENT_TO_WORLD
	#define IN_TANGENT2WORLD(tan2world) half3x3(tan2world[0].xyz,tan2world[1].xyz, NormalizePerPixelNormal(tan2world[2].xyz))
#else
	#define IN_TANGENT2WORLD(tan2world) half3x3(0,0,0,0,0,0,0,0,0) 
#endif

#ifdef _PARALLAXMAP
	#define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndParallax[0].w,i.tangentToWorldAndParallax[1].w,i.tangentToWorldAndParallax[2].w))
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
	#define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w,i.tangentToWorldAndLightDir[1].w,i.tangentToWorldAndLightDir[2].w)

#define FRAGMENT_SETUP(x) FragmentCommonData x = \
	FragmentSetup(i.tex, i.eyeVec, IN_NORMALWORLD(i.tangentToWorldAndParallax), IN_VIEWDIR4PARALLAX(i), IN_TANGENT2WORLD(i.tangentToWorldAndParallax));

#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
	FragmentSetup(i.tex, i.eyeVec,IN_NORMALWORLD(i.tangentToWorldAndLightDir), IN_VIEWDIR4PARALLAX_FWDADD(i), IN_TANGENT2WORLD(i.tangentToWorldAndLightDir));

// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
half3 NormalizePerVertexNormal (half3 n)
{
	#if defined (SHADER_API_SM2)
		return normalize(n);
	#else
		return n; // will normalize per-pixel instead
	#endif
}

half3 NormalizePerPixelNormal (half3 n)
{
	#if defined (SHADER_API_SM2)
		return n;
	#else
		return normalize(n);
	#endif
}

struct FragmentCommonData
{
	half3 baseColor, specColor;
	half reflectivity, roughness;
	half3 normalWorld, normalWorldVertex, eyeVec, normalTangent;
	half3x3 tanToWorld;
	half alpha;
};

inline FragmentCommonData FragmentSetup (float4 i_tex, half3 i_eyeVec, half3 i_normalWorld, half3 i_viewDirForParallax, half3x3 i_tanToWorld)
{
	i_tex = Parallax(i_tex, i_viewDirForParallax);

	half alpha = Alpha(i_tex.xy);
	#ifdef _ALPHATEST_ON
		clip (alpha - _AlphaTestRef);
	#endif

	FragmentCommonData o = (FragmentCommonData)0;

	#ifdef _NORMALMAP
		half3 normalWorld = NormalizePerPixelNormal(mul(NormalInTangentSpace(i_tex), i_tanToWorld)); // @TODO: see if we can squeeze this normalize on SM2.0 as well
	#else
		// Should get compiled out, isn't being used in the end.
	 	half3 normalWorld = i_normalWorld;
	#endif
	

	//NOTE(ROD): I can see how normals could be non-unity in mobiles (normalization could be in decompress instead of here, but can it actually happen in desktops?
	//normalWorld = normalize(normalWorld); // normalization fixes aliasing in specular (otherwise in some cases N.H > 1)

	half3 eyeVec = i_eyeVec;
	eyeVec = NormalizePerPixelNormal(eyeVec);
	half4 specGloss = SpecularGloss(i_tex.xy);
	half3 specColor = specGloss.rgb;
	half reflectivity = RGBToLuminance(specColor);
	half roughness = 1 - specGloss.a;

	//Diffuse/Spec Energy conservation
	half3 baseColor = Albedo(i_tex) * (1 - reflectivity);

	o.baseColor = baseColor;
	o.specColor = specColor;
	o.reflectivity = reflectivity;
	o.roughness = roughness;
	o.normalWorld = normalWorld;
	o.normalWorldVertex = i_normalWorld;
	o.tanToWorld = i_tanToWorld;
	o.eyeVec = eyeVec;
	o.alpha = alpha;
	return o;
}

//-------------------------------------------------------------------------------------
// NOTE(ROD): normal should be normalized, w=1.0
// Can we optimize that requirement away?
half3 ShadeSH3Order(half4 normal)
{
	half3 x2, x3;
	// 4 of the quadratic polynomials
	half4 vB = normal.xyzz * normal.yzzx;
	x2.r = dot(unity_SHBr,vB);
	x2.g = dot(unity_SHBg,vB);
	x2.b = dot(unity_SHBb,vB);
	
	// Final quadratic polynomial
	half vC = normal.x*normal.x - normal.y*normal.y;
	x3 = unity_SHC.rgb * vC;
	return x2 + x3;
}

half3 ShadeSH12Order (half4 normal)
{
	half3 x1;
	
	// Linear + constant polynomial terms
	x1.r = dot(unity_SHAr,normal);
	x1.g = dot(unity_SHAg,normal);
	x1.b = dot(unity_SHAb,normal);

	//Final linear term
	return x1;
}

inline void DecodeDirLightmap (sampler2D lightmap_light, sampler2D lightmap_dir, float2 uv, half3 normalWorld, half3 normalWorldVertex, out UnityLight o_light)
{
	fixed4 lmtex = tex2D(lightmap_light, uv);
	o_light.color = DecodeLightmap(lmtex);
	half4 lightDirTex = tex2D(lightmap_dir, uv);
	o_light.dir = lightDirTex.xyz * 2 - 1;

	half directionality = length(o_light.dir);
	o_light.dir /= directionality;
	o_light.ndotl = dot(normalWorld, o_light.dir);

	directionality *= lightDirTex.w;
	o_light.ambient = o_light.color * (1 - directionality);

	// Undo diffuse (it was baked with the vertex normal)
	o_light.color /= max(0.1, dot(normalWorldVertex, o_light.dir));

	// Split light into the directional and ambient parts, according to the directionality factor 
	o_light.color = o_light.color * directionality;
}


float4 unity_SpecCube_BoxMax;
float4 unity_SpecCube_BoxMin;
float4 unity_SpecCube_ProbePosition;

inline void FragmentGI (
#ifdef _GLOSSYENV_BOX_PROJECTION
	float3 worldPos, 
#endif
	float4 i_tex, half3 i_giData, float2 i_dynLightmapUV, half atten, half roughness, half3 normalWorld, half3 normalWorldVertex, half3 eyeVec, half3 normalTangent, half3x3 tanToWorld,
	inout UnityGI o_gi)
{
	half occlusion = Occlusion(i_tex.xy);

	o_gi.light.ambient = 0;

	#if SHOULD_SAMPLE_SH_PROBE
		#ifndef SHADER_API_SM2
			o_gi.light.ambient += ShadeSH12Order(half4(normalWorld, 1.0));
		#endif
		o_gi.light.ambient += i_giData;
		o_gi.light.ambient *= occlusion;
	#endif

	#ifdef LIGHTMAP_OFF
		o_gi.light.color *= atten;
	#else
		half4 lmtex = tex2D(unity_Lightmap, i_giData.xy); 
		
		#ifdef DIRLIGHTMAP_OFF
			// Single lightmaps
			half3 lm = DecodeLightmap (lmtex);
			o_gi.light.ambient = lm;

			// TBD: something looks fishy if this is used for directional lightmaps as well.
			// lightColor was overwritten in DecodeDirLightmap - not sure if it is derired in this case
			// maybe we should compare analytical lightDir and lightDir extracted from lightmap, instead?
			o_gi.light.color = max(min(o_gi.light.color, atten * lmtex.rgb), o_gi.light.color * atten);
		#else
			#if !defined(SHADER_API_SM2) // @TBD: Does it work in SM2.0? (64 ALU?)

				DecodeDirLightmap (unity_Lightmap, unity_LightmapInd, i_giData.xy, normalWorld, normalWorldVertex, o_gi.light);
				#ifdef DIRLIGHTMAP_SEPARATE
					DecodeDirLightmap (unity_LightmapLightInd, unity_LightmapDirInd, i_giData.xy, normalWorld, normalWorldVertex, o_gi.lightInd);
				#endif

			#endif
		#endif
	#endif
	
	#ifdef DYNAMICLIGHTMAP_ON
		// Dynamic lightmaps
		fixed4 dynlmtex = tex2D(unity_DynamicLightmap, i_dynLightmapUV);
		o_gi.light.ambient += DecodeLightmap (dynlmtex) * unity_LightmapIndScale.rgb;
	#endif

	o_gi.env = 0;
	#ifdef _GLOSSYENV
		half3 worldNormal = reflect(eyeVec, normalWorld);
		#ifdef _GLOSSYENV_BOX_PROJECTION
			// Do we have a valid reflection probe?
			if (unity_SpecCube_ProbePosition.w > 0.0)
			{
				half3 nrdir = normalize(worldNormal);
				
				half3 rbmax = (unity_SpecCube_BoxMax.xyz - worldPos) / nrdir;
				half3 rbmin = (unity_SpecCube_BoxMin.xyz - worldPos) / nrdir;

				half3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;
				half fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

				float3 aabbCenter = (unity_SpecCube_BoxMax.xyz + unity_SpecCube_BoxMin.xyz) * 0.5;
				float3 offset = aabbCenter - unity_SpecCube_ProbePosition.xyz;
				float3 posonbox = offset + worldPos + nrdir * fa;

				worldNormal = posonbox - aabbCenter;
			}
		#endif
		o_gi.env = Unity_GlossyEnvironment (worldNormal, roughness) * occlusion;
	#endif
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
		float2 dynLightmapUV				: TEXCOORD8;	// Dynamic Lightmap UV
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
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos );
	float3 normalWorld = normalize(UnityObjectToWorldNorm(v.normal));
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityWorldToObjectDir(v.tangent.xyz), v.tangent.w);
		tangentWorld.xyz = normalize(tangentWorld.xyz);

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
	// Sample probe for Dynamic objects only (no static or dynamic lightmaps)
	#elif SHOULD_SAMPLE_SH_PROBE
		#ifdef SHADER_API_SM2
			o.giData = ShadeSH3Order(half4(normalWorld, 1.0)) + ShadeSH12Order(half4(normalWorld, 1.0));
		#else
			o.giData = ShadeSH3Order(half4(normalWorld, 1.0)); //NOTE(ROD):probably silly to optimize for high end HW
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
	gi.light.color = _LightColor0.rgb + _LightColor0.rgb;//NOTE(ROD): Move to the CPU -1 instructions (and should be trivial)
	gi.light.dir = _WorldSpaceLightPos0.xyz;
	gi.light.ndotl = LambertTerm (s.normalWorld, gi.light.dir);
	#endif

	half atten = SHADOW_ATTENUATION(i);
	
	float2 dynLightmapUV = 0;
	#ifdef DYNAMICLIGHTMAP_ON
		dynLightmapUV = i.dynLightmapUV;
	#endif
	FragmentGI (
	#ifdef _GLOSSYENV_BOX_PROJECTION
		i.worldPos, 
	#endif
		i.tex, i.giData, dynLightmapUV, atten, s.roughness, s.normalWorld, s.normalWorldVertex, s.eyeVec, s.normalTangent, s.tanToWorld, // in
		gi); // out

	half4 colorFresnel = UNITY_BRDF_PBS (s.baseColor, s.specColor, s.reflectivity, s.roughness, s.normalWorld, -s.eyeVec, gi.light, gi.env);
	#ifdef DIRLIGHTMAP_SEPARATE
		colorFresnel += UNITY_BRDF_PBS (s.baseColor, s.specColor, s.reflectivity, s.roughness, s.normalWorld, -s.eyeVec, gi.lightInd, 0);
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
	float3 normalWorld = normalize(UnityObjectToWorldNorm(v.normal));
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityWorldToObjectDir(v.tangent.xyz), v.tangent.w);
		tangentWorld.xyz = normalize(tangentWorld.xyz);

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
	light.color = _LightColor0.rgb + _LightColor0.rgb;//NOTE(ROD): Move to the CPU -1 instructions (and should be trivial)
	light.dir = IN_LIGHTDIR_FWDADD(i);
	light.ambient = 0;

	half atten = LIGHT_ATTENUATION(i);
	
	#ifndef USING_DIRECTIONAL_LIGHT
		light.dir = NormalizePerPixelNormal(light.dir);
	#endif
	
	light.color *= atten; // Shadow the light
	
	light.ndotl = LambertTerm (s.normalWorld, light.dir);
	half4 colorFresnel = UNITY_BRDF_PBS (s.baseColor, s.specColor, s.reflectivity, s.roughness, s.normalWorld, -s.eyeVec, light, 0);
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
	float3 normalWorld = normalize(UnityObjectToWorldNorm(v.normal));
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityWorldToObjectDir(v.tangent.xyz), v.tangent.w);
		tangentWorld.xyz = normalize(tangentWorld.xyz);

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
		#ifdef SHADER_API_SM2
		o.giData = ShadeSH3Order(half4(normalWorld, 1.0)) + ShadeSH12Order(half4(normalWorld, 1.0));
		#else
		o.giData = ShadeSH3Order(half4(normalWorld, 1.0)); //NOTE(ROD):probably silly to optimize for high end HW
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
	out half4 outSpecRoughness : SV_Target1,	// RT1: spec color (rgb), roughness (a)
	out half4 outNormal : SV_Target2,			// RT2: normal (rgb), --unused-- (a)
	out half4 outEmission : SV_Target3			// RT3: emission (rgb), --unused-- (a)
)
{
	#if defined (SHADER_API_SM2)
		outDiffuse = 1;
		outSpecRoughness = 1;
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
	FragmentGI (
	#ifdef _GLOSSYENV_BOX_PROJECTION
		i.worldPos, 
	#endif
		i.tex, i.giData, dynLightmapUV, atten, s.roughness, s.normalWorld, s.normalWorldVertex, s.eyeVec, s.normalTangent, s.tanToWorld, // in
		gi); // out

	half3 color = UNITY_BRDF_PBS (s.baseColor, s.specColor, s.reflectivity, s.roughness, s.normalWorld, -s.eyeVec, gi.light, gi.env).rgb;
	#ifdef DIRLIGHTMAP_SEPARATE
		color += UNITY_BRDF_PBS (s.baseColor, s.specColor, s.reflectivity, s.roughness, s.normalWorld, -s.eyeVec, gi.lightInd, 0).rgb;
	#endif

	#ifdef _EMISSIONMAP
		color += Emission (i.tex.xy);
	#endif

	#ifndef UNITY_HDR_ON
		color.rgb = exp2(-color.rgb);
	#endif

	outDiffuse = half4(s.baseColor, 1);
	outSpecRoughness = half4(s.specColor, s.roughness);
	outNormal = half4(s.normalWorld*0.5+0.5,1);
	outEmission = half4(color, 1);
}					
			
#endif // UNITY_UNIVERSAL_CORE_INCLUDED
