Shader "Particles/~Additive-Multiply" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_MainTex ("Particle Texture", 2D) = "white" {}
}

Category {
	Tags { "Queue" = "Transparent" }
	Blend One OneMinusSrcAlpha
	ColorMask RGB
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,1) }
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}
	
	// ---- Dual texture cards
	SubShader {
		Pass {
			SetTexture [_MainTex] {
				constantColor [_TintColor]
				combine constant * texture DOUBLE, constant * primary DOUBLE
			}
			SetTexture [_MainTex] {
				combine previous * primary, one - texture * previous
			}
		}
	}
	
	// ---- Single texture cards (does not do color tint)
	SubShader {
		Pass {
			SetTexture [_MainTex] {
				combine texture * primary DOUBLE, one - texture * primary
			}
		}
	}
}
}
