Shader "Skybox/Procedural" {
Properties {
	_SunSize ("Sun Size", Float) = 1
	// 255,236,188
	_SunTint ("Sun Tint", Color) = (1, .925, .737, 1)
	_SkyExponent ("Sky Gradient", Float) = 1.5
	// 2,76,150 :: 146,188,255 :: 234,253,255 :: 94,89,87
	_SkyTopColor ("Sky Top", Color) = (.008, .296, .586, 1)
	_SkyMidColor ("Sky Middle", Color) = (.570, .734, 1, 1)
	_SkyEquatorColor ("Sky Equator", Color) = (.917, .992, 1, 1)
	_GroundColor ("Ground", Color) = (.369, .349, .341, 1)
}

SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
	Cull Off ZWrite Off

	Pass {
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		#include "UnityCG.cginc"
		#include "Lighting.cginc"

		half _SunSize;
		half4 _SunTint;
		half _SkyExponent;
		half4 _SkyTopColor;
		half4 _SkyEquatorColor;
		half4 _SkyMidColor;
		half4 _GroundColor;

		struct appdata_t {
			float4 vertex : POSITION;
			float3 texcoord : TEXCOORD0;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			float3 texcoord : TEXCOORD0;
			half4 normalAndSunExp : TEXCOORD1;
		};

		v2f vert (appdata_t v)
		{
			v2f o;
			o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
			o.texcoord = v.texcoord;
			o.normalAndSunExp.xyz = normalize(mul((float3x3)_Object2World, v.vertex.xyz));
			o.normalAndSunExp.w = 256.0/_SunSize;
			return o;
		}

		fixed4 frag (v2f i) : SV_Target
		{
			half3 normal = normalize(i.normalAndSunExp.xyz);
			half t = normal.y;

			half3 sunColor = _LightColor0.rgb * 2 * _SunTint * 2;
			half3 sunDir = _WorldSpaceLightPos0.xyz;
			half3 sun = pow(max(0,dot(normal, sunDir)), i.normalAndSunExp.w);

			half3 c;
			if (t > 0)
			{
				half skyT = 1-pow (1-t, _SkyExponent);
				if (skyT < 0.25)
					c = lerp (_SkyEquatorColor.rgb, _SkyMidColor.rgb,skyT*4);
				else
					c = lerp (_SkyMidColor.rgb, _SkyTopColor.rgb, (skyT-0.25)*(4.0/3.0));
			}
			else
			{
				half groundT = 1-pow (1+t, 10.0);
				c = lerp (_SkyEquatorColor.rgb, _GroundColor.rgb, groundT);
				sun *= (1-groundT);
			}

			c = lerp(c, max(c, sunColor), sun);

			return half4(c, 1);
		}
		ENDCG 
	}
} 	


Fallback Off

}
