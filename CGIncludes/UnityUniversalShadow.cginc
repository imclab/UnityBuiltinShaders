#ifndef UNITY_UNIVERSAL_SHADOW_INCLUDED
#define UNITY_UNIVERSAL_SHADOW_INCLUDED

// NOTE: had to split shadow functions into separate file,
// otherwise compiler gives trouble with LIGHTING_COORDS macro (in UnityUniversalCore.cginc)


#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"

// Do dithering for alpha blended shadows on SM3+/desktop;
// on lesser systems do simple alpha-tested shadows
#if defined(_ALPHABLEND_ON) && !(defined(SHADER_API_SM2) || defined (SHADER_API_MOBILE) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
#define UNIVERSAL_USE_DITHER_MASK 1
#endif

// Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
#if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
#define UNIVERSAL_USE_SHADOW_UVS 1
#endif

// Has a non-empty shadow caster output struct (it's an error to have empty structs on some platforms...)
#if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNIVERSAL_USE_SHADOW_UVS)
#define UNIVERSAL_USE_SHADOW_OUTPUT_STRUCT 1
#endif


half4		_Color;
half		_AlphaTestRef;
sampler2D	_MainTex;
float4		_MainTex_ST;
#ifdef UNIVERSAL_USE_DITHER_MASK
sampler3D	_DitherMaskLOD;
#endif
		
struct VertexInput
{
	float4 vertex	: POSITION;
	float2 uv0		: TEXCOORD0;
};

#ifdef UNIVERSAL_USE_SHADOW_OUTPUT_STRUCT
struct VertexOutputShadowCaster
{
	V2F_SHADOW_CASTER_NOPOS
	#if defined(UNIVERSAL_USE_SHADOW_UVS)
		float2 tex : TEXCOORD1;
	#endif
};
#endif


// We have to do these dances of outputting SV_POSITION separately from the vertex shader,
// and inputting VPOS in the pixel shader, since they both map to "POSITION" semantic on
// some platforms, and then things don't go well.


void vertShadowCaster (VertexInput v,
	#ifdef UNIVERSAL_USE_SHADOW_OUTPUT_STRUCT
	out VertexOutputShadowCaster o,
	#endif
	out float4 opos : SV_POSITION)
{
	TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
	#if defined(UNIVERSAL_USE_SHADOW_UVS)
		o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
	#endif
}

half4 fragShadowCaster (
	#ifdef UNIVERSAL_USE_SHADOW_OUTPUT_STRUCT
	VertexOutputShadowCaster i
	#endif
	#ifdef UNIVERSAL_USE_DITHER_MASK
	, UNITY_VPOS_TYPE vpos : VPOS
	#endif
	) : SV_Target
{
	#if defined(UNIVERSAL_USE_SHADOW_UVS)
		half alpha = tex2D(_MainTex, i.tex).a * _Color.a;
		#if defined(_ALPHATEST_ON)
			clip (alpha - _AlphaTestRef);
		#endif
		#if defined(_ALPHABLEND_ON)
			#ifdef UNIVERSAL_USE_DITHER_MASK
				// Use dither mask for alpha blended shadows, based on pixel position xy
				// and alpha level. Our dither texture is 4x4x16.
				half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,alpha*0.9375)).a;
				clip (alphaRef - 0.01);
			#else
				clip (alpha - _AlphaTestRef);
			#endif
		#endif
	#endif // #if defined(UNIVERSAL_USE_SHADOW_UVS)

	SHADOW_CASTER_FRAGMENT(i)
}			

#endif // UNITY_UNIVERSAL_SHADOW_INCLUDED
