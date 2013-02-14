Shader "Deprecated/Alpha Blended" {
	Properties {
		_TintColor ("Tint Color", Color) = (1,1,1,1)
		_MainTex ("Particle Texture", 2D) = "white"
	}
	
	SubShader {
		Tags { "Queue" = "Transparent" }
		Cull Off
		Lighting Off
		zwrite off
		Fog { color (0,0,0,0)	}
		AlphaTest Greater .01
		Blend SrcAlpha OneMinusSrcAlpha 
		BindChannels {
			Bind "Color", color
			Bind "Vertex", vertex
			Bind "TexCoord", texcoord
		}
		Pass {
			SetTexture [_MainTex] {
				constantColor [_TintColor]
				combine constant * primary DOUBLE
			}
			SetTexture [_MainTex] {
				combine previous * texture
			}
		}
	}
}