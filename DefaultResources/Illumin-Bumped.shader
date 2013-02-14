Shader "Self-Illumin/Bumped" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Bump (RGB) Illumin (A)", 2D) = "bump" {}
	}
	SubShader {
		UsePass "Self-Illumin/VertexLit/BASE"
		UsePass " Bumped/PPL"
	} 
	FallBack "Self-Illumin/VertexLit", 1
}