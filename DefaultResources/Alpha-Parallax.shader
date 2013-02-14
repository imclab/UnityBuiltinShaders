Shader "ParallaxBump/AlphaDiffuse" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_Parallax ("Height", Range (0.005, 0.08)) = 0.02
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_BumpMap ("Bumpmap (RGB) Height (A)", 2D) = "bump" {}
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
	float3	viewDirT	: TEXCOORD1;
	float2	uv2			: TEXCOORD2;
	float3	lightDirT	: TEXCOORD3;
	V2F_LIGHT_COORDS(TEXCOORD4);
}; 
struct v2f2 { 
	V2F_POS_FOG;
	float2	uv			: TEXCOORD0;
	float3	viewDirT	: TEXCOORD1;
	float2	uv2			: TEXCOORD2;
	float3	lightDirT	: TEXCOORD3;
};


v2f vert (appdata_tan v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.uv = TRANSFORM_UV(1);
	o.uv2 = TRANSFORM_UV(0);

	TANGENT_SPACE_ROTATION;
	o.lightDirT = mul( rotation, ObjSpaceLightDir( v.vertex ) );	
	o.viewDirT = mul( rotation, ObjSpaceViewDir( v.vertex ) );	
	
	PASS_LIGHT_COORDS(2);
	return o;
}

uniform sampler2D _BumpMap : register(s0);
uniform sampler2D _MainTex : register(s1);
uniform float4 _SpecColor; 
uniform float _Parallax;
uniform float4 _Color;

float4 frag (v2f2 i, LIGHTDECL(TEXUNIT2))  : COLOR
{
	half h = tex2D( _BumpMap, i.uv2 ).w;
	float2 offset = ParallaxOffset( h, _Parallax, i.viewDirT );
	i.uv += offset;
	i.uv2 += offset;
	
	// get normal from the normal map
	half3 normal = tex2D(_BumpMap, i.uv2).xyz * 2 - 1;
		
	half4 texcol = tex2D(_MainTex,i.uv);
	
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
}

FallBack "Alpha/Bumped", 1

}
