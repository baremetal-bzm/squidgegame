//see comments in BeaconHalftone.shader as the bulk is the same
Shader "Custom/BeaconHalftoneOverlay"
{
    Properties
    {
        _DotDensity ("Dots Per World Unit", Float) = 20
        _DotScale ("Dot Size", Range(0.01, 1)) = 0.5
        _FalloffExponent ("Falloff Exponent", Range(0.1, 4)) = 1
        _PulseRimWidth ("Pulse Rim Width", Range(0.01, 5)) = 0.5
        _PulseRimBoost ("Pulse Rim Brightness", Range(0, 5)) = 2.0
        _FauxIntensity ("Intensity multiplier for dot pattern", Range(1, 10)) = 5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend One One
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_Position;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
            };

            float _DotDensity, _DotScale, _FalloffExponent, _PulseRimWidth, _PulseRimBoost, _FauxIntensity;
            float3 _BeaconPositionWS;
            float _BeaconRange, _BeaconPulseRadius;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            float DotCoverage3D(float3 posWS, float3 normalWS, float cellsPerUnit, float dotRadiusNorm)
            {
                float3 cellCoord = posWS * cellsPerUnit;
                float3 cellUV = frac(cellCoord) - 0.5;
                // float dist = length(cellUV);

                //weight by normal xyz components to collapse to unit circle if a horizontal plane, enlarges dots for xyz nonzero normals tho
                float3 normalWeight = 1.0 - pow(abs(normalWS),2); //consider squaring the abs() term to counteract enlarging effect
                float dist = length(cellUV * normalWeight);

                // float3 projection = cellUV - (dot(cellUV, normalWS)*normalWS);
                // float dist = length(projection);

                float3 w = fwidth(cellCoord);
                float aa = length(w) * 0.5 + 1e-5;
                float nearCoverage = 1.0 - smoothstep(dotRadiusNorm - aa, dotRadiusNorm + aa, dist);
                float blend = saturate(max(max(w.x, w.y), w.z));
                float farCoverage = saturate((4.0 / 3.0) * PI * dotRadiusNorm * dotRadiusNorm * dotRadiusNorm);
                return lerp(nearCoverage, farCoverage, blend);
            }

            float4 frag(Varyings IN) : SV_Target
            {
                uint meshRenderingLayers = GetMeshRenderingLayer();
                float3 accumulatedLight = 0;

                #if defined(_ADDITIONAL_LIGHTS)
                InputData inputData = (InputData)0;
                inputData.positionWS = IN.positionWS;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);

                uint pixelLightCount = GetAdditionalLightsCount();
                half4 shadowMask = half4(1, 1, 1, 1);

                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);

                    #ifdef _LIGHT_LAYERS
                    // if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                    if (IsMatchingLightLayer(light.layerMask, 1<<1)) //beacon layer mask
                    #endif
                    {
                        float NdotL = saturate(dot(IN.normalWS, light.direction));
                        accumulatedLight += _FauxIntensity * light.shadowAttenuation * NdotL;
                    }
                LIGHT_LOOP_END
                #endif

                float distFromBeacon = distance(IN.positionWS, _BeaconPositionWS);
                float normalizedDist = saturate(distFromBeacon / max(_BeaconRange, 1e-4));
                float customFalloff = pow(1.0 - normalizedDist, _FalloffExponent);

                float revealed = 1.0 - smoothstep(_BeaconPulseRadius - _PulseRimWidth, _BeaconPulseRadius, distFromBeacon);
                float rim = exp(-abs(distFromBeacon - _BeaconPulseRadius) / max(_PulseRimWidth, 1e-4)) * _PulseRimBoost;

                // float realLight = dot(accumulatedLight, float3(0.2126, 0.7152, 0.0722));
                float realLight = accumulatedLight;
                float luminance = realLight * customFalloff * revealed;

                float dotRadius = _DotScale * 0.5 * saturate(luminance);
                float coverage = DotCoverage3D(IN.positionWS, IN.normalWS, _DotDensity, dotRadius);

                float4 color = lerp(float4(0, 0, 0.545, 1), float4(0.35, 0.02, 0.10, 1), normalizedDist);//saturate(1 / max(distFromBeacon, 1e-5)));
                float4 col = lerp(float4(0,0,0,0), color, coverage);
                float lightFalloff = saturate(luminance);
               
                col.rgb *= lightFalloff; 
                col.rgb = lerp(col.rgb, color.rgb, saturate(rim)); 
                
                return float4(col.xyz,1);
            }            
            ENDHLSL
        }
        //  Pass
        // {
        //     Name "ShadowCaster"
        //     Tags { "LightMode" = "ShadowCaster" }

        //     ZWrite On
        //     ZTest LEqual
        //     ColorMask 0

        //     HLSLPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag

        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        //     struct Attributes
        //     {
        //         float4 positionOS   : POSITION;
        //         float3 normalOS     : NORMAL;
        //     };

        //     struct Varyings
        //     {
        //         float4 positionCS   : SV_POSITION;
        //     };

        //     // This helper function handles URP shadow biases automatically
        //     float4 GetShadowPositionHClip(Attributes input)
        //     {
        //         float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
        //         float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
        //         #if _MAIN_LIGHT_SHADOWS_CASCADE || _ADDITIONAL_LIGHT_SHADOWS
        //             float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightShadowParams.xyz));
        //         #else
        //             float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
        //         #endif
        //         return positionCS;
        //     }

        //     Varyings vert(Attributes input)
        //     {
        //         Varyings output;
        //         output.positionCS = GetShadowPositionHClip(input);
        //         return output;
        //     }

        //     float4 frag(Varyings input) : SV_Target
        //     {
        //         return 0; // Shadowmap only cares about the depth buffer
        //     }
        //     ENDHLSL
        // }
    
    }
}