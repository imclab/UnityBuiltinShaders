#include "UnityCG.cginc"

uniform float4 _Splat0_ST,_Splat1_ST,_Splat2_ST,_Splat3_ST,_Splat4_ST;
uniform float4 _Splat5_ST,_Splat6_ST,_Splat7_ST,_Splat8_ST,_Splat9_ST;

struct v2f {
	float4 pos : POSITION;
	float fog : FOGC;
	float4 uv[(TEXTURECOUNT+1)/2 + 1] : TEXCOORD0;
	float4 color : COLOR;
};


uniform sampler2D _Control;
uniform sampler2D _Control1;
uniform sampler2D _Splat0,_Splat1,_Splat2,_Splat3;
uniform sampler2D _Splat4,_Splat5,_Splat6,_Splat7;


float4 CalculateVertexLights (float3 objSpaceNormal) {
	float3 normal = mul (objSpaceNormal, (float3x3)glstate.matrix.transpose.modelview[0]);
	
	// Do vertex light calculation
	float4 lightColor = glstate.lightmodel.ambient;
	for (int i = 0; i < 4; i++) {
		float3 lightDir = glstate.light[i].position.xyz;
		float lightAmt = saturate( dot (normal, lightDir) );
		lightColor += glstate.light[i].diffuse * lightAmt;
	}

	return lightColor;
}

void CalculateSplatUV (float2 baseUV, inout v2f o) {
	o.uv[0].xy = baseUV;	
	#if TEXTURECOUNT >= 1
	o.uv[1].xy = TRANSFORM_TEX (baseUV, _Splat0);	
	#endif
	#if TEXTURECOUNT >= 2
	o.uv[1].zw = TRANSFORM_TEX (baseUV, _Splat1);	
	#endif
	#if TEXTURECOUNT >= 3
	o.uv[2].xy = TRANSFORM_TEX (baseUV, _Splat2);	
	#endif
	#if TEXTURECOUNT >= 4
	o.uv[2].zw = TRANSFORM_TEX (baseUV, _Splat3);	
	#endif
	#if TEXTURECOUNT >= 5
	o.uv[3].xy = TRANSFORM_TEX (baseUV, _Splat4);	
	#endif
	#if TEXTURECOUNT >= 6
	o.uv[3].zw = TRANSFORM_TEX (baseUV, _Splat5);	
	#endif
	#if TEXTURECOUNT >= 7
	o.uv[4].xy = TRANSFORM_TEX (baseUV, _Splat6);	
	#endif
	#if TEXTURECOUNT >= 8
	o.uv[4].zw = TRANSFORM_TEX (baseUV, _Splat7);	
	#endif	
}

half4 CalculateSplat (v2f i) {
	half4 color;
	#if TEXTURECOUNT >= 1
	half4 control = tex2D (_Control, i.uv[0].xy); 
	color = control.r * tex2D (_Splat0, i.uv[1].xy);
	#endif
	#if TEXTURECOUNT >= 2
	color += control.g * tex2D (_Splat1, i.uv[1].zw);
	#endif
	#if TEXTURECOUNT >= 3
	color += control.b * tex2D (_Splat2, i.uv[2].xy);
	#endif
	#if TEXTURECOUNT >= 4
	color += control.a * tex2D (_Splat3, i.uv[2].zw);
	#endif
	#if TEXTURECOUNT >= 5
	control = tex2D (_Control1, i.uv[0].xy); 
	color = control.r * tex2D (_Splat4, i.uv[3].xy);
	#endif
	#if TEXTURECOUNT >= 6
	color += control.g * tex2D (_Splat5, i.uv[3].zw);
	#endif
	#if TEXTURECOUNT >= 7
	color += control.b * tex2D (_Splat6, i.uv[4].xy);
	#endif
	#if TEXTURECOUNT >= 8
	color += control.a * tex2D (_Splat7, i.uv[4].zw);
	#endif
	
	return color;	
}

float4 VertexlitSplatFragment (v2f i) : COLOR {
	half4 col = CalculateSplat (i) * i.color;
	col *= float4 (2,2,2,0);
	return col;
}

v2f VertexlitSplatVertex (appdata_base v) {
	v2f o;
	
	o.pos = mul(glstate.matrix.mvp, v.vertex);
	o.fog = o.pos.z;
	o.color = CalculateVertexLights (v.normal);
	CalculateSplatUV (v.texcoord, o);

	return o;
}

uniform sampler2D _LightMap;

float4 LightmapSplatFragment (v2f i) : COLOR {
	half4 col = CalculateSplat (i) * tex2D (_LightMap, i.uv[0].xy);
	col *= float4 (2,2,2,0);
	return col;
}

v2f LightmapSplatVertex (appdata_base v) {
	v2f o;
	
	o.pos = mul(glstate.matrix.mvp, v.vertex);
	o.fog = o.pos.z;
	CalculateSplatUV (v.texcoord, o);

	return o;
}

