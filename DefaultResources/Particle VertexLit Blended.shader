Shader "Particles/VertexLit Blended" {
Properties {
	_EmisColor ("Emissive Color", Color) = (.2,.2,.2,0)
	_MainTex ("Particle Texture", 2D) = "white" {}
}

SubShader {
	Tags { "Queue" = "Transparent" }
	Cull Off
	Lighting On
	Material { Emission [_EmisColor] }
	ColorMaterial AmbientAndDiffuse
	ZWrite Off
	ColorMask RGB
	Blend SrcAlpha OneMinusSrcAlpha
	AlphaTest Greater .001
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}
	Pass { 
		SetTexture [_MainTex] { combine primary * texture }
	}
}
}