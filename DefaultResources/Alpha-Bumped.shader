Shader "Alpha/Bumped" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_BumpMap ("Bumpmap (RGB)", 2D) = "bump" {}
}

Category {
	Tags {Queue=Transparent}
	Alphatest Greater 0
	Fog { Color [_AddFog] }
	ZWrite Off
	ColorMask RGB
	
	// ------------------------------------------------------------------
	// ARB fragment program
	
	SubShader {
		UsePass "Alpha/Diffuse/BASE"
		
		// Pixel lights
		Pass {	
			Name "PPL"
			Blend SrcAlpha One
			Tags {
				"LightMode" = "Pixel"  
				"LightTexCount" = "012"
			}
				
CGPROGRAM
// profiles arbfp1
// fragment frag
// vertex vert
// autolight 7
// fragmentoption ARB_fog_exp2
// fragmentoption ARB_precision_hint_fastest

#include "UnityCG.cginc"
#include "AutoLight.cginc" 

struct v2f { 
	V2F_POS_FOG;
	float2	uv			: TEXCOORD0;
	float2	uv2			: TEXCOORD1;
	float3	lightDirT	: TEXCOORD2;
	V2F_LIGHT_COORDS(TEXCOORD3);
}; 
struct v2f2 { 
	V2F_POS_FOG;
	float2	uv			: TEXCOORD0;
	float2	uv2			: TEXCOORD1;
	float3	lightDirT	: TEXCOORD2;
};


v2f vert (appdata_tan v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv = TRANSFORM_UV(1);
	o.uv2 = TRANSFORM_UV(0);
	
	TANGENT_SPACE_ROTATION;
	o.lightDirT = mul( rotation, ObjSpaceLightDir( v.vertex ) );	
	
	PASS_LIGHT_COORDS(2);
	return o;
}

uniform sampler2D _BumpMap : register(s0);
uniform sampler2D _MainTex : register(s1);
uniform float4 _Color;

float4 frag (v2f2 i, LIGHTDECL(TEXUNIT2))  : COLOR
{
	half4 texcol = tex2D(_MainTex,i.uv);
	
	// get normal from the normal map
	half3 normal = tex2D(_BumpMap, i.uv2).xyz * 2 - 1;
	
	half4 c = DiffuseLight( i.lightDirT, normal, texcol, LIGHTATT );
	c.a = texcol.a * _Color.a;
	return c;
}
ENDCG  
			SetTexture [_BumpMap] {combine texture}
			SetTexture [_MainTex] {combine texture}
			SetTexture [_LightTexture0] {combine texture} 
			SetTexture [_LightTextureB0] {combine texture}
		}
	}
	
	// ------------------------------------------------------------------
	// Radeon 9000
	
	SubShader {
		UsePass "Alpha/Diffuse/BASE"
		
		// Pixel lights with 0 light textures
		Pass {
			Blend SrcAlpha One
			Name "PPL"
			Tags {
				"LightMode" = "Pixel"
				"LightTexCount" = "0"
			}

CGPROGRAM
// vertex vert
#include "unityCG.cginc"

struct v2f {
	V2F_POS_FOG;
	float2 uv			: TEXCOORD0;
	float2 uv2			: TEXCOORD1;
	float3 lightDirT	: TEXCOORD2;
};

v2f vert(appdata_tan v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv = TRANSFORM_UV(0);
	o.uv2 = TRANSFORM_UV(2);
	
	TANGENT_SPACE_ROTATION;
	o.lightDirT = mul( rotation, ObjSpaceLightDir( v.vertex ) );	
	return o;
}
ENDCG
			Program "" {
				SubProgram {
					Local 0,[_ModelLightColor0]
					Local 1,[_Color]

"!!ATIfs1.0
StartConstants;
	CONSTANT c0 = program.local[0];
	CONSTANT c1 = program.local[1];
EndConstants;

StartOutputPass;
	SampleMap r0, t0.str;	# main texture
	SampleMap r2, t1.str;	# normal
	SampleMap r1, t2.str;	# normalize light direction

	DOT3 r3.sat, r2.bias.2x, r1.bias.2x;	# diffuse (N.L)
	MUL r3, r3, c0;
	MUL r0.rgb.2x, r3, r0;
	MUL r0.a, r0, c1;
EndPass;
"
				}
			}
			SetTexture[_MainTex] {combine texture}
			SetTexture[_CubeNormalize] {combine texture}
			SetTexture[_BumpMap] {combine texture}
		}

		// Pixel lights with 1 light texture
		Pass {
			Blend SrcAlpha One
			Name "PPL"
			Tags {
				"LightMode" = "Pixel"
				"LightTexCount" = "1"
			}

CGPROGRAM
// vertex vert
#include "unityCG.cginc"

struct v2f {
	V2F_POS_FOG;
	float2 uv			: TEXCOORD0;
	float3 lightDirT	: TEXCOORD3;
	float2 uv2			: TEXCOORD4; 
	float4 LightCoord0	: TEXCOORD1;
};

v2f vert(appdata_tan v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv = TRANSFORM_UV(0);
	o.uv2 = TRANSFORM_UV(3);
	
	TANGENT_SPACE_ROTATION;
	o.lightDirT = mul( rotation, ObjSpaceLightDir( v.vertex ) );
	
	o.LightCoord0 = LIGHT_COORD(1);
	
	return o;
}
ENDCG
			Program "" {
				SubProgram {
					Local 0,[_ModelLightColor0]
					Local 1, [_Color]

"!!ATIfs1.0
StartConstants;
	CONSTANT c0 = program.local[0];
	CONSTANT c1 = program.local[1];
EndConstants;

StartOutputPass;
	SampleMap r0, t0.str;	# main texture
	SampleMap r1, t1.str;	# attenuation
	SampleMap r3, t4.str;	# normal
	SampleMap r2, t3.str;	# normalize light direction

	DOT3 r5.sat, r3.bias.2x, r2.bias.2x;	# diffuse (N.L)
	MUL r5, r5, c0;
	MUL r0.rgb.2x, r5, r0;
	MUL r0.rgb, r0, r1.a;		# attenuate
	MUL r0.a, r0, c1;
EndPass; 
"
				}
			}
			SetTexture [_MainTex] {combine texture}
			SetTexture [_LightTexture0] {combine texture}
			SetTexture [_CubeNormalize] {combine texture}
			SetTexture[_BumpMap] {combine texture}
		}
		
		// Pixel lights with 2 light textures
		Pass {
			Blend SrcAlpha One
			Name "PPL"
			Tags {
				"LightMode" = "Pixel"
				"LightTexCount" = "2"
			}
CGPROGRAM
// vertex vert
#include "unityCG.cginc"

struct v2f {
	V2F_POS_FOG;
	float2 uv			: TEXCOORD0;
	float3 lightDirT	: TEXCOORD3;
	float2 uv2			: TEXCOORD5;
	float4 LightCoord0	: TEXCOORD1;
	float4 LightCoordB0	: TEXCOORD4;
};

v2f vert(appdata_tan v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv = TRANSFORM_UV(0);
	o.uv2 = TRANSFORM_UV(4);
	
	TANGENT_SPACE_ROTATION;
	o.lightDirT = mul( rotation, ObjSpaceLightDir( v.vertex ) );
	
	o.LightCoord0 = LIGHT_COORD(1);
	o.LightCoordB0 = LIGHT_COORD(3);
	
	return o;
}
ENDCG

			Program "" {
				SubProgram {
					Local 0, [_ModelLightColor0]
					Local 1, [_Color]

"!!ATIfs1.0
StartConstants;
	CONSTANT c0 = program.local[0];
	CONSTANT c1 = program.local[1];
EndConstants;

StartOutputPass;
	SampleMap r0, t0.str;	# main texture
	SampleMap r4, t5.str;	# normal	
	SampleMap r2, t3.str;	# normalize light direction

	SampleMap r1, t1.stq_dq;	# attenuation 1
	SampleMap r3, t4.stq_dq;	# attenuation 2

	DOT3 r2.sat, r4.bias.2x, r2.bias.2x;	# diffuse (N.L)
	MUL r2, r2, c0;
	MUL r0.rgb.2x, r2, r0;
	MUL r0.rgb, r0, r1.a;		# attenuate
	MUL r0.rgb, r0, r3.a;		# attenuate
	MUL r0.a, r0, c1;
EndPass; 
"
				}
			}
			SetTexture[_MainTex] {combine texture}
			SetTexture[_LightTexture0] {combine texture}
			SetTexture[_CubeNormalize] {combine texture}
			SetTexture[_LightTextureB0] {combine texture}
			SetTexture[_BumpMap] {combine texture}
		}
	}
}

FallBack "Alpha/Diffuse", 1

}