Shader "Custom/BeaconHalftone"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.1, 0.1, 0.1, 1)
        _DotColor ("Dot Color", Color) = (0.35, 0.02, 0.10, 1)
        _DotDensity ("Dots Per World Unit", Float) = 20
        _DotScale ("Dot Size", Range(0.01, 1)) = 0.5
        [Toggle(_DOT_SUPERSAMPLE)] _UseSupersampling ("Use Exact Supersampling instead of Texture (expensive)", Float) = 0
        _DotPatternTex ("Dot Pattern (prefiltered)", 2D) = "white" {}
        _DotPatternBakedRadius ("Baked Dot Radius (must match texture bake)", Range(0.01, 0.5)) = 0.35
        _PulseRimWidth ("Pulse Rim Width (world units)", Range(0.01, 5)) = 0.01
        _PulseRimBoost ("Pulse Rim Brightness", Range(0, 5)) = 1.0
        _GhostFade ("Ghost Fade", Range(0, 1)) = 1
        _FalloffExponent ("Falloff Exponent", Range(0.1, 4)) = 1
        _FauxIntensity ("Intensity multiplier for dot pattern", Range(1, 10)) = 5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma shader_feature_local _DOT_SUPERSAMPLE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE //might not need this
            #pragma multi_compile _ _SHADOWS_SOFT      

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 texcoord   : TEXCOORD;
                float4 tangentOS  : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_Position;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float2 texcoord    : TEXCOORD2;
                float4 tangentWS   : TEXCOORD3;
            };

            float4 _BaseColor;
            float4 _DotColor;
            float _DotDensity;
            float _DotScale;
            float _DotPatternBakedRadius;
            float3 _BeaconPositionWS;
            float _BeaconRange;
            float _BeaconPulseRadius;
            float _PulseRimWidth;
            float _PulseRimBoost;
            float _GhostFade;
            float _FalloffExponent;
            float _FauxIntensity;

            TEXTURE2D(_DotPatternTex);
            SAMPLER(sampler_DotPatternTex);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.texcoord = IN.texcoord;
                OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS), IN.tangentOS.w);
                return OUT;
            }

            // //brute force supersampling, probably not necessary
            // float DotCoverageSupersampled(float2 coordWS, float cellsPerUnit, float dotRadiusNorm, int N)
            // {
            //     float2 center = coordWS * cellsPerUnit;
            //     float2 dx = ddx(center); // must run outside any dynamic branch
            //     float2 dy = ddy(center);

            //     float coverage = 0.0;
            //     float invN = 1.0 / N;
            //     [unroll]
            //     for (int i = 0; i < N; i++)
            //     {
            //         [unroll]
            //         for (int j = 0; j < N; j++)
            //         {
            //             float2 jitter = (float2(i, j) + 0.5) * invN - 0.5;
            //             float2 samplePos = center + jitter.x * dx + jitter.y * dy;
            //             float2 cellUV = frac(samplePos) - 0.5;
            //             coverage += step(length(cellUV), dotRadiusNorm);
            //         }
            //     }
            //     return coverage * invN * invN;
            // }
            
            // // aa from texture
            // float DotCoveragePrefiltered(float2 coordWS, float cellsPerUnit, float dotRadiusNorm)
            // {
            //     float2 uv = coordWS * cellsPerUnit;
            //     float2 dx = ddx(uv);
            //     float2 dy = ddy(uv);
            //     float baked = SAMPLE_TEXTURE2D_GRAD(_DotPatternTex, sampler_DotPatternTex, uv, dx, dy).r;

            //     // fade out as dot size < texture dot size
            //     float areaRatio = saturate((dotRadiusNorm * dotRadiusNorm) / max(_DotPatternBakedRadius * _DotPatternBakedRadius, 1e-6));
            //     // areaRatio = 1.0f;
            //     return baked * areaRatio;
            // }

            // // old 2D approach
            // float DotCoverage(float2 posWS, float cellsPerUnit, float dotRadiusNorm)
            // {
            //     float2 cellCoord = posWS * cellsPerUnit;
            //     float2 w = fwidth(cellCoord);
            //     float blend = saturate(max(w.x, w.y));

            //     #if defined(_DOT_SUPERSAMPLE)
            //         float farCoverage = DotCoverageSupersampled(posWS, cellsPerUnit, dotRadiusNorm, 4);
            //     #else
            //         float farCoverage = DotCoveragePrefiltered(posWS, cellsPerUnit, dotRadiusNorm);
            //     #endif

            //         float2 cellUV = frac(cellCoord) - 0.5;
            //         float dist = length(cellUV);
            //         float aa = length(w) * 0.5 + 1e-5;
            //         float nearCoverage = 1.0 - smoothstep(dotRadiusNorm - aa, dotRadiusNorm + aa, dist);

            //         return lerp(nearCoverage, farCoverage, blend);
            // }


            float DotCoverage3D(float3 posWS, float cellsPerUnit, float dotRadiusNorm)
            {
                float3 cellCoord = posWS * cellsPerUnit; //scale worldspace coord to desired dot density
                float3 cellUV = frac(cellCoord) - 0.5; //split worldspace into grid, offet 0.5 to center 0,0 in middle of a cell
                float dist = length(cellUV);   // 3D distance to the nearest lattice point

                float3 w = fwidth(cellCoord);
                float aa = length(w) * 0.5 + 1e-5; //antialias dot edges
                float nearCoverage = 1.0 - smoothstep(dotRadiusNorm - aa, dotRadiusNorm + aa, dist);

                float blend = saturate(max(max(w.x, w.y), w.z));

            #if defined(_DOT_SUPERSAMPLE)
                float farCoverage = DotCoverageSupersampled3D(posWS, cellsPerUnit, dotRadiusNorm, 4);
            #else
                // approximate area coverage of dot to volume coverage of sphere. its called delesse principle or something
                float farCoverage = saturate((4.0 / 3.0) * PI * dotRadiusNorm * dotRadiusNorm * dotRadiusNorm);
            #endif

                return lerp(nearCoverage, farCoverage, blend);
            }

            float DotCoverageSupersampled3D(float3 posWS, float cellsPerUnit, float dotRadiusNorm, int N)
            {
                float3 center = posWS * cellsPerUnit;
                float3 dx = ddx(center);
                float3 dy = ddy(center);

                float coverage = 0.0;
                float invN = 1.0 / N;
                [unroll]
                for (int i = 0; i < N; i++)
                {
                    [unroll]
                    for (int j = 0; j < N; j++)
                    {
                        float2 jitter = (float2(i, j) + 0.5) * invN - 0.5;
                        float3 samplePos = center + jitter.x * dx + jitter.y * dy;
                        float3 cellUV = frac(samplePos) - 0.5;
                        coverage += step(length(cellUV), dotRadiusNorm);
                    }
                }
                return coverage * invN * invN;
            }


             float4 frag(Varyings IN) : SV_Target
            {
                // float3 N = normalize(IN.normalWS);
                // float3 T = normalize(IN.tangentWS.xyz);
                // T = normalize(T - N * dot(N, T));
                // float3 B = cross(N, T) * IN.tangentWS.w;
                // float3x3 TBN = float3x3(T, B, N);

                uint meshRenderingLayers = GetMeshRenderingLayer();
                float3 accumulatedLight = 0;
                float distanceFromLight = 0;

                #if defined(_ADDITIONAL_LIGHTS)
                InputData inputData = (InputData)0;
                inputData.positionWS = IN.positionWS;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);

                uint pixelLightCount = GetAdditionalLightsCount();

                half4 shadowMask = half4(1, 1, 1, 1); //no shadowmask
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);

                    #ifdef _LIGHT_LAYERS
                    if (IsMatchingLightLayer(light.layerMask, 1<<1)) //meshRenderingLayers)) //1<<1 corresponds to first user defined layer, here its the beacon one set in editor
                    #endif
                    {
                        float NdotL = saturate(dot(IN.normalWS, light.direction));
                        accumulatedLight += _FauxIntensity * light.shadowAttenuation * NdotL; //light color taken out since intensity of beacon set very low to avoid rendering normal lighting on the terrain
                        // // hack to reconstruct light worldposition, not needed if its declared as uniform
                        // float3 lightPositionWS = inputData.positionWS + (light.direction * rsqrt(light.distanceAttenuation)); //lightdir * magnitude of direction from point to light = full light ws vec
                        // distanceFromLight += length(IN.positionWS - lightPositionWS);
                    }
                LIGHT_LOOP_END
                #endif


                float distFromBeacon = distance(IN.positionWS, _BeaconPositionWS);
                float normalizedDist = saturate(distFromBeacon / max(_BeaconRange, 1e-4));
                float customFalloff = pow(1.0 - normalizedDist, _FalloffExponent); //adjustable falloff since 1/r^2 fades too harshly
                float luminance = dot(accumulatedLight, float3(0.2126, 0.7152, 0.0722)) * customFalloff; //honestly probably dont need the dot here since we're not working with light in the traditional sense

                float revealed = 1.0 - smoothstep(_BeaconPulseRadius - _PulseRimWidth, _BeaconPulseRadius, distFromBeacon); //check whether within current pulse radius
                float rim = exp(-abs(distFromBeacon - _BeaconPulseRadius) / max(_PulseRimWidth, 1e-4)) * _PulseRimBoost; //"_BeaconPositionWS""_BeaconRange""_BeaconPulseRadius" all set by beaconcontroller.cs

                luminance *= revealed; // nothing beyond the wavefront lights up yet, dot size, fade-to-black, everything downstream inherits this

                // //old 2d approach
                // float3 blendWeights = abs(IN.normalWS);
                // float3 normWeights = blendWeights / max(dot(blendWeights, 1.0), 1e-5);

                // float dotRadius = _DotScale * 0.5 * saturate(luminance);

                // float covYZ = DotCoverage(IN.positionWS.yz, _DotDensity, dotRadius);
                // float covXZ = DotCoverage(IN.positionWS.xz, _DotDensity, dotRadius);
                // float covXY = DotCoverage(IN.positionWS.xy, _DotDensity, dotRadius);
                // float coverage = dot(float3(covYZ, covXZ, covXY), normWeights);
                // //end 2d

                float dotRadius = _DotScale * 0.5 * saturate(luminance);
                float coverage = DotCoverage3D(IN.positionWS, _DotDensity, dotRadius);

                float4 color = lerp(float4(0, 0, 0.545, 1), float4(0.35, 0.02, 0.10, 1), normalizedDist);//saturate(1 / max(distFromBeacon, 1e-5)));
                float4 col = lerp(_BaseColor, color, coverage);
                float lightFalloff = saturate(luminance);
               
                col.rgb *= lightFalloff; // fades the whole pixel to black as light dies off
                col.rgb = lerp(col.rgb, color.rgb, saturate(rim)); // blend toward the hue instead of adding raw white on top
                col.rgb *= _GhostFade;          // per-instance, set via MaterialPropertyBlock on ghost clones only

                return col;
            }

            ENDHLSL

           
            //     // // //---start weird square wave thing
            //     // // float frequency = _DotDensity;
            //     // // float3 sawtooth = frac(IN.positionWS * frequency);
            //     // // float3 trianglew = abs(2.0 * sawtooth - 1.0);
            //     // // //float dp = length(vec2(dFdx(V), dFdy(V)));
            //     // // float3 dp = fwidth(IN.positionWS);
            //     // // float3 edge = dp * frequency * 2.0;
            //     // // float3 square = smoothstep(0.5 - edge, 0.5 + edge, trianglew);


            //     // // float distxz = length(square.xz);
            //     // // float distxy = length(square.xy);
            //     // // float distyz = length(square.yz);
            //     // // float dotRadius = _DotScale * 0.5 * saturate(luminance)*2;
            //     // // float dotMaskxz = step(distxz, dotRadius); //dotscale*.5 tunes radius of dot
            //     // // float dotMaskxy = step(distxy, dotRadius); //light cell(apply dot) if luminance/2 is > frag distance 
            //     // // float dotMaskyz = step(distyz, dotRadius);
            //     // // float dotMask = dot(float3(dotMaskyz, dotMaskxz, dotMaskxy), blendWeights); //yz~x, xz~y, yz~x
            //     // // dotMask = step(0.5, dotMask);//hack to get rid of undesirable patterns, could also just pick dominate axis from fragment normal
            //     // // float4 color = lerp(float4(0, 0, 0.545, 1), float4(0.35, 0.02, 0.10, 1), saturate(1/distanceFromLight));
            //     // // float4 col = lerp(_BaseColor, color, dotMask);
            //     // // return col;
            //     // // //--end square wave   
        }
         Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                #if _MAIN_LIGHT_SHADOWS_CASCADE || _ADDITIONAL_LIGHT_SHADOWS
                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightShadowParams.xyz));
                #else
                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                #endif
                return positionCS;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                return 0; // Shadowmap only cares about the depth buffer
            }
            ENDHLSL
        }
    }
    Fallback "Universal Render Pipeline/Lit"
}
