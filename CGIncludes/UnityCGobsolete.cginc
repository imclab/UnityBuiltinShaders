#ifndef UNITY_CG_OBSOLETE_INCLUDED
#define UNITY_CG_OBSOLETE_INCLUDED

// This contains obsolete functions/values. Don't use them,
// they are here only to not break existing shaders.

// Expand RGB color into signed for DOT3
#define EXPANDDOT3(a) (2 * (a - .5) * 2)
// Pack RGB color into unsigned for DOT3
#define PACKDOT3(a) (a * .5 + float3 (.5, .5, .5))


uniform float4 _LightColor0;


float3 CalculateReflectionVector (float4 pos, float3 normal) {
	// Get eye-space position
	float4 posW = mul (glstate.matrix.modelview[0], pos);
	// Compute normal
	float3 N = mul ((float3x3)glstate.matrix.invtrans.modelview[0], normal);
	return reflect (posW.xyz, N);
}

float3 DiffuseDot3 (int lightNo, float4 vertex, float3 normal, float4 tangent) {
    float3 retval, lightDir = {1,0,0};
    lightDir = normalize ( _ObjectSpaceLightPos[lightNo].xyz - vertex.xyz * _ObjectSpaceLightPos[lightNo].www);	
    float3 binormal = cross (normal, tangent.xyz);
    retval.x = -dot (tangent.xyz, lightDir) * tangent.w;
    retval.y = dot (binormal, lightDir);
    retval.z = dot (normal, lightDir);
    return retval;
}


struct Light {
	float4 GetLightColor (int lightNo) 		{ return glstate.light[lightNo].diffuse;}
	float4 GetLightPosition (int lightNo)		{ return glstate.light[lightNo].position; }
	// Returns attenuation factor between 0 - 1

	// Attenuation for point lights
	float PointAttenuate (int lightNo, float4 pos) {
		float3 dif = _ObjectSpaceLightPos[lightNo].xyz - (float3)pos;
		float dist = dot (dif, dif);
		return 1.0 / (glstate.light[lightNo].attenuation.x + dist * glstate.light[lightNo].attenuation.z);
	}

	// Attenuate for spotLights
	float Attenuate (int lightNo, float4 pos) {
		return PointAttenuate (lightNo, pos);
	}

	// returns diffuse color
	float3 DiffuseColor (int lightNo, float4 pos, float3 normal) {
		float3 dir = normalize (_ObjectSpaceLightPos[lightNo].xyz - (float3)pos);
		return  glstate.lightprod[lightNo].diffuse.rgb * dot (dir, normal);
	}
	float3 SpecularCubeMapCoord (int lightNo, float4 pos, float3 normal) {
		float3 refVector = CalculateReflectionVector(pos, normal);
		return mul (_LightSpecularRotation[lightNo], refVector);
	}
	float4 TextureCoord (int texNo, float4 pos) {
		return mul (glstate.matrix.texture[texNo], pos);
	}

	float3 DiffuseDot3 (int lightNo, float4 vertex, float3 normal, float4 tangent) {
		float3 retval, lightDir;
		lightDir = normalize ( _ObjectSpaceLightPos[lightNo].xyz - vertex.xyz * _ObjectSpaceLightPos[lightNo].www);
		
		float3 binormal = cross (normal, tangent.xyz);
		retval.x = dot (tangent.xyz, lightDir) * tangent.w;
		retval.y = -dot (-binormal, lightDir);
		retval.z = dot (normal, lightDir);
		return retval;
	}

	float3 LightPos (int lightNo, float4 pos) {
		return _ObjectSpaceLightPos[lightNo].xyz - (float3)pos;
	}
};


#endif
