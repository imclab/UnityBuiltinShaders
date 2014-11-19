#ifndef UNITY_UNIVERSAL_UTILS_INCLUDED
#define UNITY_UNIVERSAL_UTILS_INCLUDED

#include "UnityCG.cginc"

// Helper functions, maybe move into UnityCG.cginc


// close to Luminance() func in UnityCG, except:
//  a) different constant - 0.299,0.587,0.114) vs (0.22, 0.707, 0.071)
//  b) SM2.0 - cheap version using .g channel
//  c) precision - half instead of fixed
//  d) both don't handle difference between sRGB/Linear
half RGBToLuminance(half3 color)
{
	#ifdef SHADER_API_SM2
		return color.g;
	#else
		half3 lumSensitivity = half3(0.299,0.587,0.114);
		half luminance = dot(color, lumSensitivity);
		return luminance;
	#endif
}

// Same as ParallaxOffset in Unity CG, except:
//  *) precision - half instead of float
half2 ParallaxOffset1Step (half h, half height, half3 viewDir)
{
	h = h * height - height/2.0;
	half3 v = normalize(viewDir);
	v.z += 0.42;
	return h * (v.xy / v.z);
}

half LerpOneTo(half b, half t)
{
	half oneMinusT = 1 - t;
	return oneMinusT + b * t;
}

half3 LerpWhiteTo(half3 b, half t)
{
	half oneMinusT = 1 - t;
	return half3(oneMinusT, oneMinusT, oneMinusT) + b * t;
}

//NOTE(ROD): For SM2.0 we need to decompress a-la mobile
half3 UnpackScaleNormal(half4 packednormal, half bumpScale)
{
	#if defined(UNITY_NO_DXT5nm)
		return packednormal.xyz * 2 - 1;
	#else
		half3 normal;
		normal.xy = (packednormal.wy * 2 - 1);
		normal.xy *= bumpScale;
		normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
		return normal;
	#endif
}		

half3 BlendNormals(half3 n1, half3 n2)
{
	return normalize(half3(n1.xy + n2.xy, n1.z*n2.z));
}

half3x3 TangentToWorld(half3 normal, half3 tangent, half3 flip)
{
	half3 binormal = cross( normal, tangent ) * flip;
	return half3x3(tangent, binormal, normal );
}

// Derivative maps
// http://www.rorydriscoll.com/2012/01/11/derivative-maps/
// Unused now!

// Project the surface gradient (dhdx, dhdy) onto the surface (n, dpdx, dpdy)
half3 CalculateSurfaceGradient(half3 n, half3 dpdx, half3 dpdy, half dhdx, half dhdy)
{
	half3 r1 = cross(dpdy, n);
	half3 r2 = cross(n, dpdx);
	return (r1 * dhdx + r2 * dhdy) / dot(dpdx, r1);
}

// Move the normal away from the surface normal in the opposite surface gradient direction
half3 PerturbNormal(half3 n, half3 dpdx, half3 dpdy, half dhdx, half dhdy)
{
	//TODO: normalize seems to be necessary when scales do go beyond the 2...-2 range, should we limit that?
	//how expensive is a normalize? Anything cheaper for this case?
	return normalize(n - CalculateSurfaceGradient(n, dpdx, dpdy, dhdx, dhdy));
}

// Calculate the surface normal using the uv-space gradient (dhdu, dhdv)
half3 CalculateSurfaceNormal(half3 position, half3 normal, half2 gradient, half2 uv)
{
	half3 dpdx = ddx(position);
	half3 dpdy = ddy(position);

	half dhdx = dot(gradient, ddx(uv));
	half dhdy = dot(gradient, ddy(uv));

	return PerturbNormal(normal, dpdx, dpdy, dhdx, dhdy);
}


#endif // UNITY_UNIVERSAL_UTILS_INCLUDED
