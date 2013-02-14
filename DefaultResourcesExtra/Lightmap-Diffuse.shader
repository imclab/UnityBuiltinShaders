Shader "Lightmapped/Diffuse" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_LightMap ("Lightmap (RGB)", 2D) = "black" {}
	}
	SubShader {
		UsePass "Lightmapped/VertexLit/BASE"
		UsePass " Diffuse/PPL"
	} 
	FallBack " Diffuse", 1
}