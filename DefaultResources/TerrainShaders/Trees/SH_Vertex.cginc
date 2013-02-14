#include "UnityCG.cginc"

struct appdata {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD0;
};
uniform float _Occlusion, _AO, _BaseLight;
uniform float4 _Color;
uniform float4 _Scale;
uniform float3[4] _TerrainTreeLightDirections;
uniform float4x4 _TerrainEngineBendTree;

struct v2f {
	float4 pos : POSITION;
	float fog : FOGC;
	float4 uv : TEXCOORD0;
	float4 color : COLOR0;
};

v2f leaves(appdata v) {
	v2f o;
	// Calc vertex position
	float4 vertex = v.vertex * _Scale;
	float4 bent = mul(_TerrainEngineBendTree, vertex);
	vertex = lerp(vertex, bent, v.color.w);
	vertex.w = 1;
	
	o.pos = mul(glstate.matrix.mvp, vertex);
	o.fog = o.pos.z;
	o.uv = v.texcoord;
	
	float4 lightDir;
	lightDir.w = _AO;

	float4 lightColor = glstate.lightmodel.ambient;
	for (int i = 0; i < 4; i++) {
		#ifdef USE_CUSTOM_LIGHT_DIR
		lightDir.xyz = _TerrainTreeLightDirections[i];
		#else
		lightDir.xyz = mul ( glstate.light[i].position.xyz, (float3x3)glstate.matrix.invtrans.modelview[0]);
		#endif

		lightDir.xyz *= _Occlusion;
		float occ =  dot (v.tangent, lightDir);
		occ = max(0, occ);
		occ += _BaseLight;
		lightColor += glstate.light[i].diffuse * occ;
	}

	lightColor.a = 1;
//	lightColor = saturate(lightColor);
	
	o.color = lightColor * _Color;
	#ifdef WRITE_ALPHA_1
	o.color.a = 1;
	#endif
	return o; 
}

v2f bark(appdata v) {
	v2f o;
	// Calc vertex position
	float4 vertex = v.vertex * _Scale;
	float4 bent = mul(_TerrainEngineBendTree, vertex);
	vertex = lerp(vertex, bent, v.color.w);
	vertex.w = 1;

	o.pos = mul(glstate.matrix.mvp, vertex);
	o.fog = o.pos.z;
	o.uv = v.texcoord;
	
	float4 lightDir;
	lightDir.w = _AO;

	float4 lightColor = glstate.lightmodel.ambient;
	for (int i = 0; i < 4; i++) {
		#ifdef USE_CUSTOM_LIGHT_DIR
		lightDir.xyz = _TerrainTreeLightDirections[i];
		#else
		lightDir.xyz = mul ( glstate.light[i].position.xyz, (float3x3)glstate.matrix.invtrans.modelview[0]);
		#endif
		float occ = dot (lightDir.xyz, v.normal);
		occ = max(0, occ);
		occ *=  _AO * v.tangent.w + _BaseLight;		
		lightColor += glstate.light[i].diffuse * occ;
	}
	
	lightColor.a = 1;
	o.color = lightColor * _Color;	
	
	#ifdef WRITE_ALPHA_1
	o.color.a = 1;
	#endif
	return o; 
}
