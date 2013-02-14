#ifndef LIGHTING_INCLUDED
#define LIGHTING_INCLUDED

struct SurfaceOutput {
	half3 Albedo;
	half3 Normal;
	half3 Emission;
	half Specular;
	half Gloss;
	half Alpha;
};

#ifndef USING_DIRECTIONAL_LIGHT
#if defined (DIRECTIONAL_COOKIE) || defined (DIRECTIONAL)
#define USING_DIRECTIONAL_LIGHT
#endif
#endif

float4 _LightColor0;
float4 _SpecColor;

inline half4 LightingLambert (SurfaceOutput s, half3 lightDir, half atten)
{
	half diff = max (0, dot (s.Normal, lightDir));
	
	half4 c;
	c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten * 2);
	c.a = s.Alpha;
	return c;
}


inline half4 LightingLambert_PrePass (SurfaceOutput s, half4 light)
{
	half4 c;
	c.rgb = s.Albedo * light.rgb;
	c.a = s.Alpha;
	return c;
}


inline half4 LightingBlinnPhong (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
{
	half3 h = normalize (lightDir + viewDir);
	
	half diff = max (0, dot (s.Normal, lightDir));
	
	float nh = max (0, dot (s.Normal, h));
	float spec = pow (nh, s.Specular*128.0) * s.Gloss;
	
	half4 c;
	c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
	c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
	return c;
}

inline half4 LightingBlinnPhong_PrePass (SurfaceOutput s, half4 light)
{
	half spec = light.a * s.Gloss;
	
	half4 c;
	c.rgb = (s.Albedo * light.rgb + light.rgb * _SpecColor.rgb * spec);
	c.a = s.Alpha + spec * _SpecColor.a;
	return c;
}


#endif
