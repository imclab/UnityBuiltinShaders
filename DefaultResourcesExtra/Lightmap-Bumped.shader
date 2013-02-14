Shader "Lightmapped/Bumped" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump (RGB)", 2D) = "bump" {}
		_LightMap ("Lightmap (RGB)", 2D) = "black" {}
	}
	SubShader {
		UsePass "Lightmapped/VertexLit/BASE"
		UsePass " Bumped/PPL"
	} 
	FallBack "Lightmapped/VertexLit", 1
}