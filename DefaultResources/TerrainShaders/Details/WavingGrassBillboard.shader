Shader "Hidden/TerrainEngine/Details/BillboardWavingDoublePass" {
	Properties {
		_WavingTint ("Fade Color", Color) = (.7,.6,.5, 0)
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_WaveAndDistance ("Wave and distance", Vector) = (12, 3.6, 1, 1)
		_Cutoff ("Cutoff", float) = 0.5
	}
	SubShader {
		Tags { "Queue" = "Transparent" }

		ColorMask rgb
		Cull Off
		
		Pass {
			CGPROGRAM
			#pragma vertex BillboardVert
			#include "WavingGrass.cginc"
			ENDCG			

			AlphaTest Greater [_Cutoff]

			SetTexture [_MainTex] { combine texture * primary DOUBLE, texture }
		}
		Pass {
			CGPROGRAM
			#pragma vertex BillboardVert
			#include "WavingGrass.cginc"
			ENDCG			

			// Dont write to the depth buffer
			ZWrite off
			
			// Only render non-transparent pixels
			AlphaTest Greater 0

			// And closer to us than first pass (so we don't fill those twice)
			ZTest Less

			// Set up alpha blending
			Blend SrcAlpha OneMinusSrcAlpha
 
			SetTexture [_MainTex] { combine texture * primary DOUBLE, texture } 
		 }
	} 
	
	Fallback Off
}
