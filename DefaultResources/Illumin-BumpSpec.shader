Shader "Self-Illumin/BumpedSpecular" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Bump (RGB) Illumin (A)", 2D) = "bump" {}
	}
	SubShader {
		UsePass "Self-Illumin/VertexLit/BASE"
		UsePass " BumpedSpecular/PPL"
	}
	FallBack "Self-Illumin/Glossy", 1
}