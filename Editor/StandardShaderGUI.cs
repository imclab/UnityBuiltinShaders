using UnityEngine;
using Object = UnityEngine.Object;
using System;


namespace UnityEditor
{

internal class StandardShaderGUI : ShaderGUI
{
    private enum WorkflowMode
    {
        Specular,
        Metallic,
        Dielectric
    }

    public enum BlendMode
    {
        Opaque,
        Cutout,
        Transparent
    }

	private static class Styles
	{
		public static GUIStyle optionsButton = "PaneOptions";
		public static GUIContent uvSetLabel = new GUIContent("UV Set");
		public static GUIContent[] uvSetOptions = new GUIContent[] { new GUIContent("UV channel 0"), new GUIContent("UV channel 1") };

		public static string emptyTootip = "";
		public static string albedoTooltip = "Albedo (RGB) and Transparency (A)";
		public static string specularMapTooltip = "Specular (RGB) and Smoothness (A)";
		public static string metallicMapTooltip = "Metallic (R) and Smoothness (A)";
		public static string normalMapTooltip = "Normal Map";
		public static string heightMapTooltip = "Height Map (G)";
		public static string occlusionTooltip = "Occlusion (G)";
		public static string emissionTooltip = "Emission (RGB)";
		public static string detailMaskTooltip = "Mask for Secondary Maps (A)";
		public static string detailAlbedoTooltip = "Albedo (RGB) multiplied by 2";
		public static string detailNormalMapTooltip = "Normal Map";

		public static string whiteSpaceString = " ";
		public static string primaryMapsText = "Main Maps";
		public static string secondaryMapsText = "Secondary Maps";
		public static string renderingMode = "Rendering Mode";
		public static GUIContent emissiveWarning = new GUIContent ("Emissive value is animated but the material has not been configured to support emissive. Please make sure the material itself has some amount of emissive.");
		public static readonly string[] blendNames = Enum.GetNames (typeof (BlendMode));
	}

	MaterialProperty blendMode = null;
	MaterialProperty albedoMap = null;
	MaterialProperty albedoColor = null;
	MaterialProperty alphaCutoff = null;
	MaterialProperty specularMap = null;
	MaterialProperty specularColor = null;
	MaterialProperty metallicMap = null;
	MaterialProperty metallic = null;
	MaterialProperty smoothness = null;
	MaterialProperty bumpScale = null;
	MaterialProperty bumpMap = null;
	MaterialProperty occlusionStrength = null;
	MaterialProperty occlusionMap = null;
	MaterialProperty heigtMapScale = null;
	MaterialProperty heightMap = null;
	MaterialProperty emissionScale = null;
	MaterialProperty emissionColor = null;
	MaterialProperty emissionColorWithMap = null;
	MaterialProperty emissionColorForRendering = null;
	MaterialProperty emissionMap = null;
	MaterialProperty detailMask = null;
	MaterialProperty detailAlbedoMap = null;
	MaterialProperty detailNormalMapScale = null;
	MaterialProperty detailNormalMap = null;
	MaterialProperty uvSetSecondary = null;
	MaterialProperty lightmapping = null;

	MaterialEditor m_MaterialEditor;
	WorkflowMode m_WorkflowMode = WorkflowMode.Specular;

	bool m_FirstTimeApply = true;
	const int kSecondLevelIndentOffset = 2;
	const float kVerticalSpacing = 2f;

	public void FindProperties (MaterialProperty[] props)
	{
		blendMode = FindProperty ("_Mode", props);
		albedoMap = FindProperty ("_MainTex", props);
		albedoColor = FindProperty ("_Color", props);
		alphaCutoff = FindProperty ("_AlphaTestRef", props);
		specularMap = FindProperty ("_SpecGlossMap", props, false);
		specularColor = FindProperty ("_SpecColor", props, false);
		metallicMap = FindProperty ("_MetallicGlossMap", props, false);
		metallic = FindProperty ("_Metallic", props, false);
		if (specularMap != null && specularColor != null)
			m_WorkflowMode = WorkflowMode.Specular;
		else if (metallicMap != null && metallic != null)
			m_WorkflowMode = WorkflowMode.Metallic;
		else
			m_WorkflowMode = WorkflowMode.Dielectric;
		smoothness = FindProperty ("_Glossiness", props);
		bumpScale = FindProperty ("_BumpScale", props);
		bumpMap = FindProperty ("_BumpMap", props);
		heigtMapScale = FindProperty ("_Parallax", props);
		heightMap = FindProperty("_ParallaxMap", props);
		occlusionStrength = FindProperty ("_OcclusionStrength", props);
		occlusionMap = FindProperty ("_OcclusionMap", props);
		emissionScale = FindProperty ("_EmissionScaleUI", props);
		emissionColor = FindProperty ("_EmissionColorUI", props);
		emissionColorWithMap = FindProperty ("_EmissionColorWithMapUI", props);
		emissionColorForRendering = FindProperty ("_EmissionColor", props);
		emissionMap = FindProperty ("_EmissionMap", props);
		detailMask = FindProperty ("_DetailMask", props);
		detailAlbedoMap = FindProperty ("_DetailAlbedoMap", props);
		detailNormalMapScale = FindProperty ("_DetailNormalMapScale", props);
		detailNormalMap = FindProperty ("_DetailNormalMap", props);
		uvSetSecondary = FindProperty ("_UVSec", props);
		lightmapping = FindProperty ("_Lightmapping", props);
	}

	public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] props)
	{
		FindProperties (props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
		m_MaterialEditor = materialEditor;
		Material material = materialEditor.target as Material;

		ShaderPropertiesGUI (material);

		// Make sure that needed keywords are set up if we're switching some existing
		// material to a standard shader.
		if (m_FirstTimeApply)
		{
			SetMaterialKeywords (material);
			m_FirstTimeApply = false;
		}
	}

	public void ShaderPropertiesGUI (Material material)
	{
		// Use default labelWidth
		EditorGUIUtility.labelWidth = 0f;

		// Detect any changes to the material
		EditorGUI.BeginChangeCheck();
		{
			BlendModePopup ();

			// Manually control layout for the rest of the properties (some have multiple controls on a single line)
			Rect r = EditorGUILayout.GetControlRect (true, 1);
			float startY = r.y;
			r.y += 5f;

			const float extraSpacing = 4f;

			r.y += HeaderSection (r, Styles.primaryMapsText, albedoMap) + extraSpacing;
			r.y += DoAlbedoArea (r, albedoMap, albedoColor, material) + extraSpacing;
			if (m_WorkflowMode == WorkflowMode.Specular)
				r.y += DoSpecularArea (r, specularMap, specularColor, smoothness) + extraSpacing;
			else if (m_WorkflowMode == WorkflowMode.Metallic)
				r.y += DoMetallicArea (r, metallicMap, metallic, smoothness) + extraSpacing;

			r.y += DoTextureAndFloatProperty (r, bumpMap, bumpScale, Styles.normalMapTooltip) + extraSpacing;

			r.y += DoTextureAndFloatProperty (r, heightMap, heigtMapScale, Styles.heightMapTooltip) + extraSpacing;
			r.y += DoTextureAndFloatProperty (r, occlusionMap, occlusionStrength, Styles.occlusionTooltip) + extraSpacing;
			r.y += DoEmissionArea (r, emissionMap, emissionColor, emissionColorWithMap, emissionScale, material) + extraSpacing;
			r.y += DoTextureAndFloatProperty (r, detailMask, null, Styles.detailMaskTooltip) + extraSpacing;
			r.y += SettingsSection (r, albedoMap);

			r.y += 12f;

			r.y += HeaderSection (r, Styles.secondaryMapsText, albedoMap) + extraSpacing;
			r.y += DoDetailAlbedoArea (r, detailAlbedoMap, material) + extraSpacing;
			r.y += DoTextureAndFloatProperty (r, detailNormalMap, detailNormalMapScale, Styles.detailNormalMapTooltip) + extraSpacing;
			r.y += SettingsSection (r, detailAlbedoMap, uvSetSecondary);

			// Reserve the area we used above (in the layout system)
			EditorGUILayout.GetControlRect(true, r.y - startY, EditorStyles.layerMaskField);
		}
		if (EditorGUI.EndChangeCheck())
		{
			foreach (var obj in blendMode.targets)
				MaterialChanged ((Material)obj);
		}
	}

    public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch (blendMode)
        {
            case BlendMode.Opaque:
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.renderQueue = -1;
                break;
            case BlendMode.Cutout:
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.EnableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.renderQueue = 2450;
                break;
            case BlendMode.Transparent:
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.DisableKeyword("_ALPHATEST_ON");
                material.EnableKeyword("_ALPHABLEND_ON");
                material.renderQueue = 3000;
                break;
        }
    }

	void BlendModePopup()
	{
		EditorGUI.showMixedValue = blendMode.hasMixedValue;
		var mode = (BlendMode)blendMode.floatValue;

		EditorGUI.BeginChangeCheck();
		mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
		if (EditorGUI.EndChangeCheck())
		{
			m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
			blendMode.floatValue = (float)mode;
		}

		EditorGUI.showMixedValue = false;
	}

	// Returns height used
	float HeaderSection (Rect r, string header, MaterialProperty textureProperty)
	{
		float startY = r.y;
		r.height = EditorGUIUtility.singleLineHeight;
		GUI.Label (r, header, EditorStyles.boldLabel);
		r.y += r.height + 3f;
		return r.y - startY;
	}

	// Returns height used
	float SettingsSection (Rect r, MaterialProperty textureProperty, MaterialProperty uvSetProperty)
	{
		float startY = r.y;
		r.y += m_MaterialEditor.TextureScaleOffsetProperty (r, textureProperty, false);
		if (uvSetProperty != null)
		{
			r.height = EditorGUIUtility.singleLineHeight;
			m_MaterialEditor.ShaderProperty (r, uvSetProperty, Styles.uvSetLabel.text);
			r.y += r.height;
		}
		return r.y - startY;
	}
	float SettingsSection (Rect r, MaterialProperty textureProperty)
	{
		return SettingsSection (r, textureProperty, null);
	}

	// Returns height used
	float TextureProperty (MaterialProperty textureProp, Rect r, string tooltip)
	{
		r.height = EditorGUIUtility.singleLineHeight;
		float actualHeight = 0;
		m_MaterialEditor.TexturePropertyMiniThumbnail (r, textureProp, textureProp.displayName, tooltip, out actualHeight);
		return actualHeight;
	}

	static void WarningBox (ref Rect r, GUIContent content)
	{
		r.y = r.yMax + 2;

		float height = EditorStyles.helpBox.CalcHeight (content, r.width);
		r.height = height;
		EditorGUI.HelpBox (r, content.text, MessageType.Warning);

		r.y += 2;
	}

	// Returns rect after EditorGUIUtility.labelWidth
	Rect GetRectAfterLabelWidth (Rect r)
	{
		return new Rect(r.x + EditorGUIUtility.labelWidth, r.y, r.width - EditorGUIUtility.labelWidth, EditorGUIUtility.singleLineHeight);
	}

	// Returns fixed rect based on EditorGUIUtility.fieldWidth
	Rect GetColorPropertyCustomRect (Rect r)
	{
		return new Rect(r.xMax - EditorGUIUtility.fieldWidth, r.y, EditorGUIUtility.fieldWidth, EditorGUIUtility.singleLineHeight);
	}

	// Returns height used + spacing
	float DoAlbedoArea (Rect r, MaterialProperty textureProp, MaterialProperty colorProp, Material material)
	{
		float startY = r.y;

		Rect colorRect = GetColorPropertyCustomRect (r);
		Rect textureRect = new Rect (r.x, r.y, r.width - colorRect.width, r.height);

		// Texture
		r.height = TextureProperty (textureProp, textureRect, Styles.albedoTooltip);

		// Color
		m_MaterialEditor.ShaderProperty (colorRect, colorProp, string.Empty);

		// Alpha cutoff
        if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout))
		{
			r.y += r.height + 2;
			EditorGUI.indentLevel += kSecondLevelIndentOffset;
			m_MaterialEditor.ShaderProperty (r, alphaCutoff, alphaCutoff.displayName);
			EditorGUI.indentLevel -= kSecondLevelIndentOffset;
		}

		return r.yMax - startY + kVerticalSpacing;
	}

	// Returns height used + spacing
	float DoSpecularArea(Rect r, MaterialProperty textureProp, MaterialProperty colorProp, MaterialProperty glossiness)
	{
		float startY = r.y;

		//string tooltip = textureProp.textureValue == null ? string.Empty : ;
		r.height = TextureProperty(textureProp, r, Styles.specularMapTooltip);

		// If no texture then show color and glosiness slider
		if (textureProp.textureValue == null)
		{
			// Color
			m_MaterialEditor.ShaderProperty (GetColorPropertyCustomRect (r), colorProp, string.Empty);

			r.y += r.height + 2;

			// Glossiness
			EditorGUI.indentLevel += kSecondLevelIndentOffset;
			m_MaterialEditor.ShaderProperty (r, glossiness, glossiness.displayName);
			EditorGUI.indentLevel -= kSecondLevelIndentOffset;
		}

		return r.yMax - startY + kVerticalSpacing;
	}

	// Returns height used + spacing
	float DoMetallicArea(Rect r, MaterialProperty textureProp, MaterialProperty metallic, MaterialProperty glossiness)
	{
		float startY = r.y;

		//string tooltip = textureProp.textureValue == null ? string.Empty : ;
		r.height = TextureProperty(textureProp, r, Styles.metallicMapTooltip);

		// If no texture then show metallic and glosiness sliders
		if (textureProp.textureValue == null)
		{
			// Metallic
			EditorGUI.indentLevel += kSecondLevelIndentOffset;
			m_MaterialEditor.ShaderProperty (r, metallic, metallic.displayName);

			r.y += r.height + 2;

			// Glossiness
			m_MaterialEditor.ShaderProperty (r, glossiness, glossiness.displayName);
			EditorGUI.indentLevel -= kSecondLevelIndentOffset;
		}

		return r.yMax - startY + kVerticalSpacing;
	}

	// Returns height used + spacing
	float DoEmissionArea (Rect r, MaterialProperty textureProp, MaterialProperty colorWithoutMapProp, MaterialProperty colorWithMapProp, MaterialProperty scaleProp, Material material)
	{
		float startY = r.y;
		Rect colorRect = GetColorPropertyCustomRect (r);
		r.width -= colorRect.width + 4;
		Rect textureRect = new Rect (r.x, r.y, r.width, r.height);

		// Texture
		r.height = TextureProperty (textureProp, textureRect, Styles.emissionTooltip);
		
		// Scalar
		DoInlineFloatProperty (r, scaleProp);

		// Color
		var colorProp = (emissionMap.textureValue != null) ? colorWithMapProp: colorWithoutMapProp;
		m_MaterialEditor.ShaderProperty (colorRect, colorProp, string.Empty);
		
		// Dynamic Lightmapping mode
		if (ShouldEmissionBeEnabled(EvalFinalEmissionColor ()) && lightmapping != null)
		{
			r.y += r.height + 2;

			EditorGUI.indentLevel += kSecondLevelIndentOffset;
			m_MaterialEditor.ShaderProperty (r, lightmapping, lightmapping.displayName);
			EditorGUI.indentLevel -= kSecondLevelIndentOffset;
		}

		if (!HasValidEmissiveKeyword (material))
		{
			r.width += colorRect.width + 4;
			WarningBox (ref r, Styles.emissiveWarning);
		}

		return r.yMax - startY + kVerticalSpacing;
	}

	// Returns height used + spacing
	float DoDetailAlbedoArea (Rect r, MaterialProperty textureProp, Material mat)
	{
		float startY = r.y;
		r.height = TextureProperty (textureProp, r, Styles.detailAlbedoTooltip);
		return r.yMax - startY + kVerticalSpacing;
	}

	// Returns height used
	float DoTextureAndFloatProperty (Rect r, MaterialProperty textureProp, MaterialProperty floatProp)
	{
		return DoTextureAndFloatProperty (r, textureProp, floatProp, Styles.emptyTootip);
	}

	// Returns height used + spacing
	float DoTextureAndFloatProperty (Rect r, MaterialProperty textureProp, MaterialProperty floatProp, string tooltip)
	{
		float startY = r.y;
		r.height = TextureProperty(textureProp, r, tooltip);
		if (textureProp.textureValue != null)
			DoInlineFloatProperty (r, floatProp);

		return r.yMax - startY + kVerticalSpacing;
	}

	void DoInlineFloatProperty (Rect r, MaterialProperty floatProp)
	{
		if (floatProp == null)
			return;

		Rect floatPropRect = GetRectAfterLabelWidth (r);
		float oldLabelWidth = EditorGUIUtility.labelWidth;
		string labelString = string.Empty;
		if (floatProp.type == MaterialProperty.PropType.Float)
		{
			// To be able to have a draggable area in front of the float field we need to ensure
			// the property has a label (here we use a whitespace) and adjust label width.
			// Float value dragging is implemented over the label area
			labelString = Styles.whiteSpaceString;
			EditorGUIUtility.labelWidth = floatPropRect.width - EditorGUIUtility.fieldWidth;
		}
		m_MaterialEditor.ShaderProperty (floatPropRect, floatProp, labelString);

		EditorGUIUtility.labelWidth = oldLabelWidth;
	}
	
	// Calculate final HDR _EmissionColor from _EmissionColorUI (LDR, gamma) & _EmissionScaleUI (linear)
	Color EvalFinalEmissionColor ()
	{
		var emission = (emissionMap.textureValue != null) ? emissionColorWithMap: emissionColor;
		return emission.colorValue * Mathf.LinearToGammaSpace (emissionScale.floatValue);
	}

	static bool ShouldEmissionBeEnabled (Color color)
	{
		return color.grayscale > (0.1f / 255.0f);
	}

	void SetMaterialKeywords (Material material)
	{
		// Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
		// (MaterialProperty value might come from renderer material property block)
		SetKeyword (material, "_NORMALMAP", material.GetTexture ("_BumpMap") || material.GetTexture ("_DetailNormalMap"));
		if (m_WorkflowMode == WorkflowMode.Specular)
			SetKeyword (material, "_SPECGLOSSMAP", material.GetTexture ("_SpecGlossMap"));
		else if (m_WorkflowMode == WorkflowMode.Metallic)
			SetKeyword (material, "_METALLICGLOSSMAP", material.GetTexture ("_MetallicGlossMap"));
		SetKeyword (material, "_PARALLAXMAP", material.GetTexture ("_ParallaxMap"));
		SetKeyword (material, "_DETAIL_MULX2", material.GetTexture ("_DetailAlbedoMap") || material.GetTexture ("_DetailNormalMap"));
		SetKeyword (material, "_EMISSION", ShouldEmissionBeEnabled (material.GetColor("_EmissionColor")));
	}

	bool HasValidEmissiveKeyword (Material material)
	{
		// Material animation might be out of sync with the material keyword.
		// So if the emission support is disabled on the material, but the property blocks have a value that requires it, then we need to show a warning.
		// (note: (Renderer MaterialPropertyBlock applies its values to emissionColorForRendering))
		bool hasEmissionKeyword = material.IsKeywordEnabled ("_EMISSION");
		if (!hasEmissionKeyword && ShouldEmissionBeEnabled (emissionColorForRendering.colorValue))
			return false;
		else
			return true;
	}

	void MaterialChanged (Material material)
	{
		// Clamp EmissionScale to always positive
		if (emissionScale.floatValue < 0.0f)
			emissionScale.floatValue = 0.0f;
		// Apply combined emission value
		Color emissionColorOut = EvalFinalEmissionColor ();
		emissionColorForRendering.colorValue = emissionColorOut;

        // Handle Blending modes
        SetupMaterialWithBlendMode(material, (BlendMode)blendMode.floatValue);

        SetMaterialKeywords (material);
	}

	static void SetKeyword(Material m, string keyword, bool state)
	{
		if (state)
			m.EnableKeyword (keyword);
		else
			m.DisableKeyword (keyword);
	}

	static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties)
	{
		return FindProperty (propertyName, properties, true);
	}

	static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties, bool propertyIsMandatory)
	{
		for (var i = 0; i < properties.Length; i++)
		{
			if (properties[i] != null && properties[i].name == propertyName)
			{
				var prop = properties[i];
				properties[i] = null;
				return prop;
			}
		}

		// We assume all required properties can be found, otherwise something is broken
		if (propertyIsMandatory)
			throw new ArgumentException("Could not find MaterialProperty: '" + propertyName + "', Num properties: " + properties.Length);
		return null;
	}
}

} // namespace UnityEditor
