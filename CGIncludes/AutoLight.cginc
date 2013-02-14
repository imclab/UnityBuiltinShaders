// ------------ Shadow helpers --------

// -------- Native shadow maps
#if defined SHADOWS_NATIVE

#define SHADOW_COORDS float4 _ShadowCoord; float _ShadowFade;
float4x4 _World2Shadow;
float4 _LightShadowData;
#ifdef SHADER_API_OPENGL
#define TRANSFER_SHADOW(a) a._ShadowCoord = mul( _World2Shadow, mul(_Object2World,v.vertex) ); a._ShadowFade = (-mul(glstate.matrix.modelview[0],v.vertex).z) * _LightShadowData.z + _LightShadowData.w;
#else
#define TRANSFER_SHADOW(a) a._ShadowCoord = mul( _World2Shadow, mul(_Object2World,v.vertex) ); a._ShadowFade = ( mul(glstate.matrix.modelview[0],v.vertex).z) * _LightShadowData.z + _LightShadowData.w;
#endif
uniform sampler2D _ShadowMapTexture;

#if defined SHADOWS_PCF4
uniform float4 _ShadowOffsets[4];
#endif

inline half unitySampleShadow( float4 shadowCoord, half fade )
{
	#if defined SHADOWS_PCF4
	float3 coord = shadowCoord.xyz / shadowCoord.w;
	
	float4 shadowVals;
	shadowVals.x = tex2D( _ShadowMapTexture, coord + _ShadowOffsets[0].xy ).r;
	shadowVals.y = tex2D( _ShadowMapTexture, coord + _ShadowOffsets[1].xy ).r;
	shadowVals.z = tex2D( _ShadowMapTexture, coord + _ShadowOffsets[2].xy ).r;
	shadowVals.w = tex2D( _ShadowMapTexture, coord + _ShadowOffsets[3].xy ).r;
	float4 shadows = (shadowVals < coord.zzzz) ? _LightShadowData.rrrr : float4(1.0,1.0,1.0,1.0);	
	
	// average-4 PCF
	half shadow = dot( shadows, half4(0.25,0.25,0.25,0.25) );
	
	// real bilinear PCF
	//float2 fr = frac(coord.xy*512.0+0.5);
	//float2 shd = lerp( shadows.xy, shadows.zw, fr.x );
	//half shadow = lerp( shd.x, shd.y, fr.y );
	
	#else
	
	// Native sampling of depth textures is broken on Intel 10.4.8, and does not exist on PPC.
	// So sample manually :(
	float shadow = tex2Dproj( _ShadowMapTexture, shadowCoord.xyw ).r < (shadowCoord.z / shadowCoord.w) ? _LightShadowData.r : 1.0;
	
	#endif
	
	return saturate(shadow + saturate(fade));
}
#define SHADOW_ATTENUATION(a) unitySampleShadow(a._ShadowCoord,a._ShadowFade)

#endif


// -------- Cube shadow maps
#if defined SHADOWS_CUBE

#define SHADOW_COORDS float3 _ShadowCoord;
float4 _LightShadowData;
#define TRANSFER_SHADOW(a) a._ShadowCoord = mul(_Object2World, v.vertex).xyz - _LightPositionRange.xyz;

uniform samplerCUBE _ShadowMapTexture;
inline float unityCubeShadow( float3 vec )
{
	float mydist = length(vec) * _LightPositionRange.w;
	mydist *= 0.97; // bias
	float4 packDist = texCUBE( _ShadowMapTexture, vec );
	float dist = DecodeFloatRGBA( packDist );
	return dist < mydist ? _LightShadowData.r : 1.0;
}
#define SHADOW_ATTENUATION(a) unityCubeShadow(a._ShadowCoord)

#endif


// -------- Screen space shadow maps
#if defined SHADOWS_SCREEN

uniform float4 _ShadowOffsets[4];

#define SHADOW_COORDS float3 _ShadowCoord;
inline float3 unityTransferShadow( float4 hpos )
{
	float3x4 mat= float3x4 (
		0.5, 0, 0, 0.5,
		0, 0.5 * _ProjectionParams.x, 0, 0.5,
		0, 0, 0, 1
	);
	float3 coord = mul(mat, hpos);
	#ifdef SHADER_API_OPENGL
	coord.xy *= 0.5 / _ShadowOffsets[3].xy;
	#endif
	return coord;
}
#define TRANSFER_SHADOW(a) a._ShadowCoord = unityTransferShadow(o.pos);
uniform samplerRECT _ShadowMapTexture;

inline half unitySampleShadow( float3 shadowCoord )
{
	//#ifndef SHADOWS_PCF4
	
	half shadow = texRECTproj( _ShadowMapTexture, shadowCoord ).r;
	
	/*
	#else
	half4 shadowVals;
	float off = 15.0;
	shadowVals.x = texRECTproj( _ShadowMapTexture, shadowCoord + float3(-off,-off,0) ).r;
	shadowVals.y = texRECTproj( _ShadowMapTexture, shadowCoord + float3( off,-off,0) ).r;
	shadowVals.z = texRECTproj( _ShadowMapTexture, shadowCoord + float3(-off, off,0) ).r;
	shadowVals.w = texRECTproj( _ShadowMapTexture, shadowCoord + float3( off, off,0) ).r;
	half shadow = dot( shadowVals, half4(0.25,0.25,0.25,0.25) );
	#endif
	*/
	
	return shadow;
}
#define SHADOW_ATTENUATION(a) unitySampleShadow(a._ShadowCoord)

#endif


// -------- Shadows off
#if !defined SHADOWS_CUBE && !defined SHADOWS_NATIVE && !defined SHADOWS_SCREEN

#define SHADOW_COORDS
#define TRANSFER_SHADOW(a)
#define SHADOW_ATTENUATION(a) 1.0

#endif



// ------------ Light helpers --------

#ifdef POINT
#define LIGHTING_COORDS float3 _LightCoord; SHADOW_COORDS
uniform sampler3D _LightTexture0;
uniform float4x4 _SpotlightProjectionMatrix0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_SpotlightProjectionMatrix0, v.vertex).xyz; TRANSFER_SHADOW(a)
#ifdef SHADER_API_D3D9
#define LIGHT_ATTENUATION(a)	(tex3D(_LightTexture0, a._LightCoord).r * SHADOW_ATTENUATION(a))
#else
#define LIGHT_ATTENUATION(a)	(tex3D(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#endif
#endif


#ifdef SPOT
#define LIGHTING_COORDS float4 _LightCoord; SHADOW_COORDS
uniform sampler2D _LightTexture0;
uniform float4x4 _SpotlightProjectionMatrix0;
uniform sampler2D _LightTextureB0;
uniform float4x4 _SpotlightProjectionMatrixB0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord.w = mul(_SpotlightProjectionMatrixB0, v.vertex).z; a._LightCoord.xyz = mul(_SpotlightProjectionMatrix0, v.vertex).xyw; TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	(tex2Dproj (_LightTexture0, a._LightCoord.xyz).w * tex2D (_LightTextureB0, a._LightCoord.ww).w * SHADOW_ATTENUATION(a)) 
#endif 


#ifdef DIRECTIONAL
#define LIGHTING_COORDS SHADOW_COORDS
#define TRANSFER_VERTEX_TO_FRAGMENT(a) TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	SHADOW_ATTENUATION(a)
#endif


#ifdef POINT_NOATT
#define LIGHTING_COORDS SHADOW_COORDS
#define TRANSFER_VERTEX_TO_FRAGMENT(a) TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	SHADOW_ATTENUATION(a)
#endif


#ifdef POINT_COOKIE
#define LIGHTING_COORDS float3 _LightCoord; SHADOW_COORDS
uniform samplerCUBE _LightTexture0;
uniform float4x4 _SpotlightProjectionMatrix0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_SpotlightProjectionMatrix0, v.vertex).xyz; TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	(texCUBE(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#endif


#ifdef DIRECTIONAL_COOKIE
#define LIGHTING_COORDS float2 _LightCoord; SHADOW_COORDS
uniform sampler2D _LightTexture0;
uniform float4x4 _SpotlightProjectionMatrix0;
#define TRANSFER_VERTEX_TO_FRAGMENT(a) a._LightCoord = mul(_SpotlightProjectionMatrix0, v.vertex).xy; TRANSFER_SHADOW(a)
#define LIGHT_ATTENUATION(a)	(tex2D(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#endif

