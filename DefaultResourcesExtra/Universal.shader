Shader "Standard"
{
	Properties
	{
		[LM_Albedo] [LM_Transparency] _Color("Color", Color) = (1,1,1)	
		[LM_MasterTilingOffset] [LM_Albedo] _MainTex("Diffuse", 2D) = "white" {}
		
		[LM_TransparencyCutOff] _AlphaTestRef("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		[LM_Glossiness] _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.0
		[LM_Specular] _SpecularColor("Specular", Color) = (0.2,0.2,0.2)	
		[LM_Specular] [LM_Glossiness] _SpecGlossMap("Specular", 2D) = "white" {}

		 _BumpScale("Scale", Float) = 1.0
		[LM_NormalMap] _BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
		_ParallaxMap ("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_Occlusion("Occlusion", 2D) = "white" {}

		[HideInInspector] _EmissionScaleUI("Scale", Float) = 1.0
		[HideInInspector] _EmissionColorUI("Color", Color) = (0,0,0)
		[HideInInspector] _EmissionColorWithMapUI("Color", Color) = (1,1,1)
		[LM_Emission] _EmissionColor("Color", Color) = (0,0,0)
		[LM_Emission] _EmissionMap("Emission", 2D) = "white" {}
		[KeywordEnum(Static Lightmaps, Dynamic Lightmaps)]  _Lightmapping ("Lightmapper", Int) = 1
		
		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Diffuse x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

		[KeywordEnum(UV1, UV2)] _UVSec ("UV Set for secondary textures", Float) = 0

		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}

	CGINCLUDE
		//@TODO: should this be pulled into a shader_feature, to be able to turn it off?
		#define _GLOSSYENV 1
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		LOD 300
	

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM
			#pragma target 3.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			
			#if !defined(SHADER_API_MOBILE)
			#define UNITY_BRDF_PBS BRDF1_Unity_PBS
			#else
			#define UNITY_BRDF_PBS BRDF2_Unity_PBS
			#endif
			//#define UNITY_BRDF_WITH_ASPERITY
			// -------------------------------------

					
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma shader_feature _EMISSIONMAP
			//ALWAYS ON shader_feature _GLOSSYENV
			#pragma shader_feature _SPECGLOSSMAP 
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP
			
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
				
			#pragma vertex vertForwardBase
			#pragma fragment fragForwardBase

			#include "UnityUniversalCore.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0
			// GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles

			#if !defined(SHADER_API_MOBILE)
			#define UNITY_BRDF_PBS BRDF1_Unity_PBS
			#else
			#define UNITY_BRDF_PBS BRDF2_Unity_PBS
			#endif
			//#define UNITY_BRDF_WITH_ASPERITY
			// -------------------------------------

			
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			
			#pragma vertex vertForwardAdd
			#pragma fragment fragForwardAdd

			#include "UnityUniversalCore.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 3.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			
			#if !defined(SHADER_API_MOBILE)
			#define UNITY_BRDF_PBS BRDF1_Unity_PBS
			#else
			#define UNITY_BRDF_PBS BRDF2_Unity_PBS
			#endif
			//#define UNITY_BRDF_WITH_ASPERITY
			// -------------------------------------


			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "UnityUniversalShadow.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Deferred pass
		Pass
		{
			Name "DEFERRED"
			Tags { "LightMode" = "Deferred" }

			CGPROGRAM
			#pragma target 3.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers nomrt gles
			
			#if !defined(SHADER_API_MOBILE)
			#define UNITY_BRDF_PBS BRDF1_Unity_PBS
			#else
			#define UNITY_BRDF_PBS BRDF2_Unity_PBS
			#endif
			//#define UNITY_BRDF_WITH_ASPERITY
			// -------------------------------------

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma shader_feature _EMISSIONMAP
			//ALWAYS ON shader_feature _GLOSSYENV
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			#pragma multi_compile ___ UNITY_HDR_ON
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
			#pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
			
			#pragma vertex vertDeferred
			#pragma fragment fragDeferred

			#include "UnityUniversalCore.cginc"

			ENDCG
		}
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		LOD 100

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM
			#pragma target 2.0
			#define SHADER_API_SM2 1
			#define UNITY_BRDF_PBS BRDF3_Unity_PBS

			
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma shader_feature _EMISSIONMAP 
			// ALWAYS ON shader_feature _GLOSSYENV
			#pragma shader_feature _SPECGLOSSMAP 
			#pragma shader_feature ___ _DETAIL_MULX2
			// NOT SUPPORTED in SM2.0 shader_feature _PARALLAXMAP
			#pragma skip_variants SHADOWS_SOFT
			#pragma skip_variants DYNAMICLIGHTMAP_ON
			
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
	
			#pragma vertex vertForwardBase
			#pragma fragment fragForwardBase

			#include "UnityUniversalCore.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual
			
			CGPROGRAM
			#pragma target 2.0
			#define SHADER_API_SM2 1
			#define UNITY_BRDF_PBS BRDF3_Unity_PBS
		
		
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			// NOT SUPPORTED in SM2.0 shader_feature _PARALLAXMAP
			#pragma skip_variants SHADOWS_SOFT
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			
			#pragma vertex vertForwardAdd
			#pragma fragment fragForwardAdd

			#include "UnityUniversalCore.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 2.0
			#define SHADER_API_SM2 1
			#define UNITY_BRDF_PBS BRDF3_Unity_PBS


			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON
			#pragma skip_variants SHADOWS_SOFT
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "UnityUniversalShadow.cginc"

			ENDCG
		}
	}

	FallBack "VertexLit"
	CustomEditor "UniversalShaderEditor"
}
