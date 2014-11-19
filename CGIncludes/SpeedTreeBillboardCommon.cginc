#ifndef SPEEDTREE_BILLBOARD_COMMON_INCLUDED
#define SPEEDTREE_BILLBOARD_COMMON_INCLUDED

#define SPEEDTREE_Y_UP

sampler2D _MainTex;
#ifdef EFFECT_BUMP
	sampler2D _BumpMap;
#endif
half4 _Color;
half _Shininess;

#ifdef EFFECT_HUE_VARIATION
	uniform half4 _HueVariation;
#endif

uniform float3 _BillboardNormal;
uniform float3 _BillboardTangent;
uniform float _CameraXZAngle;

uniform float4 _TreeInfo[4];			// x: num of billboard slices; y: 1.0f / (delta angle between slices)
uniform float4 _TreeSize[4];
uniform float4 _ImageTexCoords[32];

uniform float4 _InstanceData;

sampler2D _DitherMaskLOD2D;

struct SpeedTreeBillboardData
{
	float4 vertex		: POSITION;
	float2 texcoord		: TEXCOORD0;
	float3 texcoord1	: TEXCOORD1;
	float3 normal		: NORMAL;
	float4 tangent		: TANGENT;
	float4 color		: COLOR;
};

struct Input
{
	half2 mainUV;
#ifdef EFFECT_HUE_VARIATION
	half HueVariationAmount;
#endif
#ifdef LOD_FADE_CROSSFADE
	half3 myScreenPos;
#endif
};

void vert(inout SpeedTreeBillboardData v, out Input data)
{
	float treeType = v.color.a * 255.0f;
	float4 treeInfo = _TreeInfo[treeType];
	float4 treeSize = _TreeSize[treeType];

	// assume no scaling & rotation
	float3 worldPos = { v.vertex.x + _Object2World[0].w, v.vertex.y + _Object2World[1].w, v.vertex.z + _Object2World[2].w };

#ifdef BILLBOARD_FACE_CAMERA_POS
	float3 eyeVec = normalize(_WorldSpaceCameraPos - worldPos);
	float3 billboardTangent = normalize(float3(-eyeVec.z, 0, eyeVec.x));			// cross(eyeVec, {0,1,0})
	float3 billboardNormal = float3(billboardTangent.z, 0, -billboardTangent.x);	// cross({0,1,0},billboardTangent)
	float3 angle = atan2(billboardNormal.z, billboardNormal.x);						// signed angle between billboardNormal to {0,0,1}
	angle += angle < 0 ? 2 * UNITY_PI : 0;
#else
	float3 billboardTangent = _BillboardTangent;
	float3 billboardNormal = _BillboardNormal;
	float angle = _CameraXZAngle;
#endif

	float3 instanceData = _InstanceData.w > 0 ? _InstanceData.xyz : v.texcoord1.xyz;
	float widthScale = instanceData.x;
	float heightScale = instanceData.y;
	float rotation = instanceData.z;

	float2 percent = v.texcoord.xy;
	float3 billboardPos = (percent.x - 0.5f) * treeSize.x * widthScale * billboardTangent;
	billboardPos.y += (percent.y * treeSize.y + treeSize.z) * heightScale;

	v.vertex.xyz += billboardPos;
	v.vertex.w = 1.0f;
	v.normal = billboardNormal.xyz;
	v.tangent = float4(billboardTangent.xyz,-1);

	float slices = treeInfo.x;
	float invDelta = treeInfo.y;
	angle += rotation;

	float imageIndex = fmod(floor(angle * invDelta + 0.5f), slices);
	float4 imageTexCoords = _ImageTexCoords[treeInfo.z + imageIndex];
	if (imageTexCoords.w < 0)
	{
		data.mainUV = imageTexCoords.xy - imageTexCoords.zw * percent.yx;
	}
	else
	{
		data.mainUV = imageTexCoords.xy + imageTexCoords.zw * percent;
	}

#ifdef EFFECT_HUE_VARIATION
	float worldVar = worldPos.x + worldPos.y + worldPos.z;
	data.HueVariationAmount = frac(worldVar);
	data.HueVariationAmount = saturate(data.HueVariationAmount * _HueVariation.a);
#endif

#ifdef LOD_FADE_CROSSFADE
	float4 pos = mul (UNITY_MATRIX_MVP, v.vertex);
	data.myScreenPos = ComputeScreenPos(pos).xyw;
	data.myScreenPos.xy *= _ScreenParams.xy * 0.25f;
#endif
}

void surf (Input IN, inout SurfaceOutput o) {
#ifdef LOD_FADE_CROSSFADE
	half2 projUV = IN.myScreenPos.xy / IN.myScreenPos.z;
	projUV.y = frac(projUV.y) * 0.0625 /* 1/16 */ + unity_LODFade.y /* quantized lod fade by 16 levels */;
	clip(tex2D(_DitherMaskLOD2D, projUV).a - 0.5);
#endif

	fixed4 tex = tex2D(_MainTex, IN.mainUV);

#ifdef EFFECT_HUE_VARIATION
	half3 shiftedColor = lerp(tex.rgb, _HueVariation.rgb, IN.HueVariationAmount);
	half maxBase = max(tex.r, max(tex.g, tex.b));
	half newMaxBase = max(shiftedColor.r, max(shiftedColor.g, shiftedColor.b));
	maxBase /= newMaxBase;
	maxBase = maxBase * 0.5f + 0.5f;
	// preserve vibrance
	shiftedColor.rgb *= maxBase;
	tex.rgb = saturate(shiftedColor);
#endif

	o.Albedo = tex.rgb * _Color.rgb;
	o.Alpha = tex.a * _Color.a;
	o.Gloss = tex.a;
	o.Specular = _Shininess;
#ifdef EFFECT_BUMP
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.mainUV));
#endif
}

#endif // SPEEDTREE_BILLBOARD_COMMON_INCLUDED
