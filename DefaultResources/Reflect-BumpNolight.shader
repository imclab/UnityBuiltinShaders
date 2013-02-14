Shader "Reflective/Bumped Unlit" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
	_MainTex ("Base (RGB), RefStrength (A)", 2D) = "white" {}
	_Cube ("Reflection Cubemap", Cube) = "" { TexGen CubeReflect }
	_BumpMap ("Bump (RGB)", 2D) = "bump" {}
}

Category {
	Blend AppSrcAdd AppDstAdd
	Fog { Color [_AddFog] }
	
	// ------------------------------------------------------------------
	// ARB fragment program

	SubShader {
		// Always drawn reflective pass
		Pass {
			Name "BASE"
			Tags {"LightMode" = "Always"}
CGPROGRAM
// profiles arbfp1
// fragment frag
// vertex vert
// fragmentoption ARB_fog_exp2
// fragmentoption ARB_precision_hint_fastest

#include "UnityCG.cginc"
#include "AutoLight.cginc" 

struct v2f {
	V2F_POS_FOG;
	float2	uv		: TEXCOORD0;
	float2	uv2		: TEXCOORD1;
	float3	I		: TEXCOORD2;
	float3	TtoW0 	: TEXCOORD3;
	float3	TtoW1	: TEXCOORD4;
	float3	TtoW2	: TEXCOORD5;
};

v2f vert(appdata_tan v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv = TRANSFORM_UV(1);
	o.uv2 = TRANSFORM_UV(0);
	
	o.I = mul( (float3x3)_Object2World, -ObjSpaceViewDir( v.vertex ) );	
	
	TANGENT_SPACE_ROTATION;
	o.TtoW0 = mul(rotation, _Object2World[0].xyz);
	o.TtoW1 = mul(rotation, _Object2World[1].xyz);
	o.TtoW2 = mul(rotation, _Object2World[2].xyz);
	
	return o; 
}

uniform sampler2D _BumpMap : register(s0);
uniform sampler2D _MainTex : register(s1);
uniform samplerCUBE _Cube : register(s2);
uniform float4 _ReflectColor;
uniform float4 _Color;

float4 frag (v2f i) : COLOR
{
	// Sample and expand the normal map texture	
	half4 normal = tex2D(_BumpMap,i.uv2) * 2 - 1;
	
	half4 texcol = tex2D(_MainTex,i.uv);
	
	// transform normal to world space
	half3 wn;
	wn.x = dot(i.TtoW0, normal.xyz);
	wn.y = dot(i.TtoW1, normal.xyz);
	wn.z = dot(i.TtoW2, normal.xyz);
	
	// calculate reflection vector in world space
	half3 r = reflect(i.I, wn);
	
	half4 c = _PPLAmbient * texcol;
	c.rgb *= 2;
	half4 reflcolor = texCUBE(_Cube, r) * _ReflectColor * texcol.a;
	return c + reflcolor;
}
ENDCG  
			SetTexture [_BumpMap] {combine texture}
			SetTexture [_MainTex] {combine texture}
			SetTexture [_Cube] {combine texture} 
		} 
	}
	
	// ------------------------------------------------------------------
	// Radeon 9000
	
	SubShader {
		// Always drawn reflective pass
		Pass {
			Name "BASE"
			Tags {"LightMode" = "Always"}
CGPROGRAM
// vertex
#include "UnityCG.cginc"

struct v2f {
	V2F_POS_FOG;
	float2	uv		: TEXCOORD0;
	float3	TtoW1	: TEXCOORD2;
	float3	I		: TEXCOORD3;
	float2	uv2		: TEXCOORD4;
	float3	TtoW0	: TEXCOORD1;   
	float3	TtoW2	: TEXCOORD5;
};

v2f main(appdata_tan v)
{
	v2f o;
	
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv.xy = TRANSFORM_UV(0);
	o.uv2.xy = TRANSFORM_UV(4);
	
	o.I = normalize( mul( (float3x3)_Object2World, -ObjSpaceViewDir( v.vertex ) ) );
	
	TANGENT_SPACE_ROTATION;
	o.TtoW0 = mul(rotation, _Object2World[0].xyz);
	o.TtoW1 = mul(rotation, _Object2World[1].xyz);
	o.TtoW2 = mul(rotation, _Object2World[2].xyz);
	return o; 
}
ENDCG
			Program "" {
				SubProgram {
					Local 0, [_PPLAmbient]
					Local 1, [_ReflectColor]
"!!ATIfs1.0
StartConstants;
	CONSTANT c0 = program.local[0];
	CONSTANT c1 = program.local[1];
EndConstants;

StartPrelimPass;
	SampleMap r4, t4.str;		# normal
	PassTexCoord r2, t3.str;	# incoming vector
	PassTexCoord r0, t1.str;	# tangent space
	PassTexCoord r1, t2.str;
	PassTexCoord r5, t5.str;
	
	DOT3 r0.r, r0, r4.bias.2x;	# transform normal from tangent to world space
	DOT3 r0.g, r1, r4.bias.2x;
	DOT3 r0.b, r5, r4.bias.2x;

	DOT3 r4.2x, r0, r2;			# calculate world space reflection vector
	MAD r3, r4.neg, r0, r2;	 
EndPass;

StartOutputPass;
	SampleMap r0, t0.str;		# main texture
	SampleMap r5, r3.str;		# reflection
	
	MUL  r5, r5, r0.a;
	MUL  r0.rgb.2x, r0, c0;
	MUL  r0.a, r0, c0;
	MAD  r0, r5, c1, r0;
EndPass; 
"
				}
			}
			SetTexture[_MainTex] {combine texture}
			SetTexture[_MainTex] {combine texture}
			SetTexture[_SpecFalloff] {combine texture}
			SetTexture[_CubeNormalize] {combine texture}
			SetTexture[_BumpMap] {combine texture}
			SetTexture[_Cube] {combine texture}	
		}
	}
	
	// ------------------------------------------------------------------
	//  No vertex or fragment programs
	
	SubShader {
		Pass { 
			Tags {"LightMode" = "Always"}
			Name "BASE"
			BindChannels {
				Bind "Vertex", vertex
				Bind "Normal", normal
			}
			SetTexture [_Cube] {
				constantColor [_ReflectColor]
				combine texture * constant
				Matrix [_Reflection]
			}
		}
	}
}
	
FallBack " VertexLit", 1

}
