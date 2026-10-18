Shader "Toon/SoftSurface"
{
    Properties
    {
        _Color ("Color", Color) = (0.4,0.4,0.4,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Emission ("Emission", Range (0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "UniversalForward"
            Tags {"Lightmode"= "UniversalForward"}

        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        struct Attributes
        {
            float4 positionOS   : POSITION;
            float3 normalOS     : NORMAL;
            float2 uv_MainTex   : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS  : SV_POSITION;
            float2 uv           : TEXCOORD0;
            float3 normalWS     : TEXCOORD1;
        };

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _Emission;
        CBUFFER_END

        Varyings vert(Attributes IN)
        {
            Varyings o;
                o.positionHCS = TransformObjectToHClip(IN.positionOS);
                o.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                o.uv = IN.uv_MainTex;
            return o;
        }

        half4 frag(Varyings IN) : SV_Target
        {
            half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            half4 c = texColor * _Color;

            Light mainLight = GetMainLight();
            half NdotL = saturate(dot(IN.normalWS, mainLight.direction));
            half3 ambient = SampleSH(IN.normalWS);
            half3 lighting = (mainLight.color * NdotL) + ambient;

            half3 albedo = c.rgb;
            half3 emission = texColor.rgb * _Emission;
            half3 finalColor = (albedo * lighting) + emission;
            return half4(finalColor, c.a);
        }
        ENDHLSL
    }
    }
    FallBack "Universal Render Pipeline/Lit"
}
//Old version
// Shader "Toon/SoftSurface"
// {
//     Properties
//     {
//         _Color ("Color", Color) = (0.4,0.4,0.4,1)
//         _MainTex ("Albedo (RGB)", 2D) = "white" {}
//         _Emission ("Emission", Range (0,1)) = 0.5
//     }
//     SubShader
//     {
//         Tags { "RenderType"="Opaque" }
//         LOD 100

//         CGPROGRAM
//         #pragma surface surf Lambert
//         #pragma target 3.0

//         struct Input
//         {
//             float2 uv_MainTex;
//         };

//         sampler2D _MainTex;
//         fixed4 _Color;
//         fixed _Emission;

//         void surf (Input IN, inout SurfaceOutput o)
//         {
//             fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
//             o.Albedo = c.rgb;
//             // Re-use the same texture on emission to give the soft look
//             o.Emission = tex2D (_MainTex, IN.uv_MainTex) * _Emission;
//             o.Alpha = c.a;
//         }
//         ENDCG
//     }
//     FallBack "Diffuse"
// }
