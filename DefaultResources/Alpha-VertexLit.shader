Shader "Transparent/VertexLit" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Spec Color", Color) = (1,1,1,0)
	_Emission ("Emmisive Color", Color) = (0,0,0,0)
	_Shininess ("Shininess", Range (0.1, 1)) = 0.7
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
}

Category {
	ZWrite Off
	Alphatest Greater 0
	Tags {Queue=Transparent}
	Blend SrcAlpha OneMinusSrcAlpha 
	ColorMask RGB
	SubShader {
		Material {
			Diffuse [_Color]
			Ambient [_Color]
			Shininess [_Shininess]
			Specular [_SpecColor]
			Emission [_Emission]	
		}
		Pass {
			Lighting On
			SeparateSpecular On
			SetTexture [_MainTex] {
				Combine texture * primary DOUBLE, texture * primary
			} 
		}
	} 
}
}