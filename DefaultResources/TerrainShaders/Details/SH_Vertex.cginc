#include "UnityCG.cginc"

struct appdata {
    float4 vertex;
    float4 tangent;
    float3 normal;
    float4 texcoord;
};
uniform float _Occlusion, _AO, _BaseLight;
uniform float4 _Color;
uniform float4 _Scale;

struct v2f {
	float4 pos : POSITION;
	float fog : FOGC;
	float4 uv : TEXCOORD0;
	float4 color : COLOR0;
};
v2f vert(appdata v) {
	v2f o;
	// Calc vertex position
	float4 vertex = v.vertex * _Scale;
	o.pos = mul(glstate.matrix.mvp, vertex);
	o.fog = o.pos.z;
	o.uv = v.texcoord;
	
	float4 lightDir;
	lightDir.w = _AO;

	float4 lightColor = glstate.lightmodel.ambient;
	for (int i = 0; i < 4; i++) {
		lightDir.xyz = mul ( glstate.light[i].position.xyz, (float3x3)glstate.matrix.invtrans.modelview[0]);
		lightDir.xyz *= _Occlusion;
		float occ =  dot (v.tangent, lightDir);
		occ += _BaseLight;
		lightColor += glstate.light[i].diffuse * occ;
	}
	
	o.color = lightColor * _Color;	
	return o; 
}