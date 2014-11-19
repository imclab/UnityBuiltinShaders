#ifndef UNITY_UNIVERSAL_BRDF_INCLUDED
#define UNITY_UNIVERSAL_BRDF_INCLUDED

#include "UnityCG.cginc"
//-------------------------------------------------------------------------------------
#define UNITY_SPECCUBE_LOD_EXPONENT (1.5)
#define UNITY_SPECCUBE_LOD_STEPS (8)


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
	UnityLight lightInd;
#endif
	half3 env;
};


//-------------------------------------------------------------------------------------

inline half DotClamped (half3 a, half3 b)
{
	#if SHADER_API_SM2
		return saturate(dot(a, b));
	#else
		return max(0.0f, dot(a, b));
	#endif
}

inline half LambertTerm (half3 normal, half3 lightDir)
{
	return DotClamped (normal, lightDir);
}

inline half BlinnTerm (half3 normal, half3 halfDir)
{
	return DotClamped (normal, halfDir);
}

inline half FresnelTerm (half F0, half cosA)
{
	half Falloff = 5;
	half t = pow (abs (1 - cosA), Falloff);	// ala Schlick interpoliation
	return F0 + (1-F0) * t;
}
inline half FresnelTermFast (half F0, half cosA)
{
	half t = 1 - cosA;
	t *= t; // ^2
	t *= t; // ^4
	return F0 + (1-F0) * t;
}

inline half GeometricTerm (half NdotL, half NdotH, half NdotV, half VdotH)
{
	VdotH += 1e-5f;
	return min (1.0, min (
		(2.0 * NdotH * NdotV) / VdotH,
		(2.0 * NdotH * NdotL) / VdotH));
}

inline half RoughnessToSpecPower (half roughness)
{
	half m = pow (roughness, 2.0 * UNITY_SPECCUBE_LOD_EXPONENT) + 1e-4f; // follow the same curve as unity_SpecCube
	half n = (2.0 / m) - 2.0;							// http://jbit.net/%7Esparky/academic/mm_brdf.pdf
	n = max(n, 1.0e-5f);								// prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
	return n;
}

inline half BlinnPhongNormalizedTerm (half NdotH, half n)
{
	half normTerm = (n + 1.0) / (2.0 * 3.14159f);
	half specTerm = pow (NdotH, n);
	return specTerm * normTerm;
}

//-------------------------------------------------------------------------------------

// TBD: move to UnityShaderVariables.cginc
half4 unity_SpecCubeParams; 
#ifdef SHADER_API_D3D11
	TextureCube unity_SpecCube;
	SamplerState samplerunity_SpecCube;
#define SampleCubeReflection(env, dir, lod) env.SampleLevel(sampler##env, dir, lod)
#else
	samplerCUBE unity_SpecCube;
#ifdef SHADER_API_SM2
#define SampleCubeReflection(env, dir,  lod) texCUBEbias(env, half4(dir, lod))
#else
#define SampleCubeReflection(env, dir,  lod) texCUBElod(env, half4(dir,lod))
#endif
#endif
half4 unity_SpecCube_HDR;


// Decodes HDR textures
// handles dLDR, RGBM formats
// Modified version of DecodeHDR from UnityCG.cginc
inline half3 DecodeHDR_NoLinearSupportInSM2 (fixed4 data, half4 decodeInstructions)
{
	// GLES2.0 support only Gamma mode, we can skip exponent
	// In Universal shader SM2.0 is never used in combination with SM3.0, so we CAN skip exponent too
	#if defined (SHADER_API_SM2) || (defined(SHADER_API_GLES) && defined(SHADER_API_MOBILE))
		return (data.a * decodeInstructions.x) * data.rgb;
	#else
		return (decodeInstructions.x * pow(data.a, decodeInstructions.y)) * data.rgb;
	#endif
}

half3 Unity_GlossyEnvironment (half3 worldNormal, half roughness)
{
	half4 rgbm = SampleCubeReflection(unity_SpecCube, worldNormal.xyz, roughness * UNITY_SPECCUBE_LOD_STEPS);
	return DecodeHDR_NoLinearSupportInSM2 (rgbm, unity_SpecCube_HDR);
}

//-------------------------------------------------------------------------------------

/**
* Main entry point to Physically Based BRDF.
* Derived from Disney work and based on modified Cook-Torrance with BlinnPhong as NDF and Schlick approximation for Fresnel.
*
*/
half4 BRDF1_Unity_PBS (half3 baseColor, half3 specColor, half reflectivity, half roughness, half3 normal, half3 viewDir, UnityLight light, half3 specGI)
{
	half3 halfDir = normalize (light.dir + viewDir);

	half nl = light.ndotl;
	half nh = BlinnTerm (normal, halfDir);
	half nv = DotClamped (normal, viewDir);
	half vh = DotClamped (viewDir, halfDir);
	half lv = DotClamped (light.dir, viewDir);
	half lh = DotClamped (light.dir, halfDir);

	half F = FresnelTerm (reflectivity, vh);
	half G = GeometricTerm (nl, nh, nv, vh);
	half R = BlinnPhongNormalizedTerm (nh, RoughnessToSpecPower (roughness));
	R = max (0, R);

	half Fd90 = 0.5 + 2 * pow(lh, 2) * roughness;

	// 1.00001 here to prevent from argument going just slightly below
	// zero due to floating point. Having NaNs here is not nice.
	half nlPow = pow((1.00001-nl), 5);
	half nvPow = pow((1.00001-nv), 5);

	half disneyDiffuse = (1 +(Fd90 - 1)*nlPow) * (1 + (Fd90 - 1)*nvPow);
	
	half specularTerm = max(0, (F * G * R) / (4 * nv + 1e-5f) ); // Torrance-Sparrow model
	half diffuseTerm = disneyDiffuse * nl;

	half3 diffuseColor = baseColor;
	#ifdef UNITY_BRDF_WITH_ASPERITY
	half fresnel =  (saturate(0.5 - roughness) * 2) * FresnelTerm(0, nv);
    half3 color =    diffuseColor * (light.ambient + lightColor * diffuseTerm) //Diffuse term
                    + saturate(specColor + fresnel) * (specGI + light.color * specularTerm) //spec term
                    + 16 * specColor * saturate(roughness-0.5) * 2 * light.ambient * FresnelTerm(0, nv); //Asperity term
		#else
	half3 color =	diffuseColor * (light.ambient + light.color * diffuseTerm)
					+ specColor * (specGI + (light.color * specularTerm))
					+ (1-reflectivity) * (1-roughness) * FresnelTerm(0, nv) * specGI;
	#endif
	return half4(color, FresnelTerm(0, nv) * (1-roughness));
}

half4 BRDF2_Unity_PBS (half3 baseColor, half3 specColor, half reflectivity, half roughness, half3 normal, half3 viewDir, UnityLight light, half3 specGI)
{
	half3 halfDir = normalize (light.dir + viewDir);

	half nl = light.ndotl;
	half nh = BlinnTerm (normal, halfDir);
	half nv = DotClamped (normal, viewDir);
	half lh = DotClamped (light.dir, halfDir);

	half specularPower = RoughnessToSpecPower (roughness);
	half Pi30 = (3.141592653589793 * 30);
	half specularTerm = ((specularPower + 1) * pow (nh, specularPower)) / (Pi30 * lh + 1e-5f); // slightly different from original
	half diffuseTerm = nl;
	half fresnelTerm = FresnelTermFast(0, nv);
	half grazingTerm = (1-reflectivity) * (1-roughness) * fresnelTerm;

	half3 diffuseColor = baseColor;

	half3 color =	diffuseColor * (light.ambient + light.color * diffuseTerm)
					+ specColor * (specGI + (light.color * specularTerm))
					+ specGI * grazingTerm;
	return half4(color, fresnelTerm * (1-roughness));
}

sampler2D unity_NHxRoughness;
half4 BRDF3_Unity_PBS (half3 baseColor, half3 specColor, half reflectivity, half roughness, half3 normal, half3 viewDir, UnityLight light, half3 specGI)
{
	half3 halfDir = normalize (light.dir + viewDir);

	half nl = light.ndotl;
	half nh = BlinnTerm (normal, halfDir);
	half nv = DotClamped (normal, viewDir);

//			half specularTerm = BlinnPhongNormalizedTerm (nh, RoughnessToSpecPower (roughness));
	half specularTerm = tex2D(unity_NHxRoughness, half2(dot(normal, halfDir), roughness)).UNITY_ATTEN_CHANNEL * 16 * nl;
	half diffuseTerm = nl;
	half fresnelTerm = FresnelTermFast(0, nv);
	half grazingTerm = (1-reflectivity) * (1-roughness) * fresnelTerm;

	half3 diffuseColor = baseColor;

	half3 color =	diffuseColor * (light.ambient + light.color * diffuseTerm)
					+ specColor * (specGI + light.color * specularTerm)
					+ specGI * grazingTerm;
	return half4(color, fresnelTerm * (1-roughness));
}


#endif // UNITY_UNIVERSAL_BRDF_INCLUDED
