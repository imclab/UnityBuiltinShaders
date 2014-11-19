Shader "Legacy Shaders/Reflective/Bumped VertexLit" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Spec Color", Color) = (1,1,1,1)
	_Shininess ("Shininess", Range (0.1, 1)) = 0.7
	_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
	_MainTex ("Base (RGB) RefStrength (A)", 2D) = "white" {}
	_Cube ("Reflection Cubemap", Cube) = "" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
}

Category {
	Tags { "RenderType"="Opaque" }
	LOD 250
	SubShader {
		UsePass "Reflective/Bumped Unlit/BASE"

		Pass {
			Tags { "LightMode" = "Vertex" }
			Blend One One ZWrite Off
			Lighting On

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fog

#include "UnityCG.cginc"

struct v2f {
	float2 uv : TEXCOORD0;
	UNITY_FOG_COORDS(1)
	fixed4 diff : COLOR0;
	float4 pos : SV_POSITION;
};

float3 Shade4SpotLights (float4 vertex, float3 normal)
{
	float3 viewpos = mul (UNITY_MATRIX_MV, vertex).xyz;
	float3 viewN = normalize (mul ((float3x3)UNITY_MATRIX_IT_MV, normal));
	float3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;
	for (int i = 0; i < 4; i++) {
		float3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
		float lengthSq = dot(toLight, toLight);
		float atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z);

		toLight *= rsqrt(lengthSq);

		float rho = max (0, dot(toLight, unity_SpotDirection[i].xyz));
		float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
		atten *= saturate(spotAtt);

		float diff = max (0, dot (viewN, toLight));
		lightColor += unity_LightColor[i].rgb * (diff * atten);
	}
	return lightColor;
}

uniform float4 _MainTex_ST;
uniform float4 _Color;

v2f vert (appdata_base v)
{
	v2f o;
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
	float4 lighting = float4(Shade4SpotLights(v.vertex, v.normal),_Color.w);
	o.diff = lighting * _Color;
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

uniform sampler2D _MainTex;

fixed4 frag (v2f i) : SV_Target
{
	fixed4 temp = tex2D (_MainTex, i.uv);
	fixed4 c;
	c.xyz = (temp.xyz * i.diff.xyz) * 2;
	c.w = temp.w * i.diff.w;
	UNITY_APPLY_FOG_COLOR(i.fogCoord, c, fixed4(0,0,0,0)); // fog towards black due to our blend mode
	return c;
}
ENDCG

		}
	}
}

FallBack "Legacy Shaders/Reflective/VertexLit"
}
