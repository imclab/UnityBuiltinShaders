Shader " Diffuse (fast)" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

// Calculates lighting per vertex, but applies
// light attenuation maps or spot cookies per pixel.
// Quite fine for tesselated geometry.

Category {
	Lod 0
	Blend AppSrcAdd AppDstAdd
	Fog { Color [_AddFog] }
	
	// ------------------------------------------------------------------
	// ARB fragment program
	
	SubShader {
		// Ambient pass
		Pass {
			Name "BASE"
			Tags {"LightMode" = "PixelOrNone"}
			Color [_PPLAmbient]
			SetTexture [_MainTex] {constantColor [_Color] Combine texture * primary DOUBLE, texture * constant}
		}
		// Vertex lights
		Pass { 
			Name "BASE"
			Tags {"LightMode" = "Vertex"}
			Lighting On
			Material {
				Diffuse [_Color]
				Emission [_PPLAmbient]
			}
			SetTexture [_MainTex] { constantColor [_Color] Combine texture * primary DOUBLE, texture * constant}
		}
		// Pixel lights
		Pass {
			Name "PPL"
			Tags { 
				"LightMode" = "Pixel"
				"LightTexCount" = "012"
			}
			Material { Diffuse [_Color] }
			Lighting On

CGPROGRAM
// autolight 7
// profiles arbfp1
// fragment frag
// fragmentoption ARB_fog_exp2
// fragmentoption ARB_precision_hint_fastest

#include "UnityCG.cginc"
#include "AutoLight.cginc"

struct v2f {
	float2 uv : TEXCOORD0;
	float4 diff : COLOR0;
};  

uniform sampler2D _MainTex : register(s0);

half4 frag (v2f i, LIGHTDECL (TEXUNIT1)) : COLOR
{
	half4 texcol = tex2D( _MainTex, i.uv );
	half4 c;
	c.xyz = texcol.xyz * i.diff.xyz * (LIGHTATT * 2);
	c.w = 0;
	return c;
} 
ENDCG
			SetTexture [_MainTex] {combine texture}
			SetTexture [_LightTexture0] {combine texture}
			SetTexture [_LightTextureB0] {combine texture}
		}
	}

	// ------------------------------------------------------------------
	// Radeon 7000 / 9000
	
	Category {
		Material {
			Diffuse [_Color]
			Emission [_PPLAmbient]
		}
		Lighting On
		SubShader {
			// Ambient pass
			Pass {
				Name "BASE"
				Tags {"LightMode" = "PixelOrNone"}
				Color [_PPLAmbient]
				Lighting Off
				SetTexture [_MainTex] {Combine texture * primary DOUBLE}
				SetTexture [_MainTex] {Combine texture * primary DOUBLE}
				SetTexture [_MainTex] {Combine texture * primary DOUBLE, primary * texture}
			}
			// Vertex lights
			Pass {
				Name "BASE"
				Tags {"LightMode" = "Vertex"}
				SetTexture [_MainTex] {Combine texture * primary DOUBLE, primary * texture}
			}
			// Pixel lights with 2 light textures
			Pass {
				Name "PPL"
				Tags {
					"LightMode" = "Pixel"
					"LightTexCount"  = "2"
				}
				ColorMask RGB
				SetTexture [_LightTexture0] 	{ combine previous * texture alpha, previous }
				SetTexture [_LightTextureB0]	{ 
					combine previous * texture alpha + constant, previous
					constantColor [_PPLAmbient]
				}
				SetTexture [_MainTex] {combine previous * texture DOUBLE}
			}
			// Pixel lights with 1 light texture
			Pass {
				Name "PPL"
				Tags {
					"LightMode" = "Pixel"
					"LightTexCount"  = "1"
				}
				ColorMask RGB
				SetTexture [_LightTexture0] {
					combine previous * texture alpha + constant, previous
					constantColor [_PPLAmbient]
				}
				SetTexture [_MainTex] { combine previous * texture DOUBLE }
			}
			// Pixel lights with 0 light textures
			Pass {
				Name "PPL"
				Tags {
					"LightMode" = "Pixel"
					"LightTexCount" = "0"
				}
				ColorMask RGB
				SetTexture[_MainTex] { combine previous * texture DOUBLE }
			}
		}
	}

	// ------------------------------------------------------------------
	// GeForce 2/4MX
	
 	SubShader {
		Pass {
			Tags {"LightMode" = "None"}
			Blend AppSrcAdd AppDstAdd
			Color [_PPLAmbient]
			SetTexture [_MainTex] {
				Combine texture * primary DOUBLE, texture * primary
			}
		}

		Pass {
			Name "PPL"
			Tags {
				"LightMode" = "Pixel"
				"LightTexCount" = "2"
			}
			Blend AppSrcAdd AppDstAdd
			Material {
				Diffuse [_Color]
			}
			Lighting On
Program "" {
SubProgram {
  Local 0, [_PPLAmbient]
  Local 1 , [_Color]

  "!!RC1.0
  {   
    alpha {
	spare1 = tex0.a * tex1.a; 
    } 
  }
  {
    rgb {
	discard = spare1.a * col0.rgb;
	discard = const0.rgb;
	col0 = sum(); 
   }
    alpha { 
	col0 = const0;
    } 
  }
  out.rgb = unsigned(col0.rgb);
  out.a = unsigned(col0.a);
  " 
}

}
			SetTexture [_LightTexture0] { combine texture alpha}
			SetTexture [_LightTextureB0]{ combine texture alpha * previous}
		}
		Pass {
			Name "PPL"
			Tags {
				"LightMode" = "Pixel" 		// Per-pixel mode
				"LightTexCount" = "2"		// 2-tex only
				"LightCount" = "0"			// Only refnder this pass once
			}
			Blend DstColor SrcColor
			SetTexture [_MainTex] { constantColor (0,0,0,.5) combine texture, constant }
		}
		Pass {	// add in 1-tex lights
			Name "PPL"
			Tags {
				"LightMode" = "Pixel" 
				"LightTexCount" = "01"
			}
			Blend AppSrcAdd AppDstAdd
			Lighting On
			Material {
				Diffuse [_Color]
			}
Program "" {
SubProgram {
  Local 0, [_PPLAmbient]
  "!!RC1.0
  {
    rgb {
      discard = col0.rgb * tex0.a;
      discard = const0.rgb;
      col0 = sum();
    }
    alpha {
	col0 = const0 * tex0.a;
    }
  }
  {
    rgb
    {
      col0 = col0.rgb * tex1.rgb;
      scale_by_two();
    }
  }
  out.rgb = unsigned(col0.rgb);
  out.a = unsigned(col0.a);
  "
}
}
			SetTexture [_LightTexture0] { combine texture alpha}
			SetTexture [_MainTex] {combine texture}
		}
		Pass {
			Tags {"LightMode" = "Vertex"}
			Blend AppSrcAdd AppDstAdd
			Material {
				Diffuse [_Color]
				Emission [_PPLAmbient]
			}
			Lighting On
			SetTexture [_MainTex] { constantColor [_PPLAmbient] Combine texture * primary DOUBLE, texture * constant}
		}
	}
}

Fallback " VertexLit", 2

}