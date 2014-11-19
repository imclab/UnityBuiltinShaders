#ifndef HLSL_SUPPORT_INCLUDED
#define HLSL_SUPPORT_INCLUDED

#if defined(SHADER_TARGET_SURFACE_ANALYSIS)
	// Cg is used for surface shader analysis step
	#define UNITY_COMPILER_CG
#elif defined(SHADER_API_D3D11) || defined(SHADER_API_XBOX360) || defined(SHADER_API_D3D11_9X) || defined(SHADER_API_D3D9) || defined(SHADER_API_XBOXONE)
	#define UNITY_COMPILER_HLSL
#elif defined(SHADER_TARGET_GLSL)
	#define UNITY_COMPILER_HLSL2GLSL
#else
	#define UNITY_COMPILER_CG
#endif

#if !defined(SV_Target)
#	if defined(SHADER_API_PSSL)
#		define SV_Target S_TARGET_OUTPUT
#	elif !defined(SHADER_API_XBOXONE)
#		define SV_Target COLOR
#	endif
#endif


#if !defined(SV_Target0)
#	if defined(SHADER_API_PSSL)
#		define SV_Target0 S_TARGET_OUTPUT0
#	elif !defined(SHADER_API_XBOXONE)
#		define SV_Target0 COLOR0
#	endif
#endif


#if !defined(SV_Target1)
#	if defined(SHADER_API_PSSL)
#		define SV_Target1 S_TARGET_OUTPUT1
#	elif !defined(SHADER_API_XBOXONE)
#		define SV_Target1 COLOR1
#	endif
#endif

#if !defined(SV_Target2)
#	if defined(SHADER_API_PSSL)
#		define SV_Target2 S_TARGET_OUTPUT2
#	elif !defined(SHADER_API_XBOXONE)
#		define SV_Target2 COLOR2
#	endif
#endif

#if !defined(SV_Target3)
#	if defined(SHADER_API_PSSL)
#		define SV_Target3 S_TARGET_OUTPUT3
#	elif !defined(SHADER_API_XBOXONE)
#		define SV_Target3 COLOR3
#	endif
#endif



#if !defined(SV_Depth)
#	if defined(SHADER_API_PSSL)
#		define SV_Depth S_DEPTH_OUTPUT
#	elif !defined(SHADER_API_XBOXONE)
#		define SV_Depth DEPTH
#	endif
#endif

#if defined(SHADER_API_PSSL)
// compute shader defines
#define StructuredBuffer RegularBuffer
#define AppendStructuredBuffer AppendRegularBuffer
#define SV_VertexID S_VERTEX_ID
#define SV_InstanceID S_INSTANCE_ID

#endif 

#if defined(UNITY_COMPILER_HLSL)
#pragma warning (disable : 3205) // conversion of larger type to smaller
#pragma warning (disable : 3568) // unknown pragma ignored
#endif


#if !defined(SHADER_TARGET_GLSL) && !defined(SHADER_API_PSSL)
#define fixed half
#define fixed2 half2
#define fixed3 half3
#define fixed4 half4
#define fixed4x4 half4x4
#define fixed3x3 half3x3
#define fixed2x2 half2x2
#define sampler2D_half sampler2D
#define sampler2D_float sampler2D
#define samplerCUBE_half samplerCUBE
#define samplerCUBE_float samplerCUBE
#endif

#if defined(SHADER_API_PSSL)
#define uniform
#define half float
#define half2 float2
#define half3 float3
#define half4 float4
#define half2x2 float2x2
#define half3x3 float3x3
#define half4x4 float4x4
#define fixed float
#define fixed2 float2
#define fixed3 float3
#define fixed4 float4
#define fixed4x4 half4x4
#define fixed3x3 half3x3
#define fixed2x2 half2x2
#define samplerCUBE_half samplerCUBE
#define samplerCUBE_float samplerCUBE

#define ConsumeStructuredBuffer ConsumeRegularBuffer
#define AppendStructuredBuffer AppendRegularBuffer
#define RWTexture2D RW_Texture2D
#define RWTexture3D RW_Texture3D

#define CBUFFER_START(name) ConstantBuffer name {
#define CBUFFER_END };
#elif defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X)
#define CBUFFER_START(name) cbuffer name {
#define CBUFFER_END };
#else
#define CBUFFER_START(name)
#define CBUFFER_END
#endif

#if defined(SHADOWS_NATIVE) && defined(SHADER_API_PSSL)
	// PSSL
	#define UNITY_DECLARE_SHADOWMAP(tex)		Texture2D tex; SamplerComparisonState sampler##tex
	#define UNITY_SAMPLE_SHADOW(tex,coord)		tex.SampleCmpLOD0(sampler##tex,(coord).xy,(coord).z)
	#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord)	tex.SampleCmpLOD0(sampler##tex,(coord).xy/(coord).w,(coord).z/(coord).w)
#elif defined(SHADOWS_NATIVE) && (defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X))
	// DX11 syntax for shadow maps
	#if defined(SHADER_API_D3D11_9X)
		// FL9.x has some bug where the runtime really wants resource & sampler to be bound to the same slot,
		// otherwise it is skipping draw calls that use shadowmap sampling. Let's bind to #15
		// and hope all works out.
		#define UNITY_DECLARE_SHADOWMAP(tex) Texture2D tex : register(t15); SamplerComparisonState sampler##tex : register(s15)
	#else
		#define UNITY_DECLARE_SHADOWMAP(tex) Texture2D tex; SamplerComparisonState sampler##tex
	#endif
	#define UNITY_SAMPLE_SHADOW(tex,coord) tex.SampleCmpLevelZero (sampler##tex,(coord).xy,(coord).z)
	#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex.SampleCmpLevelZero (sampler##tex,(coord).xy/(coord).w,(coord).z/(coord).w)
#elif defined(SHADOWS_NATIVE) && defined(SHADER_TARGET_GLSL)
	// hlsl2glsl syntax for shadow maps
	#define UNITY_DECLARE_SHADOWMAP(tex) sampler2DShadow tex
	#define UNITY_SAMPLE_SHADOW(tex,coord) shadow2D (tex,(coord).xyz)
	#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) shadow2Dproj (tex,coord)
#elif defined(SHADOWS_NATIVE) && defined(SHADER_API_PSP2) && !defined(SHADER_API_PSM)
	#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D tex
	#define UNITY_SAMPLE_SHADOW(tex,coord) f1tex2D<float>(tex, (coord).xyz)
	#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) f1tex2Dproj<float>(tex, coord)
#elif defined(SHADOWS_NATIVE) && defined(SHADER_API_D3D9)
	// Native shadow maps FOURCC "driver hack" on D3D9: looks just like a regular
	// texture sample. Have to always do a projected sample
	// so that HLSL compiler doesn't try to be too smart and mess up swizzles
	// (thinking that Z is unused).
	#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D tex
	#define UNITY_SAMPLE_SHADOW(tex,coord) tex2Dproj (tex,float4((coord).xyz,1)).r
	#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex2Dproj (tex,coord).r
#else
	// Fallback for other platforms: look just like a regular texture sample.
	#define UNITY_DECLARE_SHADOWMAP(tex) sampler2D tex
	#define UNITY_SAMPLE_SHADOW(tex,coord) tex2D (tex,(coord).xyz).r
	#define UNITY_SAMPLE_SHADOW_PROJ(tex,coord) tex2Dproj (tex,coord).r
#endif



// Macros to declare textures and samplers, possibly separately. For platforms
// that have separate samplers & textures (like DX11), and we'd want to conserve
// the samplers.
//	- UNITY_DECLARE_TEX2D_NOSAMPLER declares a texture, without a sampler.
//	- UNITY_SAMPLE_TEX2D_SAMPLER samples a texture, using sampler from another texture.
//		That another texture must also be actually used in the current shader, otherwise
//		the correct sampler will not be set.
#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE)
#define UNITY_DECLARE_TEX2D(tex) Texture2D tex; SamplerState sampler##tex
#define UNITY_DECLARE_TEX2D_NOSAMPLER(tex) Texture2D tex
#define UNITY_SAMPLE_TEX2D(tex,coord) tex.Sample (sampler##tex,coord)
#define UNITY_SAMPLE_TEX2D_SAMPLER(tex,samplertex,coord) tex.Sample (sampler##samplertex,coord)
#define UNITY_DECLARE_TEXCUBE(tex) TextureCube tex; SamplerState sampler##tex
#define UNITY_ARGS_TEXCUBE(tex) TextureCube tex, SamplerState sampler##tex
#define UNITY_PASS_TEXCUBE(tex) tex, sampler##tex
#define UNITY_DECLARE_TEXCUBE_NOSAMPLER(tex) TextureCube tex
#else
#define UNITY_DECLARE_TEX2D(tex) sampler2D tex
#define UNITY_DECLARE_TEX2D_NOSAMPLER(tex) sampler2D tex
#define UNITY_SAMPLE_TEX2D(tex,coord) tex2D (tex,coord)
#define UNITY_SAMPLE_TEX2D_SAMPLER(tex,samplertex,coord) tex2D (tex,coord)
#define UNITY_DECLARE_TEXCUBE(tex) samplerCUBE tex
#define UNITY_ARGS_TEXCUBE(tex) samplerCUBE tex
#define UNITY_PASS_TEXCUBE(tex) tex
#define UNITY_DECLARE_TEXCUBE_NOSAMPLER(tex) samplerCUBE tex
#endif



#define samplerRECT sampler2D
#define texRECT tex2D
#define texRECTlod tex2Dlod
#define texRECTbias tex2Dbias
#define texRECTproj tex2Dproj

#if defined(SHADER_API_PSSL)
#define VPOS			S_POSITION
#elif defined(UNITY_COMPILER_CG)
// Cg seems to use WPOS instead of VPOS semantic?
#define VPOS WPOS
// Cg does not have tex2Dgrad and friends, but has tex2D overload that
// can take the derivatives
#define tex2Dgrad tex2D
#define texCUBEgrad texCUBE
#define tex3Dgrad tex3D
#endif

// Data type to be used for "screen space position" pixel shader input semantic;
// D3D9 needs it to be float2, unlike all other platforms.
#if defined(SHADER_API_D3D9)
#define UNITY_VPOS_TYPE float2
#else
#define UNITY_VPOS_TYPE float4
#endif


#if defined(SHADER_API_PSSL)

struct sampler1D {
	Texture1D		t;
	SamplerState	s;
};
struct sampler2D {
	Texture2D		t;
	SamplerState	s;
};
struct sampler2D_float {
	Texture2D		t;
	SamplerState	s;
};
struct sampler3D {
	Texture3D		t;
	SamplerState	s;
};
struct samplerCUBE {
	TextureCube		t;
	SamplerState	s;
};

float4 tex1D(sampler1D x, float v)				{ return x.t.Sample(x.s, v); }
float4 tex2D(sampler2D x, float2 v)				{ return x.t.Sample(x.s, v); }
float4 tex2D(sampler2D_float x, float2 v)		{ return x.t.Sample(x.s, v); }
float4 tex3D(sampler3D x, float3 v)				{ return x.t.Sample(x.s, v); }
float4 texCUBE(samplerCUBE x, float3 v)			{ return x.t.Sample(x.s, v); }

float4 tex1Dbias(sampler1D x, in float4 t)		{ return x.t.SampleBias(x.s, t.x, t.w); }
float4 tex2Dbias(sampler2D x, in float4 t)		{ return x.t.SampleBias(x.s, t.xy, t.w); }
float4 tex2Dbias(sampler2D_float x, in float4 t)		{ return x.t.SampleBias(x.s, t.xy, t.w); }
float4 tex3Dbias(sampler3D x, in float4 t)		{ return x.t.SampleBias(x.s, t.xyz, t.w); }
float4 texCUBEbias(samplerCUBE x, in float4 t)	{ return x.t.SampleBias(x.s, t.xyz, t.w); }

float4 tex1Dlod(sampler1D x, in float4 t)		{ return x.t.SampleLOD(x.s, t.x, t.w); }
float4 tex2Dlod(sampler2D x, in float4 t)		{ return x.t.SampleLOD(x.s, t.xy, t.w); }
float4 tex2Dlod(sampler2D_float x, in float4 t)		{ return x.t.SampleLOD(x.s, t.xy, t.w); }
float4 tex3Dlod(sampler3D x, in float4 t)		{ return x.t.SampleLOD(x.s, t.xyz, t.w); }
float4 texCUBElod(samplerCUBE x, in float4 t)	{ return x.t.SampleLOD(x.s, t.xyz, t.w); }

float4 tex1Dgrad(sampler1D x, float t, float dx, float dy)			{ return x.t.SampleGradient(x.s, t, dx, dy); }
float4 tex2Dgrad(sampler2D x, float2 t, float2 dx, float2 dy)		{ return x.t.SampleGradient(x.s, t, dx, dy); }
float4 tex2Dgrad(sampler2D_float x, float2 t, float2 dx, float2 dy)		{ return x.t.SampleGradient(x.s, t, dx, dy); }
float4 tex3Dgrad(sampler3D x, float3 t, float3 dx, float3 dy)		{ return x.t.SampleGradient(x.s, t, dx, dy); }
float4 texCUBEgrad(samplerCUBE x, float3 t, float3 dx, float3 dy)	{ return x.t.SampleGradient(x.s, t, dx, dy); }

float4 tex1Dproj(sampler1D s, in float2 t)		{ return tex1D(s, t.x / t.y); }
float4 tex1Dproj(sampler1D s, in float4 t)		{ return tex1D(s, t.x / t.w); }
float4 tex2Dproj(sampler2D s, in float3 t)		{ return tex2D(s, t.xy / t.z); }
float4 tex2Dproj(sampler2D_float s, in float3 t)		{ return tex2D(s, t.xy / t.z); }
float4 tex2Dproj(sampler2D s, in float4 t)		{ return tex2D(s, t.xy / t.w); }
float4 tex3Dproj(sampler3D s, in float4 t)		{ return tex3D(s, t.xyz / t.w); }
float4 texCUBEproj(samplerCUBE s, in float4 t)	{ return texCUBE(s, t.xyz / t.w); }

#elif defined(SHADER_API_XBOX360)

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

#if defined(UNITY_COMPILER_HLSL) || defined (SHADER_TARGET_GLSL)
#define FOGC FOG
#endif

// Use VFACE pixel shader input semantic in your shaders to get front-facing scalar value.
#if defined(UNITY_COMPILER_CG)
#define VFACE FACE
#endif
#if defined(UNITY_COMPILER_HLSL2GLSL)
#define FACE VFACE
#endif

#if defined(SHADER_API_PSSL)
#define SV_POSITION S_POSITION
#elif !defined(SHADER_API_D3D11) && !defined(SHADER_API_D3D11_9X)
#define SV_POSITION POSITION
#endif


#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360) || defined(SHADER_API_PS3) || defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X) || defined(SHADER_API_PSP2) || defined(SHADER_API_PSSL)
#define UNITY_ATTEN_CHANNEL r
#else
#define UNITY_ATTEN_CHANNEL a
#endif

#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360) || defined(SHADER_API_PSP2)
#define UNITY_HALF_TEXEL_OFFSET
#endif

#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360) || defined(SHADER_API_PS3) || defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X) || defined(SHADER_API_PSP2) || defined(SHADER_API_PSSL) || defined(SHADER_API_METAL)
#define UNITY_UV_STARTS_AT_TOP 1
#endif

#if defined(SHADER_API_D3D9) || defined(SHADER_API_XBOX360) || defined(SHADER_API_PS3) || defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X)
#define UNITY_NEAR_CLIP_VALUE (0.0)
#else
#define UNITY_NEAR_CLIP_VALUE (-1.0)
#endif


#if defined(SHADER_API_D3D9)
#define UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
#endif


#if (defined(SHADER_API_OPENGL) && !defined(SHADER_TARGET_GLSL)) || defined(SHADER_API_PSP2)
#define UNITY_BUGGY_TEX2DPROJ4
#define UNITY_PROJ_COORD(a) (a).xyw
#else
#define UNITY_PROJ_COORD(a) a
#endif


// Platforms which do not use cascaded/screenspace shadow maps: more or less "mobile" platforms
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL) || defined(SHADER_API_D3D11_9X)
#define UNITY_NO_SCREENSPACE_SHADOWS
#endif

// Platforms which do not use RGBM lightmap compression, or DXT5nm normal map compression
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL)
#define UNITY_NO_RGBM
#define UNITY_NO_DXT5nm
#endif

// Platforms which can support "framebuffer fetch" on some devices
#if defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL)
#define UNITY_FRAMEBUFFER_FETCH_AVAILABLE
#endif


// On most platforms, use floating point render targets to store depth of point
// light shadowmaps. However, on some others they either have issues, or aren't widely
// supported; in which case fallback to encoding depth into RGBA channels.
// Make sure this define matches GraphicsCaps.useRGBAForPointShadows.
#if defined(SHADER_API_GLES) || defined(SHADER_API_PSP2) || defined(SHADER_API_XBOX360) || defined(SHADER_API_PS3)
#define UNITY_USE_RGBA_FOR_POINT_SHADOWS
#endif


// Initialize arbitrary structure with zero values.
// Not supported on some backends (e.g. Cg-based like PS3 and particularly with nested structs).
// hlsl2glsl would almost support it, except with structs that have arrays -- so treat as not supported there either :(
#if defined(UNITY_COMPILER_HLSL) || defined(SHADER_API_PSSL)
#define UNITY_INITIALIZE_OUTPUT(type,name) name = (type)0;
#else
#define UNITY_INITIALIZE_OUTPUT(type,name)
#endif

#if defined(SHADER_API_D3D11)
#define UNITY_CAN_COMPILE_TESSELLATION 1
#	define UNITY_domain					domain
#	define UNITY_partitioning			partitioning
#	define UNITY_outputtopology			outputtopology
#	define UNITY_patchconstantfunc		patchconstantfunc
#	define UNITY_outputcontrolpoints	outputcontrolpoints
#elif defined(SHADER_API_PSSL)
#	define UNITY_CAN_COMPILE_TESSELLATION 1

#	define SV_OutputControlPointID		S_OUTPUT_CONTROL_POINT_ID
#	define SV_TessFactor				S_EDGE_TESS_FACTOR
#	define SV_InsideTessFactor			S_INSIDE_TESS_FACTOR
#	define SV_DomainLocation			S_DOMAIN_LOCATION
#   define SV_DispatchThreadID          S_DISPATCH_THREAD_ID
#	define SV_GroupID					S_GROUP_ID
#	define SV_GroupThreadID				S_GROUP_THREAD_ID
#	define SV_GroupIndex				S_GROUP_INDEX

#	define groupshared					thread_group_memory

#	define UNITY_domain					DOMAIN_PATCH_TYPE
#	define UNITY_partitioning			PARTITIONING_TYPE
#	define UNITY_outputtopology			OUTPUT_TOPOLOGY_TYPE
#	define UNITY_patchconstantfunc		PATCH_CONSTANT_FUNC
#	define UNITY_outputcontrolpoints	OUTPUT_CONTROL_POINTS

#	define	domain						DOMAIN_PATCH_TYPE
#	define	partitioning				PARTITIONING_TYPE
#	define	outputtopology				OUTPUT_TOPOLOGY_TYPE
#	define	patchconstantfunc			PATCH_CONSTANT_FUNC
#	define	outputcontrolpoints			OUTPUT_CONTROL_POINTS

#	define	maxtessfactor				MAX_TESS_FACTOR
#	define	instance					INSTANCE
#	define	numthreads					NUM_THREADS
#	define	patchsize					PATCH_SIZE
#	define	maxvertexcount				MAX_VERTEX_COUNT
#	define	earlydepthstencil			FORCE_EARLY_DEPTH_STENCIL

#	define	GroupMemoryBarrierWithGroupSync ThreadGroupMemoryBarrierSync

// geometry shader
#	define TriangleStream				TriangleBuffer
#	define PointStream					PointBuffer
#	define LineStream					LineBuffer
#	define triangle					Triangle
#	define point						Point
#	define line						Line
#	define triangleadj					AdjacentTriangle
#	define lineadj						AdjacentLine

// multimedia operations
#define msad4						msad

#endif

// Not really needed anymore, but did ship in Unity 4.0; with D3D11_9X remapping them to .r channel.
// Now that's not used.
#define UNITY_SAMPLE_1CHANNEL(x,y) tex2D(x,y).a
#define UNITY_ALPHA_CHANNEL a


// HLSL branch and flatten attributes
#if defined(UNITY_COMPILER_HLSL)
	#define UNITY_BRANCH	[branch]
	#define UNITY_FLATTEN	[flatten]
#else
	#define UNITY_BRANCH
	#define UNITY_FLATTEN
#endif

#endif
