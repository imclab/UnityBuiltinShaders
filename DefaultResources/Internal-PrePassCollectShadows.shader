// Collects cascaded shadows into screen space buffer ready for blurring
Shader "Hidden/Internal-PrePassCollectShadows" {
Properties {
	_ShadowMapTexture ("", any) = "" {}
}

CGINCLUDE
#include "UnityCG.cginc"
struct appdata {
	float4 vertex : POSITION;
	float2 texcoord : TEXCOORD0;
	float3 normal : NORMAL;
};

struct v2f {
	float2 uv : TEXCOORD0;

	// View space ray, for perspective case
	float3 ray : TEXCOORD1;
	// Orthographic view space position, xy regular, z position at near plane, w position at far plane
	float4 orthoPos : TEXCOORD2;

	float4 pos : SV_POSITION;
};

v2f vert (appdata v)
{
	v2f o;
	o.uv = v.texcoord;
	o.ray = v.normal;
	float4 clipPos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.pos = clipPos;

	// To compute view space position from Z buffer for orthographic case,
	// we need different code than for perspective case. We want to avoid
	// doing matrix multiply in the pixel shader: less operations, and less
	// constant registers used. Particularly with constant registers, having
	// unity_CameraInvProjection in the pixel shader would push the PS over SM2.0
	// limits.

	clipPos.y *= _ProjectionParams.x;
	float4 orthoNearPos = mul(unity_CameraInvProjection, float4(clipPos.x,clipPos.y,-1,1));
	float4 orthoFarPos = mul(unity_CameraInvProjection, float4(clipPos.x,clipPos.y,1,1));
	o.orthoPos = float4(orthoNearPos.x, orthoNearPos.y, -orthoNearPos.z, -orthoFarPos.z);

	return o;
}
sampler2D_float _CameraDepthTexture;
float4 unity_ShadowBlurParams;
float4 unity_ShadowMapSize;

CBUFFER_START(UnityPerCamera2)
float4x4 _CameraToWorld;
CBUFFER_END

UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);

//
// Keywords based defines
//
#if defined (SHADOWS_SPLIT_SPHERES)
	#define GET_CASCADE_WEIGHTS(wpos, z)    getCascadeWeights_splitSpheres(wpos)
	#define GET_SHADOW_FADE(wpos, z)		getShadowFade_SplitSpheres(wpos)
#else
	#define GET_CASCADE_WEIGHTS(wpos, z)	getCascadeWeights( wpos, z )
	#define GET_SHADOW_FADE(wpos, z)		getShadowFade(z)
#endif

#if defined (SHADOWS_SINGLE_CASCADE)
	#define GET_SHADOW_COORDINATES(wpos,z)	getShadowCoord_SingleCascade(wpos)
#else
	#define GET_SHADOW_COORDINATES(wpos,z)	getShadowCoord(wpos,z)
#endif

// prototypes 
inline fixed4 getCascadeWeights(float3 wpos, float z);		// calculates the cascade weights based on the world position of the fragment and plane positions
inline fixed4 getCascadeWeights_splitSpheres(float3 wpos);	// calculates the cascade weights based on world pos and split spheres positions
inline float  getShadowFade_SplitSpheres( float3 wpos );	
inline float  getShadowFade( float3 wpos, float z );
inline float4 getShadowCoord_SingleCascade( float4 wpos );	// converts the shadow coordinates for shadow map using the world position of fragment (optimized for single fragment)
inline float4 getShadowCoord( float4 wpos, float z );		// converts the shadow coordinates for shadow map using the world position of fragment
half 		  sampleShadowmap_PCF5x5 (float4 coord);		// samples the shadowmap based on PCF filtering (5x5 kernel)
half 		  unity_sampleShadowmap( float4 coord );		// sample shadowmap SM2.0+

/**
 * Gets the cascade weights based on the world position of the fragment.
 * Returns a float4 with only one component set that corresponds to the appropriate cascade.
 */
inline fixed4 getCascadeWeights(float3 wpos, float z)
{
	fixed4 zNear = float4( z >= _LightSplitsNear );
	fixed4 zFar = float4( z < _LightSplitsFar );
	fixed4 weights = zNear * zFar;
	return weights;
}

/**
 * Gets the cascade weights based on the world position of the fragment and the poisitions of the split spheres for each cascade.
 * Returns a float4 with only one component set that corresponds to the appropriate cascade.
 */
inline fixed4 getCascadeWeights_splitSpheres(float3 wpos)
{
	float3 fromCenter0 = wpos.xyz - unity_ShadowSplitSpheres[0].xyz;
	float3 fromCenter1 = wpos.xyz - unity_ShadowSplitSpheres[1].xyz;
	float3 fromCenter2 = wpos.xyz - unity_ShadowSplitSpheres[2].xyz;
	float3 fromCenter3 = wpos.xyz - unity_ShadowSplitSpheres[3].xyz;
	float4 distances2 = float4(dot(fromCenter0,fromCenter0), dot(fromCenter1,fromCenter1), dot(fromCenter2,fromCenter2), dot(fromCenter3,fromCenter3));
	fixed4 weights = float4(distances2 < unity_ShadowSplitSqRadii);
	weights.yzw = saturate(weights.yzw - weights.xyz);
	return weights;
}

/**
 * Returns the shadow fade based on the 'z' position of the fragment
 */
inline float getShadowFade( float z )
{
	return saturate(z * _LightShadowData.z + _LightShadowData.w);
}

/**
 * Returns the shadow fade based on the world position of the fragment, and the distance from the shadow fade center
 */
inline float getShadowFade_SplitSpheres( float3 wpos )
{	
	float sphereDist = distance(wpos.xyz, unity_ShadowFadeCenterAndType.xyz);
	half shadowFade = saturate(sphereDist * _LightShadowData.z + _LightShadowData.w);
	return shadowFade;	
}

/**
 * Returns the shadowmap coordinates for the given fragment based on the world position and z-depth.
 * These coordinates belong to the shadowmap atlas that contains the maps for all cascades.
 */
inline float4 getShadowCoord( float4 wpos, float z )
{
	float4 cascadeWeights = GET_CASCADE_WEIGHTS(wpos,z);

	float3 sc0 = mul (unity_World2Shadow[0], wpos).xyz;
	float3 sc1 = mul (unity_World2Shadow[1], wpos).xyz;
	float3 sc2 = mul (unity_World2Shadow[2], wpos).xyz;
	float3 sc3 = mul (unity_World2Shadow[3], wpos).xyz;
	return float4(sc0 * cascadeWeights[0] + sc1 * cascadeWeights[1] + sc2 * cascadeWeights[2] + sc3 * cascadeWeights[3], 1);
}

/**
 * Same as the getShadowCoord; but optimized for single cascade
 */
inline float4 getShadowCoord_SingleCascade( float4 wpos )
{
	return float4( mul (unity_World2Shadow[0], wpos).xyz, 0);
}

/**
 * PCF shadowmap filtering based on a 5x5 kernel (optimized with 9 taps)
 *
 * Algorithm: http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/
 * Implementation example: http://mynameismjp.wordpress.com/2013/09/10/shadow-maps/
 */
half sampleShadowmap_PCF5x5 (float4 coord)
{
	const float2 offset = float2(0.5,0.5);
	float2 uv = (coord.xy * unity_ShadowMapSize.xy) + offset;
	float2 base_uv = (floor(uv) - offset)* unity_ShadowMapSize.zw;
	float2 st = frac(uv);

	float3 uw = float3( 4-3*st.x, 7, 1+3*st.x );
	float3 u = float3( (3-2*st.x) / uw.x - 2, (3+st.x)/uw.y, st.x/uw.z + 2 );
	u *= unity_ShadowMapSize.z;

	float3 vw = float3( 4-3*st.y, 7, 1+3*st.y );
	float3 v = float3( (3-2*st.y) / vw.x - 2, (3+st.y)/vw.y, st.y/vw.z + 2 );
	v *= unity_ShadowMapSize.w;

	float sum = 0.0f;

#if defined (SHADOWS_NATIVE)
	float3 accum = uw * vw.x;
	sum += accum.x * UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.x,v.x), coord.z ) );
    sum += accum.y * UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.y,v.x), coord.z ) );
    sum += accum.z * UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.z,v.x), coord.z ) );

	accum = uw * vw.y;
    sum += accum.x *  UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.x,v.y), coord.z ) );
    sum += accum.y *  UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.y,v.y), coord.z ) );
    sum += accum.z *  UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.z,v.y), coord.z ) );

	accum = uw * vw.z;
    sum += accum.x * UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.x,v.z), coord.z ) );
    sum += accum.y * UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.y,v.z), coord.z ) );
    sum += accum.z * UNITY_SAMPLE_SHADOW( _ShadowMapTexture, float3( base_uv + float2(u.z,v.z), coord.z ) );
#else //SHADOWS_NATIVE

	float3 accum = uw * vw.x;
	sum += accum.x * (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.x,v.x)) < coord.z ? 0.0f : 1.0f ));
    sum += accum.y * (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.y,v.x)) < coord.z ? 0.0f : 1.0f ));
    sum += accum.z * (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.z,v.x)) < coord.z ? 0.0f : 1.0f ));

	accum = uw * vw.y;
    sum += accum.x *  (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.x,v.y)) < coord.z ? 0.0f : 1.0f ));
    sum += accum.y *  (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.y,v.y)) < coord.z ? 0.0f : 1.0f ));
    sum += accum.z *  (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.z,v.y)) < coord.z ? 0.0f : 1.0f ));

	accum = uw * vw.z;
    sum += accum.x * (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.x,v.z)) < coord.z ? 0.0f : 1.0f ));
    sum += accum.y * (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.y,v.z)) < coord.z ? 0.0f : 1.0f ));
    sum += accum.z * (SAMPLE_DEPTH_TEXTURE( _ShadowMapTexture, float2( base_uv + float2(u.z,v.z)) < coord.z ? 0.0f : 1.0f ));
#endif

    float shadow = sum / 144.0f;
    shadow = lerp (_LightShadowData.r, 1.0f, shadow);
    return shadow;
}

/**
 *	Samples the shadowmap at the given coordinates.
 */
half unity_sampleShadowmap( float4 coord )
{
#if defined (SHADOWS_NATIVE)
	half shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture,coord);
	shadow = lerp(_LightShadowData.r, 1.0, shadow);
#else
	half shadow = SAMPLE_DEPTH_TEXTURE(_ShadowMapTexture, coord.xy) < coord.z ? _LightShadowData.r : 1.0;
#endif

	return shadow;
}

fixed4 frag (v2f i) : SV_Target
{
	float zdepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

	// 0..1 linear depth, 0 at near plane, 1 at far plane.
	float depth = lerp (Linear01Depth(zdepth), zdepth, unity_OrthoParams.w);

	// view position calculation for perspective & ortho cases
	float3 vposPersp = i.ray * depth;
	float3 vposOrtho = i.orthoPos.xyz;
	vposOrtho.z = lerp(i.orthoPos.z, i.orthoPos.w, zdepth);
	// pick the perspective or orho position as needed
	float3 vpos = lerp (vposPersp, vposOrtho, unity_OrthoParams.w);

	float4 wpos = mul (_CameraToWorld, float4(vpos,1));

	half shadow = unity_sampleShadowmap( GET_SHADOW_COORDINATES(wpos, vpos.z) );
	shadow += GET_SHADOW_FADE(wpos, vpos.z);

	fixed4 res;
	res.x = shadow;
	res.y = 1.0;
	// convert from full depth range to shadow range
	res.zw = EncodeFloatRG (1 - depth * unity_ShadowBlurParams.z);
	return res;	
}
ENDCG

SubShader {
Pass {
	ZWrite Off ZTest Always Cull Off

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma multi_compile_shadowcollector

	ENDCG
}
}

// Subshader based on PCF 5x5 filtering
Subshader {
	Tags {"ShadowmapFilter"="PCF_5x5"}

Pass {
	ZWrite Off ZTest Always Cull Off

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag_pcf5x5
	#pragma multi_compile_shadowcollector
	#pragma target 3.0

	// 3.0 fragment shader
	fixed4 frag_pcf5x5 (v2f i) : SV_Target
	{
		float zdepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		// 0..1 linear depth, 0 at near plane, 1 at far plane.
		float depth = lerp (Linear01Depth(zdepth), zdepth, unity_OrthoParams.w);

		// view position calculation for perspective & ortho cases
		float3 vposPersp = i.ray * depth;
		float3 vposOrtho = i.orthoPos.xyz;
		vposOrtho.z = lerp(i.orthoPos.z, i.orthoPos.w, zdepth);
		// pick the perspective or orho position as needed
		float3 vpos = lerp (vposPersp, vposOrtho, unity_OrthoParams.w);

		float4 wpos = mul (_CameraToWorld, float4(vpos,1));
		half shadow = sampleShadowmap_PCF5x5( GET_SHADOW_COORDINATES(wpos, vpos.z) );
		shadow += GET_SHADOW_FADE(wpos, vpos.z);

		return float4( shadow, 1.0f, 1.0f, 1.0f );
	}
	ENDCG
}
}
SubShader {
Pass {
	ZWrite Off ZTest Always Cull Off

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma multi_compile_shadowcollector

	ENDCG
}
} // pcf 5x5 subshader
Fallback Off
}
