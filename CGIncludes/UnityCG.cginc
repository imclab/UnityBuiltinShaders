#ifndef UNITY_CG_INCLUDED
#define UNITY_CG_INCLUDED

// -------------------------------------------------------------------
//  builtin values exposed from Unity

// Time values from Unity
uniform float4 _Time;
uniform float4 _SinTime;
uniform float4 _CosTime;

// x = 1 or -1 (-1 if projection is flipped)
// y = near plane
// z = far plane
// w = 1/far plane
uniform float4 _ProjectionParams;

uniform float4 _PPLAmbient;

uniform float4 _ObjectSpaceCameraPos;
uniform float4 _ObjectSpaceLightPos0;
uniform float4 _ModelLightColor0;
uniform float4 _SpecularLightColor0;

uniform float4x4 _Light2World0, _World2Light0, _Object2World, _World2Object, _Object2Light0;

uniform float4 _LightDirectionBias; // xyz = direction, w = bias
uniform float4 _LightPositionRange; // xyz = pos, w = 1/range


// -------------------------------------------------------------------
//  helper functions and macros used in many standard shaders

#if defined DIRECTIONAL_COOKIE || defined DIRECTIONAL
#define USING_DIRECTIONAL_LIGHT
#endif

#if defined DIRECTIONAL || defined DIRECTIONAL_COOKIE || defined POINT || defined SPOT || defined POINT_NOATT || defined POINT_COOKIE
#define USING_LIGHT_MULTI_COMPILE
#endif

struct appdata_base {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
};

struct appdata_tan {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
};

// Computes final clip space position and fog parameter
inline void PositionFog( in float4 v, out float4 pos, out float fog )
{
	pos = mul( glstate.matrix.mvp, v );
	fog = pos.z;
}

// Computes object space light direction
inline float3 ObjSpaceLightDir( in float4 v )
{
	#ifndef USING_LIGHT_MULTI_COMPILE
		return _ObjectSpaceLightPos0.xyz - v.xyz * _ObjectSpaceLightPos0.w;
	#else
		#ifndef USING_DIRECTIONAL_LIGHT
		return _ObjectSpaceLightPos0.xyz - v.xyz;
		#else
		return _ObjectSpaceLightPos0.xyz;
		#endif
	#endif
}

// Computes object space view direction
inline float3 ObjSpaceViewDir( in float4 v )
{
	return _ObjectSpaceCameraPos - v.xyz;
}

// Declares 3x3 matrix 'rotation', filled with tangent space basis
#define TANGENT_SPACE_ROTATION \
	float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w; \
	float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal )


// Transforms float2 UV by scale/bias property (new method)
#define TRANSFORM_TEX(tex,name) (tex.xy * name##_ST.xy + name##_ST.zw)
// Transforms float4 UV by a texture matrix (old method)
#define TRANSFORM_UV(idx) mul( glstate.matrix.texture[idx], v.texcoord ).xy

#define V2F_POS_FOG float4 pos : POSITION; float fog : FOGC


// Calculates Lambertian (diffuse) ligting model
inline half4 DiffuseLight( half3 lightDir, half3 normal, half4 color, half atten )
{
	#ifndef USING_DIRECTIONAL_LIGHT
	lightDir = normalize(lightDir);
	#endif
	
	half diffuse = dot( normal, lightDir );
	
	half4 c;
	c.rgb = color.rgb * _ModelLightColor0.rgb * (diffuse * atten * 2);
	c.a = 0; // diffuse passes by default don't contribute to overbright
	return c;
}


// Calculates Blinn-Phong (specular) lighting model
inline half4 SpecularLight( half3 lightDir, half3 viewDir, half3 normal, half4 color, float specK, half atten )
{
	#ifndef USING_DIRECTIONAL_LIGHT
	lightDir = normalize(lightDir);
	#endif
	viewDir = normalize(viewDir);
	half3 h = normalize( lightDir + viewDir );
	
	half diffuse = dot( normal, lightDir );
	
	float nh = saturate( dot( h, normal ) );
	float spec = pow( nh, specK ) * color.a;
	
	half4 c;
	c.rgb = (color.rgb * _ModelLightColor0.rgb * diffuse + _SpecularLightColor0.rgb * spec) * (atten * 2);
	c.a = _SpecularLightColor0.a * spec * atten; // specular passes by default put highlights to overbright
	return c;
}


struct v2f_vertex_lit {
	float2 uv	: TEXCOORD0;
	float4 diff	: COLOR0;
	float4 spec	: COLOR1;
};  

inline half4 VertexLight( v2f_vertex_lit i, sampler2D mainTex )
{
	half4 texcol = tex2D( mainTex, i.uv );
	half4 c;
	c.xyz = ( texcol.xyz * i.diff.xyz + i.spec.xyz * texcol.a ) * 2;
	c.w = texcol.w * i.diff.w;
	return c;
}


// Calculates UV offset for parallax bump mapping
inline float2 ParallaxOffset( half h, half height, half3 viewDir )
{
	h = h * height - height/2.0;
	float3 v = normalize(viewDir);
	v.z += 0.42;
	return h * (v.xy / v.z);
}


// Converts color to luminance (grayscale)
inline half Luminance( half3 c )
{
	return dot( c, half3(0.22, 0.707, 0.071) );
}

// Helpers used in image effects. Most image effects use the same
// minimal vertex shader (vert_img).

struct appdata_img {
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0;
};
struct v2f_img {
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
};

float2 MultiplyUV (float4x4 matrix, float2 inUV) {
	float4 temp = float4 (inUV.x, inUV.y, 0, 0);
	temp = mul (matrix, temp);
	return temp.xy;
}

v2f_img vert_img( appdata_img v )
{
	v2f_img o;
	o.pos = mul (glstate.matrix.mvp, v.vertex);
	o.uv = MultiplyUV( glstate.matrix.texture[0], v.texcoord );
	return o;
}


uniform float4 _RGBAEncodeDot;	// 1.0, 255.0, 65025.0, 160581375.0
uniform float4 _RGBAEncodeBias;	// around -0.5/255.0, depending on hardware
uniform float4 _RGBADecodeDot;	// 1.0, 1/255.0, 1/65025.0, 1/160581375.0


// Encoding/decoding 0..1 floats into 8 bit/channel RGBA
inline float4 EncodeFloatRGBA( float v )
{
	return frac(_RGBAEncodeDot * v) + _RGBAEncodeBias;
}
inline float DecodeFloatRGBA( float4 enc )
{
	return dot( enc, _RGBADecodeDot );
}

// Encoding/decoding 0..1 floats into 8 bit/channel RG
inline float2 EncodeFloatRG( float v )
{
	float2 kEncodeMul = float2(1.0, 255.0);
	float kEncodeBit = 1.0/255.0;
	float2 enc = kEncodeMul * v;
	enc = frac (enc);
	enc.x -= enc.y * kEncodeBit;
	return enc;
}
inline float DecodeFloatRG( float2 enc )
{
	float2 kDecodeDot = float2(1.0, 1/255.0);
	return dot( enc, kDecodeDot );
}


// Encoding/decoding view space normals into 2D 0..1 vector
inline float2 EncodeViewNormalStereo( float3 n )
{
	float kScale = 1.7777;
	float2 enc;
	enc = n.xy / (n.z+1);
	enc /= kScale;
	enc = enc*0.5+0.5;
	return enc;
}
inline float3 DecodeViewNormalStereo( float4 enc4 )
{
	float kScale = 1.7777;
	float3 nn = enc4.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
	float g = 2.0 / dot(nn.xyz,nn.xyz);
	float3 n;
	n.xy = g*nn.xy;
	n.z = g-1;
	return n;
}

inline float4 EncodeDepthNormal( float depth, float3 normal )
{
	float4 enc;
	enc.xy = EncodeViewNormalStereo (normal);
	enc.zw = EncodeFloatRG (depth);
	return enc;
}

inline void DecodeDepthNormal( float4 enc, out float depth, out float3 normal )
{
	depth = DecodeFloatRG (enc.zw);
	normal = DecodeViewNormalStereo (enc);
}


uniform float4 _ZBufferParams;

// Z buffer to linear 0..1 depth (0 at eye, 1 at far plane)
inline float Linear01Depth( float z )
{
	return 1.0 / (_ZBufferParams.x * z + _ZBufferParams.y);
}
// Z buffer to linear depth
inline float LinearEyeDepth( float z )
{
	return 1.0 / (_ZBufferParams.z * z + _ZBufferParams.w);
}


// Depth render texture helpers
#ifdef SHADER_API_D3D9
	#define TRANSFER_EYEDEPTH(o) o = -(mul( glstate.matrix.modelview[0], v.vertex ).z * _ProjectionParams.w)
	#define OUTPUT_EYEDEPTH(i) return i
	#define DECODE_EYEDEPTH(i) (i * _ProjectionParams.z)
#else
	#define TRANSFER_EYEDEPTH(o) 
	#define OUTPUT_EYEDEPTH(i) return 0
	#define DECODE_EYEDEPTH(i) LinearEyeDepth(i)
#endif
#define COMPUTE_EYEDEPTH(o) o = -mul( glstate.matrix.modelview[0], v.vertex ).z
#define COMPUTE_DEPTH_01 -(mul( glstate.matrix.modelview[0], v.vertex ).z * _ProjectionParams.w)
#define COMPUTE_VIEW_NORMAL mul((float3x3)glstate.matrix.invtrans.modelview[0], v.normal)


// Shadow caster pass helpers

#ifdef SHADOWS_CUBE
	#define V2F_SHADOW_CASTER float4 pos : POSITION; float3 vec
	#define TRANSFER_SHADOW_CASTER(o) o.vec = mul( _Object2World, v.vertex ).xyz - _LightPositionRange.xyz; o.pos = mul(glstate.matrix.mvp, v.vertex);
	#define SHADOW_CASTER_FRAGMENT(i) return EncodeFloatRGBA( length(i.vec) * _LightPositionRange.w );
#else
	#ifdef SHADER_API_D3D9
	#define V2F_SHADOW_CASTER float4 pos : POSITION; float4 hpos
	#define TRANSFER_SHADOW_CASTER(o) v.vertex.xyz += _LightDirectionBias.xyz * _LightDirectionBias.w; o.pos = mul(glstate.matrix.mvp, v.vertex); if( o.pos.z < 0.0 ) o.pos.z = 0.0; o.hpos = o.pos;
	#define SHADOW_CASTER_FRAGMENT(i) return i.hpos.z / i.hpos.w;
	#else
	#define V2F_SHADOW_CASTER float4 pos : POSITION
	#define TRANSFER_SHADOW_CASTER(o) v.vertex.xyz += _LightDirectionBias.xyz * _LightDirectionBias.w; o.pos = mul(glstate.matrix.mvp, v.vertex); if( o.pos.z < -o.pos.w ) o.pos.z = -o.pos.w;
	#define SHADOW_CASTER_FRAGMENT(i) return 0;
	#endif
#endif

// Shadow collector pass helpers
#ifdef SHADOW_COLLECTOR_PASS

uniform float4x4 _World2Shadow;
uniform float4x4 _World2Shadow1;
uniform float4x4 _World2Shadow2;
uniform float4x4 _World2Shadow3;
uniform float4 _LightShadowData;

#define V2F_SHADOW_COLLECTOR float4 pos : POSITION; float4 _ShadowCoord[4]; float2 _ShadowZFade
#define TRANSFER_SHADOW_COLLECTOR(o)	\
	o.pos = mul(glstate.matrix.mvp, v.vertex); \
	float z = -mul( glstate.matrix.modelview[0], v.vertex ).z; \
	o._ShadowZFade.x = z; \
	o._ShadowZFade.y = z * _LightShadowData.z + _LightShadowData.w; \
	float4 wpos = mul(_Object2World, v.vertex); \
	o._ShadowCoord[0] = mul(_World2Shadow ,wpos); \
	o._ShadowCoord[1] = mul(_World2Shadow1,wpos); \
	o._ShadowCoord[2] = mul(_World2Shadow2,wpos); \
	o._ShadowCoord[3] = mul(_World2Shadow3,wpos);

uniform float4 _LightSplitsNear;
uniform float4 _LightSplitsFar;
sampler2D _ShadowMapTexture;

#define SHADOW_COLLECTOR_FRAGMENT(i) \
	float4 z = i._ShadowZFade.x; \
	float4 near = float4( z >= _LightSplitsNear ); \
	float4 far = float4( z < _LightSplitsFar ); \
	float4 weights = near * far; \
	float4 coord = i._ShadowCoord[0] * weights[0] + i._ShadowCoord[1] * weights[1] + i._ShadowCoord[2] * weights[2] + i._ShadowCoord[3] * weights[3]; \
	float shadow = tex2Dproj( _ShadowMapTexture, coord.xyw ).r < (coord.z / coord.w) ? _LightShadowData.r : 1.0; \
	half faded = saturate(shadow + saturate(i._ShadowZFade.y)); \
	half distance = saturate(1.0 - z * _LightShadowData.g); \
	return half4(faded,1.0,distance,frac(distance*255.0));
	
#endif

#endif
