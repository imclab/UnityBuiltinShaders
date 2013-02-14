#include "UnityCG.cginc"


uniform float4 _WavingTint;
uniform float4 _WaveAndDistance; // wind speed, wave size, wind amount, max sqr distance

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
			
void WaveGrass (inout float3 vertex, float waveAmount, float3 color, out float4 outColor) {
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
//  TODO: if we fade towards this depending on wind size, it will look better as the slider goes to the right
//	float lighting = dot (s, normalize (float4 (.7,.5,1,1))) * .7;

	s = s * waveAmount;

	float3 waveMove = float3 (0,0,0);
	waveMove.x = dot (s, _waveXmove);
	waveMove.z = dot (s, _waveZmove);

	vertex.xz -= waveMove.xz * _WaveAndDistance.z;	
	/// Apply Color animation
	float3 waveColor = lerp (float3(0.5,0.5,0.5), _WavingTint.rgb, lighting);
	
	
	// Dry - dyning color interpolate (static)
	outColor.rgb = color * waveColor * 2;
}




struct AppData {
	float4 vertex : POSITION;
	float4 color : COLOR;			// XSize, ySize, wavyness,unused
	float4 texcoord : TEXCOORD0;	// UV Coordinates 
	float4 texcoord1 : TEXCOORD1;	// UV Coordinates 
};

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
	float fog : FOGC;
	float4 uv : TEXCOORD0;	// [grass uv, lightmap uv, noise uvw]
};

uniform float4 _CameraPosition;

v2f vert (AppData v) {
	v2f o;

	float4 vertex = v.vertex;
	
	float waveAmount = v.color.a * _WaveAndDistance.z;
	float3 color = v.color.rgb;
	
	// Wave the grass
	WaveGrass (vertex.xyz, waveAmount, color, o.color);

	// Transform grass into world space
	float4 pos = mul (glstate.matrix.mvp, vertex);
	
	o.pos = pos;
	o.fog = o.pos.z;
	o.uv = v.texcoord;

	float4 offset = vertex - _CameraPosition;
	// Radeon HD drivers on OS X 10.4.10 don't saturate vertex colors properly...
	o.color.a = saturate( _WaveAndDistance.w - dot(offset, offset) );

	return o;
}

uniform float3 _CameraRight, _CameraUp;

v2f BillboardVert (AppData v) {
	v2f o;

	float4 vertex = v.vertex;
	
	float4 offset = vertex - _CameraPosition;
	if (dot(offset, offset) > _WaveAndDistance.w)
		v.texcoord1 *= 0;

    vertex.xyz += (v.texcoord1.x - 0.5) * _CameraRight.xyz;
	vertex.xyz += v.texcoord1.y * _CameraUp.xyz;

	float waveAmount = v.texcoord1.y;//v.color.a;
	float3 color = v.color.rgb;
	
	// Wave the grass
	WaveGrass (vertex.xyz, waveAmount, color, o.color);
		
	// Transform grass into world space
	float4 pos = mul (glstate.matrix.mvp, vertex);
	
	o.pos = pos;
//	o.pos.z *= lerp (1, .999, v.texcoord1.y);
	o.fog = o.pos.z;
	o.uv = v.texcoord;
	return o;
}
