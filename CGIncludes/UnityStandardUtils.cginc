#ifndef UNITY_STANDARD_UTILS_INCLUDED
#define UNITY_STANDARD_UTILS_INCLUDED

#include "UnityCG.cginc"

// Helper functions, maybe move into UnityCG.cginc


// dynamic & static lightmaps will contain the ligthing, thus ignore sh
#define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )


#if !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30)
// should we support box projection?
#define _GLOSSYENV_BOX_PROJECTION 1
// should we support blending between probes
#define _GLOSSYENV_BLENDING 1
#endif

half SpecularStrength(half3 specular)
{
	#if (SHADER_TARGET < 30)
		return specular.r; // Red channel - because most metals are either monocrhome or with redish/yellowish tint
	#else
		return max (max (specular.r, specular.g), specular.b);
	#endif
}

// Same as ParallaxOffset in Unity CG, except:
//  *) precision - half instead of float
half2 ParallaxOffset1Step (half h, half height, half3 viewDir)
{
	h = h * height - height/2.0;
	half3 v = normalize(viewDir);
	v.z += 0.42;
	return h * (v.xy / v.z);
}

half LerpOneTo(half b, half t)
{
	half oneMinusT = 1 - t;
	return oneMinusT + b * t;
}

half3 LerpWhiteTo(half3 b, half t)
{
	half oneMinusT = 1 - t;
	return half3(oneMinusT, oneMinusT, oneMinusT) + b * t;
}

half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
{
	#if defined(UNITY_NO_DXT5nm)
		return packednormal.xyz * 2 - 1;
	#else
		half3 normal;
		normal.xy = (packednormal.wy * 2 - 1);
		normal.xy *= bumpScale;
		normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
		return normal;
	#endif
}		

half3 BlendNormals(half3 n1, half3 n2)
{
	return normalize(half3(n1.xy + n2.xy, n1.z*n2.z));
}

half3x3 TangentToWorld(half3 normal, half3 tangent, half3 flip)
{
	half3 binormal = cross(normal, tangent) * flip;
	return half3x3(tangent, binormal, normal);
}


//-------------------------------------------------------------------------------------
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

inline half3 DecodeDirectionalLightmap (half3 color, fixed4 dirTex, half3 normalWorld)
{
	// In directional (non-specular) mode Enlighten bakes dominant light direction
	// in a way, that using it for half Lambert and then dividing by a "rebalancing coefficient"
	// gives a result close to plain diffuse response lightmaps, but normalmapped.

	// Note that dir is not unit length on purpose. It's length is "directionality", like
	// for the directional specular lightmaps.
	half3 dir = dirTex.xyz * 2 - 1;

	half4 tau = half4(normalWorld, 1.0) * 0.5;
	half halfLambert = dot(tau, half4(dir, 1.0));

	return color * halfLambert / dirTex.w;
}

inline void DecodeDirectionalSpecularLightmap (half3 color, fixed4 dirTex, half3 normalWorld, bool isRealtimeLightmap, fixed4 realtimeNormalTex, out UnityLight o_light)
{
	o_light.color = color;
	o_light.dir = dirTex.xyz * 2 - 1;

	// The length of the direction vector is the light's "directionality", i.e. 1 for all light coming from this direction,
	// lower values for more spread out, ambient light.
	half directionality = length(o_light.dir);
	o_light.dir /= directionality;

	#ifdef DYNAMICLIGHTMAP_ON
	if (isRealtimeLightmap)
	{
		// Realtime directional lightmaps' intensity needs to be divided by N.L
		// to get the incoming light intensity. Baked directional lightmaps are already
		// output like that (including the max() to prevent div by zero).
		half3 realtimeNormal = realtimeNormalTex.zyx * 2 - 1;
		o_light.color /= max(0.125, dot(realtimeNormal, o_light.dir));
	}
	#endif

	o_light.ndotl = LambertTerm(normalWorld, o_light.dir);

	// Split light into the directional and ambient parts, according to the directionality factor.
	o_light.ambient = o_light.color * (1 - directionality);
	o_light.color = o_light.color * directionality;

	// Technically this is incorrect, but helps hide jagged light edge at the object silhouettes and
	// makes normalmaps show up.
	o_light.ambient *= o_light.ndotl;
}

inline half3 MixLightmapWithRealtimeAttenuation (half3 lightmapContribution, half attenuation, fixed4 bakedColorTex)
{
	// Let's try to make realtime shadows work on a surface, which already contains
	// baked lighting and shadowing from the current light.
	// Generally do min(lightmap,shadow), with "shadow" taking overall lightmap tint into account.
	half3 shadowLightmapColor = bakedColorTex.rgb * attenuation;
	half3 darkerColor = min(lightmapContribution, shadowLightmapColor);

	// However this can darken overbright lightmaps, since "shadow color" will
	// never be overbright. So take a max of that color with attenuated lightmap color.
	return max(darkerColor, lightmapContribution * attenuation);
}


struct UnityGIInputData
{
	float3 worldPos;
	float3 worldViewDir;
	half3 worldVertexNormal;
	half atten;
	half3 giData;
	float2 dynLightmapUV;

	float4 boxMax[2];
	float4 boxMin[2];
	float4 probePosition[2];
	float4 probeHDR[2];
	float4 blendLerp;
};

UNITY_DECLARE_TEXCUBE(unity_SpecCube);
UNITY_DECLARE_TEXCUBE(unity_SpecCube1);

#if defined(_GLOSSYENV_BOX_PROJECTION) && defined(_GLOSSYENV)
inline half3 UnityBoxProjection (half3 worldNormal, float3 worldPos, float4 probePosition, float4 boxMin, float4 boxMax)
{
	// Do we have a valid reflection probe?
	UNITY_BRANCH
	if (probePosition.w > 0.0)
	{
		half3 nrdir = normalize(worldNormal);
				
		half3 rbmax = (boxMax.xyz - worldPos) / nrdir;
		half3 rbmin = (boxMin.xyz - worldPos) / nrdir;

		half3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;
		half fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

		float3 aabbCenter = (boxMax.xyz + boxMin.xyz) * 0.5;
		float3 offset = aabbCenter - probePosition.xyz;
		float3 posonbox = offset + worldPos + nrdir * fa;

		worldNormal = posonbox - aabbCenter;
	}
	return worldNormal;
}
#endif


inline void UnityStandardGlobalIllumination (
	UnityGIInputData data, half occlusion, half roughness, half3 normalWorld, // in
	inout UnityGI o_gi)
{
	o_gi.light.ambient = 0;

	#if SHOULD_SAMPLE_SH_PROBE
		#if (SHADER_TARGET >= 30)
			o_gi.light.ambient += ShadeSH12Order(half4(normalWorld, 1.0));
		#endif
		o_gi.light.ambient += data.giData;
	#endif

	#if !defined(LIGHTMAP_ON)
		o_gi.light.color *= data.atten;

	#else
		// Baked lightmaps
		fixed4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.giData.xy); 
		half3 bakedColor = DecodeLightmap(bakedColorTex);
		
		#ifdef DIRLIGHTMAP_OFF
			o_gi.light.ambient = bakedColor;

			#ifdef SHADOWS_SCREEN
				o_gi.light.ambient = MixLightmapWithRealtimeAttenuation (o_gi.light.ambient, data.atten, bakedColorTex);
			#endif // #ifdef SHADOWS_SCREEN

		#elif DIRLIGHTMAP_COMBINED
			fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.giData.xy);
			o_gi.light.ambient = DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

			#ifdef SHADOWS_SCREEN
				o_gi.light.ambient = MixLightmapWithRealtimeAttenuation (o_gi.light.ambient, data.atten, bakedColorTex);
			#endif // #ifdef SHADOWS_SCREEN

		#elif DIRLIGHTMAP_SEPARATE
			// Left halves of both intensity and direction lightmaps store direct light; right halves - indirect.

			// Direct
			fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, data.giData.xy);
			DecodeDirectionalSpecularLightmap (bakedColor, bakedDirTex, normalWorld, false, 0, o_gi.light);

			// Indirect
			half2 uvIndirect = data.giData.xy + half2(0.5, 0);
			bakedColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, uvIndirect));
			bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, uvIndirect);
			DecodeDirectionalSpecularLightmap (bakedColor, bakedDirTex, normalWorld, false, 0, o_gi.light2);
		#endif
	#endif
	
	#ifdef DYNAMICLIGHTMAP_ON
		// Dynamic lightmaps
		fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.dynLightmapUV);
		half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex) * unity_LightmapIndScale.rgb;

		#ifdef DIRLIGHTMAP_OFF
			o_gi.light.ambient += realtimeColor;

		#elif DIRLIGHTMAP_COMBINED
			half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.dynLightmapUV);
			o_gi.light.ambient += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);

		#elif DIRLIGHTMAP_SEPARATE
			half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.dynLightmapUV);
			half4 realtimeNormalTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicNormal, unity_DynamicLightmap, data.dynLightmapUV);
			DecodeDirectionalSpecularLightmap (realtimeColor, realtimeDirTex, normalWorld, true, realtimeNormalTex, o_gi.light3);
		#endif
	#endif

	o_gi.light.ambient *= occlusion;

	o_gi.environment = 0;
	#ifdef _GLOSSYENV
		half3 worldNormal = reflect(-data.worldViewDir, normalWorld);
		
		#ifdef _GLOSSYENV_BOX_PROJECTION
			half3 worldNormal0 = UnityBoxProjection(worldNormal, data.worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
		#else
			half3 worldNormal0 = worldNormal;
		#endif

		half3 env0 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube), data.probeHDR[0], worldNormal0, roughness) * occlusion;
		#ifdef _GLOSSYENV_BLENDING
			const float kBlendFactor = 0.99999;
			UNITY_BRANCH
			if (data.blendLerp.x < kBlendFactor)
			{
				#ifdef _GLOSSYENV_BOX_PROJECTION
					half3 worldNormal1 = UnityBoxProjection(worldNormal, data.worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
				#else
					half3 worldNormal1 = worldNormal;
				#endif

				half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(unity_SpecCube1), data.probeHDR[1], worldNormal1, roughness) * occlusion;
				o_gi.environment = lerp(env1, env0, data.blendLerp.x);
			}
			else
			{
				o_gi.environment = env0;
			}
		#else
			o_gi.environment = env0;
		#endif
	#endif
}

#ifdef DIRLIGHTMAP_SEPARATE
inline half4 DirectionalLightmapsIndirectBRDF (half3 baseColor, half3 specColor, half oneMinusReflectivity, half oneMinusRoughness, half3 normal, half3 viewDir, UnityGI gi)
{
	half4 c = 0;

	#ifdef LIGHTMAP_ON
		c += UNITY_BRDF_PBS_LIGHTMAP_INDIRECT (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normal, viewDir, gi.light2, 0);
	#endif
	#ifdef DYNAMICLIGHTMAP_ON
		c += UNITY_BRDF_PBS_LIGHTMAP_INDIRECT (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normal, viewDir, gi.light3, 0);
	#endif

	return c;
}
#endif

// Derivative maps
// http://www.rorydriscoll.com/2012/01/11/derivative-maps/
// For future use.

// Project the surface gradient (dhdx, dhdy) onto the surface (n, dpdx, dpdy)
half3 CalculateSurfaceGradient(half3 n, half3 dpdx, half3 dpdy, half dhdx, half dhdy)
{
	half3 r1 = cross(dpdy, n);
	half3 r2 = cross(n, dpdx);
	return (r1 * dhdx + r2 * dhdy) / dot(dpdx, r1);
}

// Move the normal away from the surface normal in the opposite surface gradient direction
half3 PerturbNormal(half3 n, half3 dpdx, half3 dpdy, half dhdx, half dhdy)
{
	//TODO: normalize seems to be necessary when scales do go beyond the 2...-2 range, should we limit that?
	//how expensive is a normalize? Anything cheaper for this case?
	return normalize(n - CalculateSurfaceGradient(n, dpdx, dpdy, dhdx, dhdy));
}

// Calculate the surface normal using the uv-space gradient (dhdu, dhdv)
half3 CalculateSurfaceNormal(half3 position, half3 normal, half2 gradient, half2 uv)
{
	half3 dpdx = ddx(position);
	half3 dpdy = ddy(position);

	half dhdx = dot(gradient, ddx(uv));
	half dhdy = dot(gradient, ddy(uv));

	return PerturbNormal(normal, dpdx, dpdy, dhdx, dhdy);
}


#endif // UNITY_STANDARD_UTILS_INCLUDED
