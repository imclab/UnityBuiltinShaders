#ifndef UNITY_STANDARD_CONFIG_INCLUDED
#define UNITY_STANDARD_CONFIG_INCLUDED

// Define Specular cubemap constants
#define UNITY_SPECCUBE_LOD_EXPONENT (1.5)
#define UNITY_SPECCUBE_LOD_STEPS (7) // TODO: proper fix for different cubemap resolution needed. My assumptions were actually wrong!

#define UNITY_GLOSS_MATCHES_MARMOSET_TOOLBAG2
//#define UNITY_BRDF_GGX

// Orthnormalize Tangent Space basis per-pixel
// Necessary to support high-quality normal-maps. Compatible with Maya and Marmoset.
// However xNormal expects oldschool non-orthnormalized basis - essentially preventing good looking normal-maps :(
// Due to the fact that xNormal is probably _the most used tool to bake out normal-maps today_ we have to stick to old ways for now.
// 
// Disabled by default, until xNormal has an option to bake proper normal-maps.
//#define UNITY_TANGENT_ORTHONORMALIZE

#endif // UNITY_STANDARD_CONFIG_INCLUDED
