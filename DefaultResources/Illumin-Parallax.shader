Shader "ParallaxBump/IlluminDiffuse" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_Parallax ("Height", Range (0.005, 0.08)) = 0.02
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Bump (RGB) HeightIllum (A)", 2D) = "bump" {}
	}
	SubShader {
		UsePass "Self-Illumin/VertexLit/BASE"
		UsePass "ParallaxBump/Diffuse/PPL"
	}
	FallBack "Self-Illumin/Bumped", 1
}