Shader "Nature/Soft Occlusion Bark" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,0)
		_MainTex ("Main Texture", 2D) = "white" {  }
		_BaseLight ("BaseLight", range (0, 1)) = 0.35
		_AO ("Amb. Occlusion", range (0, 10)) = 2.4
		_Scale ("Scale", Vector) = (1,1,1,1)
	}
	SubShader {
		Tags {
			"BillboardShader" = "Hidden/TerrainEngine/Soft Occlusion Bark rendertex"
			"TerrainCustomLit" = "Hidden/TerrainEngine/Soft Occlusion Bark customLit"
		}

		Pass {
			CGPROGRAM
			#pragma vertex bark
			#include "SH_Vertex.cginc"
			ENDCG
						
			SetTexture [_MainTex] { combine primary * texture DOUBLE, constant }
		}
	}
	SubShader {
		Tags {
			"BillboardShader" = "Hidden/TerrainEngine/Soft Occlusion Bark rendertex"
			"TerrainCustomLit" = "Hidden/TerrainEngine/Soft Occlusion Bark customLit"
		}
		Pass {
			Lighting On
			Material {
				Diffuse [_Color]
				Ambient [_Color]
			}
			SetTexture [_MainTex] { combine primary * texture DOUBLE, constant }
		}		
	}
	
	Fallback Off
}
