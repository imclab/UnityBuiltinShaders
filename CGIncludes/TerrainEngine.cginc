#ifndef TERRAIN_ENGINE_INCLUDED
#define TERRAIN_ENGINE_INCLUDED

// Terrain engine shader helpers


// ---- Vertex input structures

struct appdata_tree {
    float4 vertex : POSITION;		// position
    float4 tangent : TANGENT;		// directional AO
    float3 normal : NORMAL;			// normal
    float4 color : COLOR;			// .w = bend factor
    float4 texcoord : TEXCOORD0;	// UV
};

struct appdata_tree_billboard {
	float4 vertex : POSITION;
	float4 color : COLOR;			// Color
	float4 texcoord : TEXCOORD0;	// UV Coordinates 
	float2 texcoord1 : TEXCOORD1;	// Billboard extrusion
};

struct appdata_grass {
	float4 vertex : POSITION;
	float4 color : COLOR;			// XSize, ySize, wavyness, unused
	float4 texcoord : TEXCOORD0;	// UV Coordinates 
	float4 texcoord1 : TEXCOORD1;	// Billboard extrusion
};



// ---- Grass helpers


// Calculate a 4 fast sine-cosine pairs
// val: 	the 4 input values - each must be in the range (0 to 1)
// s:		The sine of each of the 4 values
// c:		The cosine of each of the 4 values
void FastSinCos (float4 val, out float4 s, out float4 c) {
	val = val * 6.408849 - 3.1415927;
	// powers for taylor series
	float4 r5 = val * val;					// wavevec ^ 2
	float4 r6 = r5 * r5;						// wavevec ^ 4;
	float4 r7 = r6 * r5;						// wavevec ^ 6;
	float4 r8 = r6 * r5;						// wavevec ^ 8;

	float4 r1 = r5 * val;					// wavevec ^ 3
	float4 r2 = r1 * r5;						// wavevec ^ 5;
	float4 r3 = r2 * r5;						// wavevec ^ 7;


	//Vectors for taylor's series expansion of sin and cos
	float4 sin7 = {1, -0.16161616, 0.0083333, -0.00019841};
	float4 cos8  = {-0.5, 0.041666666, -0.0013888889, 0.000024801587};

	// sin
	s =  val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;

	// cos
	c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
}


uniform float4 _WavingTint;
uniform float4 _WaveAndDistance; // wind speed, wave size, wind amount, max sqr distance
uniform float4 _CameraPosition;
uniform float3 _CameraRight, _CameraUp;


void TerrainWaveGrass (inout float4 vertex, float waveAmount, float3 color, out float4 outColor)
{
	// Intel GMA X3100 cards on OS X have bugs in this vertex shader part (OS X 10.5.0-10.5.2),
	// transforming vertices to almost infinities.
	// So we multi-compile shaders, and use a non-waving one on X3100 cards.
	
	#ifndef INTEL_GMA_X3100_WORKAROUND
	
	const float4 _waveXSize = float4(0.012, 0.02, 0.06, 0.024) * _WaveAndDistance.y;
	const float4 _waveZSize = float4 (0.006, .02, 0.02, 0.05) * _WaveAndDistance.y;
	const float4 waveSpeed = float4 (0.3, .5, .4, 1.2) * 4;

	float4 _waveXmove = float4(0.012, 0.02, -0.06, 0.048) * 2;
	float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);

	float4 waves;
	waves = vertex.x * _waveXSize;
	waves += vertex.z * _waveZSize;

	// Add in time to model them over time
	waves += _WaveAndDistance.x * waveSpeed;

	float4 s, c;
	waves = frac (waves);
	FastSinCos (waves, s,c);

	s = s * s;
	
	s = s * s;

	float lighting = dot (s, normalize (float4 (1,1,.4,.2))) * .7;

	s = s * waveAmount;

	float3 waveMove = float3 (0,0,0);
	waveMove.x = dot (s, _waveXmove);
	waveMove.z = dot (s, _waveZmove);

	vertex.xz -= waveMove.xz * _WaveAndDistance.z;	
	// Apply Color animation
	float3 waveColor = lerp (float3(0.5,0.5,0.5), _WavingTint.rgb, lighting);
	
	
	// Dry - dyning color interpolate (static)
	outColor.rgb = color * waveColor * 2;
	
	#else
	
	outColor.rgb = color;
	
	#endif
}

void TerrainBillboardGrass( inout float4 pos, float2 offset )
{
	float3 grasspos = pos.xyz - _CameraPosition.xyz;
	if (dot(grasspos, grasspos) > _WaveAndDistance.w)
		offset = 0.0;
    pos.xyz += (offset.x - 0.5) * _CameraRight.xyz;
	pos.xyz += offset.y * _CameraUp.xyz;
}


// ---- Tree helpers


uniform float4 _Scale;
uniform float4x4 _TerrainEngineBendTree;

void TerrainAnimateTree( inout float4 pos, float alpha )
{
	pos.xyz *= _Scale.xyz;
	float3 bent = mul((float4x3)_TerrainEngineBendTree, pos.xyz);
	pos.xyz = lerp( pos.xyz, bent, alpha );
}


// ---- Billboarded tree helpers


uniform float3 _TreeBillboardCameraRight, _TreeBillboardCameraUp;
uniform float4 _TreeBillboardCameraPos;
uniform float4 _TreeBillboardDistances; // x = max distance ^ 2

void TerrainBillboardTree( inout float4 pos, float2 offset )
{
	float3 treePos = pos.xyz - _TreeBillboardCameraPos;
	float treeDistanceSqr = dot(treePos, treePos);
	if( treeDistanceSqr > _TreeBillboardDistances.x )
		offset.xy = 0.0;
	pos.xyz += offset.x * _TreeBillboardCameraRight.xyz;
	pos.xyz += offset.y * _TreeBillboardCameraUp.xyz;
}



#endif
