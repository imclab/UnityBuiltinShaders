/// The lines below are codes picked up by the perl preprocessor 
/// "TYPECODE" define_name unity_lightNo texcount
/// 
/// TYPECODE NOTEX			1     4
/// TYPECODE TEX2D      	2     1
/// TYPECODE TEX2D2D    	3     2	
/// TYPECODE TEX3D   		4     1
/// TYPECODE TEXCUBE 		5     1

#ifdef TEX2D
#define SAMPLERS uniform sampler2D _LightTexture0;
#define SAMPLE1(b) tex2Dproj (_LightTexture0,b .xyw).wwww
#define SAMPLE2(b) half4 (1,1,1,1)
#define LIGHTDECL(a) uniform sampler2D _LightTexture[1] : a,	float4 _LightCoord[1], float4 _LightColor :COLOR
#define LIGHTATT	(tex2Dproj (_LightTexture[0], _LightCoord[0].xyw).w)
#endif

#ifdef TEX3D
#define SAMPLERS uniform sampler3D _LightTexture0;
#define SAMPLE1(b) tex3D (_LightTexture0,b .xyz).wwww
#define SAMPLE2(b) half4 (1,1,1,1)
#define LIGHTDECL(a) uniform sampler3D _LightTexture[1] : a,	float4 _LightCoord[1], float4 _LightColor :COLOR
#define LIGHTATT	(tex3D (_LightTexture[0], _LightCoord[0].xyz).w)
#endif

#ifdef TEXCUBE
#define SAMPLERS uniform samplerCUBE _LightTexture0;
#define SAMPLE1(b) texCUBE (_LightTexture0,b .xyz).wwww
#define SAMPLE2(b) half4 (1,1,1,1)
#define LIGHTDECL(a) uniform samplerCUBE _LightTexture[1] : a,	float4 _LightCoord[1], float4 _LightColor :COLOR
#define LIGHTATT	(texCUBE (_LightTexture[0], _LightCoord[0].xyz).w)
#endif

#ifdef TEX2D2D
#define SAMPLERS uniform sampler2D _LightTexture0; uniform sampler2D _LightTextureB0;
#define SAMPLE1(b) tex2Dproj (_LightTexture0,b .xyw).wwww
#define SAMPLE2(b) tex2Dproj (_LightTextureB0, b.xyw).wwww
#define LIGHTDECL(a) uniform sampler2D _LightTexture[2] : a,	float4 _LightCoord[2], float4 _LightColor :COLOR
#define LIGHTATT	(tex2Dproj (_LightTexture[0], _LightCoord[0]).w * tex2Dproj (_LightTexture[1], _LightCoord[1]).w) 
#endif 

#ifdef NOTEX
#define SAMPLERS /* */
#define SAMPLE1(b) half4 (1,1,1,1)
#define SAMPLE2(b) half4 (1,1,1,1)
#define LIGHTDECL(a) float4 _LightColor :COLOR
#define LIGHTATT	1
#endif

#define LIGHTCOLOR (LIGHTATT * _LightColor.xyz)
