#ifndef UNITY_CG_INCLUDED
#define UNITY_CG_INCLUDED

// The maximum number of pixel lights we can process in one pass.
// Most shaders only do one light per pass.
#define MAXLIGHTS 2

// -------------------------------------------------------------------
//  builtin values exposed from Unity

// Time values from Unity
#define _TIMEPROP
uniform float4 _Time;
uniform float4 _SinTime;
uniform float4 _CosTime;

/// The current light 
uniform float4 _LightColor;
uniform float4 _PPLAmbient;

uniform float3 _ObjectSpaceCameraPos;
uniform float4 _ObjectSpaceLightPos[MAXLIGHTS];
uniform float4 _ModelLightColor[MAXLIGHTS];
uniform float4 _SpecularLightColor[MAXLIGHTS];
/// 3x3 rotation matrix for specular cubemap
uniform float3x3 _LightSpecularRotation0;
uniform float3x3 _LightSpecularRotation1;

uniform float4x4 _Light2World[MAXLIGHTS], _World2Light[MAXLIGHTS], _Object2World, _World2Object, _Object2Light[MAXLIGHTS];


// Define obsolete functions/values for backwards compatability.
#include "UnityCGobsolete.cginc"



// -------------------------------------------------------------------
//  helper functions and macros used in many standard shaders

struct appdata_base {
    float4 vertex;
    float3 normal;
    float4 texcoord;
};

struct appdata_tan {
    float4 vertex;
    float4 tangent;
    float3 normal;
    float4 texcoord;
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
	return _ObjectSpaceLightPos[0].xyz - v.xyz * _ObjectSpaceLightPos[0].w;
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


// Transforms float4 UV
#define TRANSFORM_UV(idx) mul( glstate.matrix.texture[idx], v.texcoord ).xy

#define LIGHT_COORD(idx) mul( glstate.matrix.texture[idx], v.vertex )

#define V2F_POS_FOG float4 pos : POSITION; float fog : FOGC
#define V2F_LIGHT_COORDS(idx) float4 _LightCoord[2] : idx

// Passes light texture coordinates to the fragment
#define PASS_LIGHT_COORDS(idx) \
	o._LightCoord[0] = LIGHT_COORD( idx ); \
	o._LightCoord[1] = LIGHT_COORD( idx+1 )


// Calculates Lambertian (diffuse) ligting model
inline half4 DiffuseLight( half3 lightDir, half3 normal, half4 color, half atten )
{
	lightDir = normalize(lightDir);
	
	half diffuse = dot( normal, lightDir );
	
	half4 c;
	c.rgb = color.rgb * _ModelLightColor[0].rgb * (diffuse * atten * 2);
	c.a = 0; // diffuse passes by default don't contribute to overbright
	return c;
}


// Calculates Blinn-Phong (specular) lighting model
inline half4 SpecularLight( half3 lightDir, half3 viewDir, half3 normal, half4 color, float specK, half atten )
{
	lightDir = normalize(lightDir);
	viewDir = normalize(viewDir);
	half3 h = normalize( lightDir + viewDir );
	
	half diffuse = dot( normal, lightDir );
	
	float nh = saturate( dot( h, normal ) );
	float spec = pow( nh, specK ) * color.a;
	spec *= diffuse;
	
	half4 c;
	c.rgb = (color.rgb * _ModelLightColor[0].rgb * diffuse + _SpecularLightColor[0].rgb * spec) * (atten * 2);
	c.a = _SpecularLightColor[0].a * spec * atten; // specular passes by default put highlights to overbright
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



#endif
