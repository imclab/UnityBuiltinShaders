#ifndef HLSL_SUPPORT_INCLUDED
#define HLSL_SUPPORT_INCLUDED

#define samplerRECT sampler2D
#define texRECT tex2D
#define texRECTlod tex2Dlod
#define texRECTbias tex2Dbias
#define texRECTproj tex2Dproj

#if (defined(SHADER_API_D3D9) || defined(SHADER_API_OPENGL) || defined(SHADER_API_PS3)) && !defined(SHADER_TARGET_GLSL)
// Cg seems to use WPOS instead of VPOS semantic?
#define VPOS WPOS
#endif

#if !defined(SHADER_API_XBOX360) && !defined(SHADER_API_PS3) && !defined(SHADER_API_GLES) && !defined(SHADER_TARGET_GLSL)
#define UNITY_HAS_LIGHT_PARAMETERS 1
#endif

#if defined(SHADER_API_XBOX360)

float4 tex2Dproj(in sampler2D s, in float4 t) 
{ 
	float2 ti=t.xy / t.w;
	return tex2D( s, ti);
}

float4 tex2Dproj(in sampler2D s, in float3 t) 
{ 
	float2 ti=t.xy / t.z;
	return tex2D( s, ti);
}


#endif

#if defined(SHADER_API_XBOX360) || defined(SHADER_API_D3D11) || defined (SHADER_TARGET_GLSL)

float4x4 glstate_matrix_mvp;
float4x4 glstate_matrix_modelview0;
float4x4 glstate_matrix_projection;
float4x4 glstate_matrix_transpose_modelview0;
float4x4 glstate_matrix_invtrans_modelview0;
#ifndef SHADER_TARGET_GLSL
float4x4 glstate_matrix_texture[8];
#endif
float4x4 glstate_matrix_texture0;
float4x4 glstate_matrix_texture1;
float4x4 glstate_matrix_texture2;
float4x4 glstate_matrix_texture3;
float4	 glstate_lightmodel_ambient;


#define UNITY_MATRIX_MVP glstate_matrix_mvp
#define UNITY_MATRIX_MV glstate_matrix_modelview0
#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_MATRIX_T_MV glstate_matrix_transpose_modelview0
#define UNITY_MATRIX_IT_MV glstate_matrix_invtrans_modelview0
#define UNITY_MATRIX_TEXTURE glstate_matrix_texture
#define UNITY_MATRIX_TEXTURE0 glstate_matrix_texture0
#define UNITY_MATRIX_TEXTURE1 glstate_matrix_texture1
#define UNITY_MATRIX_TEXTURE2 glstate_matrix_texture2
#define UNITY_MATRIX_TEXTURE3 glstate_matrix_texture3
#define UNITY_LIGHTMODEL_AMBIENT glstate_lightmodel_ambient


#define FOGC FOG

#else

#define UNITY_MATRIX_MVP glstate.matrix.mvp
#define UNITY_MATRIX_MV glstate.matrix.modelview[0]
#define UNITY_MATRIX_P glstate.matrix.projection
#define UNITY_MATRIX_T_MV glstate.matrix.transpose.modelview[0]
#define UNITY_MATRIX_IT_MV glstate.matrix.invtrans.modelview[0]
#define UNITY_MATRIX_TEXTURE glstate.matrix.texture
#define UNITY_MATRIX_TEXTURE0 glstate.matrix.texture[0]
#define UNITY_MATRIX_TEXTURE1 glstate.matrix.texture[1]
#define UNITY_MATRIX_TEXTURE2 glstate.matrix.texture[2]
#define UNITY_MATRIX_TEXTURE3 glstate.matrix.texture[3]
#define UNITY_LIGHTMODEL_AMBIENT glstate.lightmodel.ambient


#endif


#if !defined(SHADER_API_D3D11)
#define SV_POSITION POSITION
#endif


#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360)
#define UNITY_ATTEN_CHANNEL r
#else
#define UNITY_ATTEN_CHANNEL a
#endif

#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360)
#define UNITY_HALF_TEXEL_OFFSET
#endif

#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360)
#define UNITY_UV_STARTS_AT_TOP 1
#else
#define UNITY_UV_STARTS_AT_TOP 0
#endif

#if defined(SHADER_API_D3D9)
#define UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
#endif


#if defined(SHADER_API_OPENGL) && !defined(SHADER_TARGET_GLSL)
#define UNITY_BUGGY_TEX2DPROJ4
#define UNITY_PROJ_COORD(a) a.xyw
#else
#define UNITY_PROJ_COORD(a) a
#endif

#endif
