Shader "Hidden/TerrainEngine/BillboardTree" {
	Properties {
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	}
	
	SubShader {
		Tags { "Queue" = "Transparent" }
		
		Pass {

			CGPROGRAM
			#pragma vertex Vertex
			#include "UnityCG.cginc"		// Get standard Unity constants
			
			struct AppData {
				float4 vertex : POSITION; 		
				float4 color : COLOR;			// color.r, color.g, color.b
				float4 texcoord : TEXCOORD0;		// UV Coordinates 
				float2 texcoord1 : TEXCOORD1;		// xy offset
			};
			
			struct v2f {
				float4 pos : POSITION;
				float fog : FOGC;
				float4 color : COLOR0;
				float4 uv : TEXCOORD0;	// [tree uv]
			};
			
			uniform float3 _TreeBillboardCameraRight, _TreeBillboardCameraUp;
			uniform float4 _TreeBillboardCameraPos;
			uniform float4 _TreeBillboardDistances; // x = max distance ^ 2
			
			v2f Vertex (AppData v) {
				v2f o;
				
				float4 vertex = v.vertex;
				float2 xyOffset = v.texcoord1;
				
				float4 offset = vertex - _TreeBillboardCameraPos;
				float distanceSqr = dot(offset,offset);
				if (distanceSqr > _TreeBillboardDistances.x)
				{
					xyOffset.xy = 0.0F;
				}
				
				// Apply billboard extrusion
				vertex.xyz += xyOffset.x * _TreeBillboardCameraRight.xyz;
				vertex.xyz += xyOffset.y * _TreeBillboardCameraUp.xyz;
				
				float4 pos = mul (glstate.matrix.mvp, vertex);
				o.pos = pos;
				o.fog = o.pos.z;
				o.uv = v.texcoord;
				o.color = v.color;
				return o;
			}
			ENDCG			

			// Premultiplied alpha
			ColorMask rgb
			// Doesn't actually look so bad!
			Blend SrcAlpha OneMinusSrcAlpha

			ZWrite Off
			Cull Off
			AlphaTest Greater 0
			SetTexture [_MainTex] { combine texture * primary, texture }
		}
	}
	
	Fallback Off
}