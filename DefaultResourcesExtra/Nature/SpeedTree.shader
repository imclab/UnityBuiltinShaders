Shader "Nature/SpeedTree"
{
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0,0,0,0)
		_HueVariation ("Hue Variation", Color) = (1.0,0.5,0.0,0.1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.1
		_MainTex ("Base (RGB) TransGloss (A)", 2D) = "white" {}
		_DetailTex ("Detail", 2D) = "black" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.333
		[MaterialEnum(None,0,Fastest,1,Fast,2,Better,3,Best,4,Palm,5)] _WindQuality ("Wind Quality", Range(0,5)) = 0
	}

	// targeting SM3.0+
	SubShader
	{
		Tags
		{
			"Queue"="Geometry"
			"IgnoreProjector"="True"
			"RenderType"="Opaque"
			"DisableBatching"="LODFading"
		}
		LOD 400

		Cull Off
		AlphaToMask True

		CGPROGRAM
			#pragma surface surf Lambert vertex:vert nolightmap
			#pragma target 3.0
			#pragma multi_compile __ LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
			#pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_BRANCH_BLEND GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_FACING_LEAF GEOM_TYPE_MESH
			#pragma shader_feature EFFECT_BUMP
			#pragma shader_feature EFFECT_HUE_VARIATION
			#define ENABLE_WIND
			#include "SpeedTreeCommon.cginc"
		ENDCG

		Pass
		{
			Name "SpeedTreeCustomShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off
			AlphaToMask False

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma multi_compile __ LOD_FADE_PERCENTAGE
				#pragma shader_feature __ GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_FACING_LEAF
				#pragma multi_compile_shadowcaster
				#define ENABLE_WIND
				#include "SpeedTreeVertex.cginc"
				#include "UnityCG.cginc"

				uniform sampler2D _MainTex;
				uniform half4 _Color;
				
				#if defined(GEOM_TYPE_FROND) || defined(GEOM_TYPE_LEAF) || defined(GEOM_TYPE_FACING_LEAF)
					#define ENABLE_ALPHATEST
					uniform half _Cutoff;
				#endif

				struct v2f 
				{
					V2F_SHADOW_CASTER;
					#ifdef ENABLE_ALPHATEST
						half2 uv : TEXCOORD1;
					#endif
				};

				v2f vert(SpeedTreeVB v)
				{
					v2f o;
					#ifdef ENABLE_ALPHATEST
						o.uv = v.texcoord.xy;
					#endif
					OffsetSpeedTreeVertex(v, unity_LODFade.x);
					TRANSFER_SHADOW_CASTER(o)
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					#ifdef ENABLE_ALPHATEST
						clip(tex2D(_MainTex, i.uv).a * _Color.a - _Cutoff);
					#endif
					SHADOW_CASTER_FRAGMENT(i)
				}
			ENDCG
		}
	}

	// SM2.0 version: Cross-fading, Normal-mapping, Hue variation and Wind animation are turned off for less instructions
	SubShader
	{
		Tags
		{
			"Queue"="Geometry"
			"IgnoreProjector"="True"
			"RenderType"="Opaque"
			"DisableBatching"="LODFading"
		}
		LOD 400

		Cull Off
		AlphaToMask True

		CGPROGRAM
			#pragma surface surf Lambert vertex:vert nolightmap
			#pragma multi_compile __ LOD_FADE_PERCENTAGE
			#pragma shader_feature GEOM_TYPE_BRANCH GEOM_TYPE_BRANCH_DETAIL GEOM_TYPE_BRANCH_BLEND GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_FACING_LEAF GEOM_TYPE_MESH
			#include "SpeedTreeCommon.cginc"
		ENDCG

		Pass
		{
			Name "SpeedTreeCustomShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off
			AlphaToMask False

			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile __ LOD_FADE_PERCENTAGE
				#pragma shader_feature __ GEOM_TYPE_FROND GEOM_TYPE_LEAF GEOM_TYPE_FACING_LEAF
				#pragma multi_compile_shadowcaster
				#include "SpeedTreeVertex.cginc"
				#include "UnityCG.cginc"

				uniform sampler2D _MainTex;
				uniform half4 _Color;
				
				#if defined(GEOM_TYPE_FROND) || defined(GEOM_TYPE_LEAF) || defined(GEOM_TYPE_FACING_LEAF)
					#define ENABLE_ALPHATEST
					uniform half _Cutoff;
				#endif

				struct v2f 
				{
					V2F_SHADOW_CASTER;
					#ifdef ENABLE_ALPHATEST
						half2 uv : TEXCOORD1;
					#endif
				};

				v2f vert(SpeedTreeVB v)
				{
					v2f o;
					#ifdef ENABLE_ALPHATEST
						o.uv = v.texcoord.xy;
					#endif
					OffsetSpeedTreeVertex(v, unity_LODFade.x);
					TRANSFER_SHADOW_CASTER(o)
					return o;
				}

				float4 frag(v2f i) : SV_Target
				{
					#ifdef ENABLE_ALPHATEST
						clip(tex2D(_MainTex, i.uv).a * _Color.a - _Cutoff);
					#endif
					SHADOW_CASTER_FRAGMENT(i)
				}
			ENDCG
		}
	}

	FallBack "Diffuse"
	CustomEditor "SpeedTreeMaterialInspector"
}
