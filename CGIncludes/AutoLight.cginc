#ifndef AUTOLIGHT_INCLUDED
#define AUTOLIGHT_INCLUDED


// ------------ Shadow helpers --------

// -------- Screen space shadow maps
#if defined (SHADOWS_SCREEN)

uniform float4 _ShadowOffsets[4];

#define SHADOW_COORDS(idx1) float4 _ShadowCoord : TEXCOORD##idx1;
#define TRANSFER_SHADOW(a) a._ShadowCoord = ComputeScreenPos(o.pos);
uniform sampler2D _ShadowMapTexture;

inline half unitySampleShadow (float4 shadowCoord)
{
	half shadow = tex2Dproj( _ShadowMapTexture, UNITY_PROJ_COORD(shadowCoord) ).r;
	return shadow;
}
#define SHADOW_ATTENUATION(a) unitySampleShadow(a._ShadowCoord)

#endif


// -------- Shadows off
#if !defined (SHADOWS_SCREEN)

#define SHADOW_COORDS(idx1)
#define TRANSFER_SHADOW(a)
#define SHADOW_ATTENUATION(a) 1.0


#endif



// ------------ Light helpers --------

#ifdef POINT
#define LIGHTING_COORDS(idx1,idx2) float3 _LightCoord : TEXCOORD##idx1;
uniform sampler2D _LightTexture0;
uniform float4x4 _LightMatrix0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_LightMatrix0, mul(_Object2World, v.vertex)).xyz;
#define LIGHT_ATTENUATION(a)	(tex2D(_LightTexture0, dot(a._LightCoord,a._LightCoord).rr).UNITY_ATTEN_CHANNEL)
#endif

#ifdef SPOT
#define LIGHTING_COORDS(idx1,idx2) float4 _LightCoord : TEXCOORD##idx1;
uniform sampler2D _LightTexture0;
uniform float4x4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_LightMatrix0, mul(_Object2World, v.vertex));
inline float UnitySpotCookie(float4 LightCoord)
{
	return tex2D(_LightTexture0, LightCoord.xy / LightCoord.w + 0.5).w;
}
inline float UnitySpotAttenuate(float3 LightCoord)
{
	return tex2D(_LightTextureB0, dot(LightCoord, LightCoord).xx).UNITY_ATTEN_CHANNEL;
}
#define LIGHT_ATTENUATION(a)	( (a._LightCoord.z > 0) * UnitySpotCookie(a._LightCoord) * UnitySpotAttenuate(a._LightCoord.xyz) )
#endif


#ifdef DIRECTIONAL
#define LIGHTING_COORDS(idx1,idx2) SHADOW_COORDS(idx1)
#define TRANSFER_VERTEX_TO_FRAGMENT(a) TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	SHADOW_ATTENUATION(a)
#endif


#ifdef POINT_COOKIE
#define LIGHTING_COORDS(idx1,idx2) float3 _LightCoord : TEXCOORD##idx1;
uniform samplerCUBE _LightTexture0;
uniform float4x4 _LightMatrix0;
uniform sampler2D _LightTextureB0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_LightMatrix0, mul(_Object2World, v.vertex)).xyz;
#define LIGHT_ATTENUATION(a)	(tex2D(_LightTextureB0, dot(a._LightCoord,a._LightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, a._LightCoord).w)
#endif

#ifdef DIRECTIONAL_COOKIE
#define LIGHTING_COORDS(idx1,idx2) float2 _LightCoord : TEXCOORD##idx1; SHADOW_COORDS(idx2)
uniform sampler2D _LightTexture0;
uniform float4x4 _LightMatrix0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_LightMatrix0, mul(_Object2World, v.vertex)).xy; TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	(tex2D(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#endif


#endif
