Shader "UnderwaterScreenEffect"
{
    // commented out stuff was for screenspace bubble effect i abandoned because it breaks the illusion immediately upon camera movement in xz plane
    // assign shader material to "Full Screen Pass Renderer Feature" on teh URP Renderer asset. See UnderwaterEffectController.cs for the script that sets _BubbleUpDir and _EffectTime.

    Properties
    {
        _TintColor      ("Underwater Tint", Color) = (0.05, 0.35, 0.45, 1)
        _FogDensity     ("Fog Density", Range(0,1)) = 0.15
        _MaxFogDistance ("Max Fog Distance", Float) = 40

        // _BubbleColor    ("Bubble Color", Color) = (0.85, 0.95, 1, 1)
        // _BubbleDensity  ("Bubble Density (cells across screen)", Range(4, 60)) = 18
        // _BubbleSpeed    ("Bubble Speed", Range(0, 0.5)) = 0.06
        // _BubbleSize     ("Bubble Size", Range(0.05, 0.6)) = 0.28
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Name "UnderwaterEffect"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // Provides the fullscreen-triangle Vert(), Varyings struct,
            // _BlitTexture and sampler_LinearClamp.
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


            float4 _TintColor;
            float  _FogDensity;
            float  _MaxFogDistance;

            // float4 _BubbleColor;
            // float  _BubbleDensity;
            // float  _BubbleSpeed;
            // float  _BubbleSize;

            // // Driven from C# each frame:
            // float4 _BubbleUpDir; // xy = normalized screen-space direction of world +Y
            // float  _EffectTime;  // independent clock, so speed/pause is controllable from script

            // float2 Hash22(float2 p)
            // {
            //     p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
            //     return frac(sin(p) * 43758.5453123);
            // }

            // // One layer of scrolling, sparse circular "bubbles" that always
            // // travel along 'dir' regardless of screen orientation.
            // float BubbleLayer(float2 uv, float aspect, float cellsAcross, float speed, float sizeScale, float seedOffset)
            // {
            //     float2 dir  = normalize(_BubbleUpDir.xy + 1e-5); //corresponds to world up
            //     float2 side = float2(-dir.y, dir.x); //perpendicular to dir

            //     float2 correctedUv = float2(uv.x * aspect, uv.y) * cellsAcross; //make cells square instead of stretched on wide screens
            //     float2 local = float2(dot(correctedUv, side), dot(correctedUv, dir)); //bubblespace

            //     local.y -= _EffectTime * speed * cellsAcross; //travel 'up'

            //     float2 cell = floor(local); //which cell we're in
            //     float2 f    = frac(local) - 0.5; //position within cell, centered at 0.5,0.5

            //     float minDist = 1.0;

            //     [unroll]
            //     for (int y = -1; y <= 1; y++)
            //     {
            //         [unroll]
            //         for (int x = -1; x <= 1; x++)
            //         {
            //             float2 neighbor = cell + float2(x, y); //check neighbors
            //             float2 rnd = Hash22(neighbor + seedOffset); //pseudorandom but deterministic, same cell reads same values

            //             // Skip most cells so bubbles read as sparse, not a grid, rnd runs [0,1]
            //             if (rnd.x > 0.95)
            //             {
            //                 float2 cellPos = float2(x, y) + (rnd - 0.5) * 0.7; //where to place bubble with a random offset
            //                 cellPos.x += sin(_EffectTime * 2.0 + rnd.y * 20.0) * 0.15; // wobble as it rises

            //                 float radius = lerp(0.15, 1.0, rnd.y) * sizeScale; //bubble radius
            //                 float d = length(f - cellPos) / radius; //distance from current pixel within cell (f) to bubb
            //                 minDist = min(minDist, d); //closest bubble
            //             }
            //         }
            //     }

            //     return smoothstep(1.0, 0.75, minDist); //aa bubble edge, no bubble if dist>1.0radius, inside bubble of dist<0.75r
            // }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.texcoord;
                float4 sceneColor = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv);

                // Depth-based underwater fog.
                float rawDepth    = SampleSceneDepth(uv);
                float linearDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float fog = 1.0 - exp(-_FogDensity * saturate(linearDepth / _MaxFogDistance) * 4.0);
                float3 fogged = lerp(sceneColor.rgb, _TintColor.rgb, saturate(fog));

                // // Three bubble layers at different scale/speed for a bit of depth variety.
                // float aspect = _ScreenParams.x / _ScreenParams.y;
                // float b1 = BubbleLayer(uv, aspect, _BubbleDensity,        _BubbleSpeed,       _BubbleSize,       0.0);
                // float b2 = BubbleLayer(uv, aspect, _BubbleDensity * 1.7,  _BubbleSpeed * 1.6, _BubbleSize * 0.6, 91.0);
                // float b3 = BubbleLayer(uv, aspect, _BubbleDensity * 0.55, _BubbleSpeed * 0.6, _BubbleSize * 1.4, 191.0);

                // float bubbleMask = saturate(b1 * 0.8 + b2 * 0.5 + b3 * 0.6);
                // float3 result = fogged + bubbleMask * _BubbleColor.rgb * 0.9;

                float3 result = fogged;
                return float4(result, sceneColor.a);
            }
            ENDHLSL
        }
    }
}
