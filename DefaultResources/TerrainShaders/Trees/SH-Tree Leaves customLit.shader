Shader "Hidden/TerrainEngine/Soft Occlusion Leaves customLit" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {  }
		_Cutoff ("Base Alpha cutoff", Range (.5,.9)) = .5
		_BaseLight ("BaseLight", range (0, 1)) = 0.35
		_AO ("Amb. Occlusion", range (0, 10)) = 2.4
		_Occlusion ("Dir Occlusion", range (0, 20)) = 7.5
		_Scale ("Scale", Vector) = (1,1,1,1)
	}
	SubShader {
		Tags {
			"Queue" = "Transparent" 
		}
		Cull Off
		ColorMask RGB
		CGINCLUDE
		#pragma vertex leaves
		#define USE_CUSTOM_LIGHT_DIR 1
		#include "SH_Vertex.cginc"
		ENDCG
		Pass {
			CGPROGRAM
			ENDCG

			AlphaTest GEqual [_Cutoff]
			ZWrite On
			
			SetTexture [_MainTex] { combine primary * texture DOUBLE, texture }
		}
		
		Pass {
			CGPROGRAM
			ENDCG
			// the texture is premultiplied alpha!
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

			SetTexture [_MainTex] { combine primary * texture DOUBLE, texture }
		}
	}
	SubShader {
		Tags {
			"Queue" = "Transparent" 
		}
		Cull Off
		ColorMask RGB
		Pass {
			AlphaTest GEqual [_Cutoff]
			Lighting On
			Material {
				Diffuse [_Color]
				Ambient [_Color]
			}
			SetTexture [_MainTex] { combine primary * texture DOUBLE, texture }
		}		
	}
	
	Fallback Off
}
