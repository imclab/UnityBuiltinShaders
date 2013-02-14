Shader " DiffuseDetail" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white"{}
	_Detail ("Detail (RGB)", 2D) = "gray" {}
}

Category {
	Lod 0
	Blend AppSrcAdd AppDstAdd
	Fog { Color [_AddFog] }
		
	// ------------------------------------------------------------------
	// ARB fragment program
	
	SubShader {
		// Ambient pass
		Pass {
			Tags {"LightMode" = "PixelOrNone"}
			Color [_PPLAmbient]
			SetTexture [_MainTex] {constantColor [_Color] Combine texture * primary DOUBLE, texture * constant}
			SetTexture [_Detail] {combine previous * texture DOUBLE, previous}
		}
		
		// Vertex lights
		Pass { 
			Tags {"LightMode" = "Vertex"}
			Material {
				Diffuse [_Color]
				Emission [_PPLAmbient]
			}
			Lighting On
			SetTexture [_MainTex] {constantColor [_PPLAmbent] Combine texture * primary DOUBLE, texture * primary}
			SetTexture [_Detail] { combine previous * texture DOUBLE, previous }
		}
		
		// Pixel lights
		Pass {
			Name "PPL"
			Tags {
				"LightMode" = "Pixel" 
				"LightTexCount" = "012"
			}
CGPROGRAM
// profiles arbfp1
// fragment frag
// vertex vert
// autolight 7
#include "UnityCG.cginc"
#include "AutoLight.cginc"
// fragmentoption ARB_fog_exp2
// fragmentoption ARB_precision_hint_fastest

struct v2f {
	V2F_POS_FOG;
	float2	uv[2]		: TEXCOORD0;
	float3	normal		: TEXCOORD2;
	float3	lightDir	: TEXCOORD3;
	V2F_LIGHT_COORDS(TEXCOORD4);
};
struct v2f2 { 
	V2F_POS_FOG;
	float2	uv[2]		: TEXCOORD0;
	float3	normal		: TEXCOORD2;
	float3	lightDir	: TEXCOORD3;
};

v2f vert (appdata_base v)
{
	v2f o;
	PositionFog( v.vertex, o.pos, o.fog );
	o.normal = v.normal;
	o.uv[0] = TRANSFORM_UV(1);
	o.uv[1] = TRANSFORM_UV(0);
	o.lightDir = ObjSpaceLightDir( v.vertex );	
	PASS_LIGHT_COORDS(2);
	return o;
}

uniform sampler2D _MainTex : register(s1);
uniform sampler2D _Detail : register(s0);

half4 frag (v2f2 i, LIGHTDECL (TEXUNIT2)) : COLOR
{
	half4 texcol = tex2D(_MainTex,i.uv[0]);
	texcol.rgb *= tex2D(_Detail,i.uv[1]).rgb*2;
	
	return DiffuseLight( i.lightDir, i.normal, texcol, LIGHTATT );
} 
ENDCG

			SetTexture [_Detail] {combine texture}
			SetTexture [_MainTex] {combine texture}
			SetTexture [_LightTexture0] {combine texture}
			SetTexture [_LightTextureB0] {combine texture}
		}
	}
	
	// ------------------------------------------------------------------
	// GeForce3/4Ti
	
	SubShader {
		TexCount 4		// Get Geforce2s to ignore this shader
		// Ambient
		Pass {
			Tags {"LightMode" = "PixelOrNone"}
			Color [_PPLAmbient]
			SetTexture[_Detail] { combine previous * texture }
			SetTexture [_MainTex] {constantColor [_Color] Combine texture * primary DOUBLE, texture * constant}
		}
		// Vertex lights
		Pass { 
			Tags {"LightMode" = "Vertex"} 
			Material {
				Diffuse [_Color]
				Emission [_PPLAmbient]
			}
			Lighting On
			SetTexture[_Detail]		{ combine previous * texture }
			SetTexture [_MainTex] {constantColor [_PPLAmbent] Combine texture * primary DOUBLE, texture *  primary}
		}
		// Pixel lights
		Pass {
			Tags { 
				"LightMode" = "Pixel" 
			}
			Material { 
				Diffuse [_Color] 
				Emission [_PPLAmbient]
			}
			Lighting On

CGPROGRAM
// autolight 7
// profiles fp20
// fragment
// fragmentoption ARB_fog_exp2
// fragmentoption ARB_precision_hint_fastest

#include "UnityCG.cginc"
#include "AutoLight.cginc"

struct v2f { 
	float4 hPosition    : POSITION;
	float4 uv: TEXCOORD0;
	float4 uv2: TEXCOORD3;
};  

uniform sampler2D _MainTex;
uniform sampler2D _Detail: TEXUNIT03;

half4 main (v2f i, LIGHTDECL (TEXUNIT1)) : COLOR
{
	half4 temp = tex2D (_MainTex, i.uv.xy); 
	half4 detail = tex2D (_Detail, i.uv2.xy); 
	temp.xyz *= LIGHTCOLOR + _PPLAmbient.xyz; 
 	temp.xyz *= 2;
	temp.xyz *= detail.xyz;
	temp.w *= _PPLAmbient.w;
	return temp;
} 
ENDCG

			SetTexture [_MainTex]{ combine texture * primary DOUBLE}
			SetTexture [_LightTexture0] { combine previous * texture alpha} 
			SetTexture [_LightTextureB0]{ combine previous}
			SetTexture [_Detail]{ combine texture * primary DOUBLE}

		}
	}
	
	// ------------------------------------------------------------------
	// Radeon 7000/9000
	
	Category {
		Material {
			Diffuse [_Color]
			Emission [_PPLAmbient]
		}
		Lighting On
		Fog { Color [_AddFog] }
		Blend AppSrcAdd AppDstAdd
		SubShader {
			// Ambient pass
			Pass {
				Tags {"LightMode" = "PixelOrNone"}
				Color [_PPLAmbient]
				Lighting Off
				SetTexture [_MainTex] {constantColor [_Color] Combine texture * primary DOUBLE, texture * constant}
				SetTexture [_Detail] {combine previous * texture DOUBLE, previous}
			}
			
			// Vertex lights
			Pass { 
				Tags {"LightMode" = "Vertex"}
				Lighting On
				Material {
					Diffuse [_Color]
					Emission [_PPLAmbient]
				}
				SetTexture [_MainTex] {constantColor [_PPLAmbent] Combine texture * primary DOUBLE, texture * primary}
				SetTexture [_Detail] {combine previous * texture DOUBLE, previous}
			}
			
			// Pixel lights with 2 light textures
			Pass {
				Tags {
					"LightMode" = "Pixel"
					"LightTexCount" = "2"
				}
				ColorMask RGB
				SetTexture [_LightTexture0] 	{ combine previous * texture alpha, previous }
				SetTexture [_LightTextureB0]	{
					combine previous * texture alpha + constant, previous
					constantColor [_PPLAmbient]
				}
				SetTexture[_Detail]		{ combine previous * texture DOUBLE, previous }
				SetTexture[_MainTex] 	{ combine previous * texture DOUBLE }
			}
			// Pixel lights with 1 light texture
			Pass {
				Tags {
					"LightMode" = "Pixel"
					"LightTexCount"  = "1"
				}
				ColorMask RGB
				SetTexture [_LightTexture0] {
					combine previous * texture alpha + constant, previous
					constantColor [_PPLAmbient]
				}
				SetTexture[_Detail]		{ combine previous * texture, previous }
				SetTexture[_MainTex] 	{ combine previous * texture DOUBLE }
			}
			// Pixel lights with 0 light textures
			Pass {
				Tags {
					"LightMode" = "Pixel"
					"LightTexCount"  = "0"
				}
				ColorMask RGB
				SetTexture[_Detail]		{ combine previous * texture, previous }
				SetTexture [_MainTex] 	{ combine previous * texture DOUBLE }
			}
		}
	}
}

// Fallback to vertex lit
Fallback " VertexLit", 2

}
