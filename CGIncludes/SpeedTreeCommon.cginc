#ifndef SPEEDTREE_COMMON_INCLUDED
#define SPEEDTREE_COMMON_INCLUDED

#define SPEEDTREE_Y_UP

#if defined(GEOM_TYPE_BRANCH_DETAIL) || defined(GEOM_TYPE_BRANCH_BLEND)
	#define GEOM_TYPE_BRANCH
#endif

#if defined(GEOM_TYPE_FROND) || defined(GEOM_TYPE_LEAF) || defined(GEOM_TYPE_FACING_LEAF)
	#define ENABLE_ALPHATEST
	uniform half _Cutoff;
#endif

#include "SpeedTreeVertex.cginc"

uniform sampler2D _MainTex;
uniform half4 _Color;
uniform half _Shininess;

#ifdef GEOM_TYPE_BRANCH_DETAIL
	uniform sampler2D _DetailTex;
#endif

#ifdef EFFECT_BUMP
	uniform sampler2D _BumpMap;
#endif

#ifdef LOD_FADE_CROSSFADE
	uniform sampler2D _DitherMaskLOD2D;
#endif

struct Input
{
	half4 interpolator1;
	#if defined(GEOM_TYPE_BRANCH_DETAIL) || defined(GEOM_TYPE_BRANCH_BLEND)
		half3 interpolator2;
	#endif

	#ifdef LOD_FADE_CROSSFADE
		half3 myScreenPos;
	#endif
};

#define uv_MainTex interpolator1.xy
#define AmbientOcclusion interpolator1.z
#ifdef EFFECT_HUE_VARIATION
	#define HueVariationAmount interpolator1.w
	uniform half4 _HueVariation;
#endif
#ifdef GEOM_TYPE_BRANCH_DETAIL
	#define Detail interpolator2.xy
#endif
#ifdef GEOM_TYPE_BRANCH_BLEND
	#define BranchBlend interpolator2
#endif

void vert(inout SpeedTreeVB IN, out Input OUT)
{
	UNITY_INITIALIZE_OUTPUT(Input, OUT);

	OUT.uv_MainTex = IN.texcoord.xy;
	OUT.AmbientOcclusion = IN.color.r;

	#ifdef EFFECT_HUE_VARIATION
		float hueVariationAmount = frac(_Object2World[0].w + _Object2World[1].w + _Object2World[2].w);
		hueVariationAmount += frac(IN.vertex.x + IN.normal.y + IN.normal.x) * 0.5 - 0.3;
		OUT.HueVariationAmount = saturate(hueVariationAmount * _HueVariation.a);
	#endif

	#ifdef GEOM_TYPE_BRANCH_DETAIL
		OUT.Detail = IN.texcoord2.xy;
	#endif

	#ifdef GEOM_TYPE_BRANCH_BLEND
		OUT.BranchBlend = float3(IN.texcoord2.zw, IN.texcoord1.w);
	#endif

	#ifdef LOD_FADE_CROSSFADE
		float4 pos = mul(UNITY_MATRIX_MVP, IN.vertex);
		OUT.myScreenPos = ComputeScreenPos(pos).xyw;
		OUT.myScreenPos.xy *= _ScreenParams.xy * 0.25;
	#endif

	OffsetSpeedTreeVertex(IN, unity_LODFade.x);
}

void surf(Input IN, inout SurfaceOutput OUT)
{
	#ifdef LOD_FADE_CROSSFADE
		half2 projUV = IN.myScreenPos.xy / IN.myScreenPos.z;
		projUV.y = frac(projUV.y) * 0.0625 + unity_LODFade.y; // quantized lod fade by 16 levels
		clip(tex2D(_DitherMaskLOD2D, projUV).a - 0.5);
	#endif

	half4 diffuseColor = tex2D(_MainTex, IN.uv_MainTex);

	// match alpha scalar in the modeler for A2C
	diffuseColor.a = min(1.0, 2.0 * diffuseColor.a);
	OUT.Alpha = diffuseColor.a * _Color.a;
	#ifdef ENABLE_ALPHATEST
		clip(OUT.Alpha - _Cutoff);
	#endif

	#ifdef GEOM_TYPE_BRANCH_DETAIL
		half4 detailColor = tex2D(_DetailTex, IN.Detail);
		diffuseColor.rgb = lerp(diffuseColor.rgb, detailColor.rgb, detailColor.a);
	#endif

	#ifdef GEOM_TYPE_BRANCH_BLEND
		half4 blendColor = tex2D(_MainTex, IN.BranchBlend.xy);
		half amount = saturate(IN.BranchBlend.z);
		diffuseColor.rgb = lerp(blendColor.rgb, diffuseColor.rgb, amount);
	#endif

	#ifdef EFFECT_HUE_VARIATION
		half3 shiftedColor = lerp(diffuseColor.rgb, _HueVariation.rgb, IN.HueVariationAmount);
		half maxBase = max(diffuseColor.r, max(diffuseColor.g, diffuseColor.b));
		half newMaxBase = max(shiftedColor.r, max(shiftedColor.g, shiftedColor.b));
		maxBase /= newMaxBase;
		maxBase = maxBase * 0.5f + 0.5f;
		// preserve vibrance
		shiftedColor.rgb *= maxBase;
		diffuseColor.rgb = saturate(shiftedColor);
	#endif

	diffuseColor.rgb *= IN.AmbientOcclusion.rrr;

	OUT.Albedo = diffuseColor.rgb * _Color.rgb;
	OUT.Gloss = diffuseColor.a;
	OUT.Specular = _Shininess;

	#ifdef EFFECT_BUMP
		OUT.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
	#endif
}

#endif // SPEEDTREE_COMMON_INCLUDED
