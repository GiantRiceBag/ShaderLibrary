Shader "Unlit/PlaneOcean(Shader)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Depth Color Gradient)]
        _DepthMaxDistance("Depth Max Distance",float) = 5
        _DepthShallowColor("Depth Shallow Color",Color) = (1,1,1,1)
        _DepthDeepColor("Depth Deep Color",Color) = (0,0,0,1)

        [space(30)]
        [Header(Wave)]
        _WaveMaxDistance("Wave Max Distance",float) = 1
        _WaveStrength("Wave Strength",float) = 1
        _WaveSpeed("Wave Speed",float) = 1
        _WaveCount("Wave Count",float) = 10
        _WaveCutOff("Wave Cutoff",range(0,1)) = 0.5
        _WaveColor("Wave Color",Color) = (1,0,0,1)
        [NoScaleOffset]_WaveTexture("Wave Texture",2D) ="White"{}

        [space(30)]
        [Header(Surface Foam)]
        [NoScaleOffset]_SurfaceNoise("Surface Noise",2D) = "White"{}
        [NoScaleOffset]_SurfaceDistortion("Surface Distortion",2D) = "White"{}
        _FoamMaxDistance("Foam Max Distance",float) = 1
        _FoamSpeed("Foam Speed",float) = 1
        _FoamDistortionSpeed("Foam Distortion Speed",float) = 1
        _FoamCutOff("Foam CutOff",Range(0,1)) = 0.5
        _FoamColor("Foam Color",Color) = (1,1,1,1)
        _FoamDirection("Foam Direction",Vector) = (1,0,0,0)
        _FoamScale("Foam Scale",float) = 1
        _FoamFeather("Foam Feather",Range(0,0.5)) = 0.1

        [space(30)]
        [Header(Noise)]
        _NoiseStrength("Noise Strength",float) = 1
        _NoiseSpeed("Noise Speed",float) = 1
        _NoiseScale("Noise Scale",float) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "LightMode"="UniversalForward"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma shader_feature _MAIN_LIGHT_SHADOWS
            #pragma shader_feature _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma shader_feature _SHADOWS_SOFT

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD3;
                float4 positionCS : SV_POSITION;
                float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform sampler2D DBufferDepth;
            float4 _DepthShallowColor;
            float4 _DepthDeepColor;
            float _DepthMaxDistance;

            float _WaveStrength;
            float _WaveMaxDistance;
            float _WaveSpeed;
            float _WaveCutOff;
            float _WaveCount;
            float2 _FoamDirection;
            float4 _WaveColor;
            sampler2D _WaveTexture;

            sampler2D _SurfaceNoise;
            sampler2D _SurfaceDistortion;
            float _FoamSpeed;
            float _FoamMaxDistance;
            float _FoamCutOff;
            float _FoamFeather;
            float _FoamScale;
            float _FoamDistortionSpeed;
            float4 _FoamColor;

            float _NoiseStrength;
            float _NoiseSpeed;
            float _NoiseScale;

            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            {
                Out = unity_gradientNoise(UV * Scale) + 0.5;
            }

            v2f vert (appdata v)
            {
                v2f o;

                float noise;
                Unity_GradientNoise_float(v.uv + _Time.y * _NoiseSpeed,_NoiseScale,noise);
                v.positionOS.y += noise * _NoiseStrength;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.screenPos = ComputeScreenPos(o.positionCS); // 裁剪空间坐标转映射至 [0,w] 
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 finalColor;
                // 屏幕坐标也可以用i.positionCS.xy / _ScreenParams.xy
                // 深度纹理中的值是非线性分布 需要用LinearEyeDepth转为相机空间中的对应线性值
                // Linear01Depth同理 不过映射至 [0,1]
                float depth = LinearEyeDepth(tex2Dproj(DBufferDepth,i.screenPos),_ZBufferParams); // tex2Dproj对uv做一次齐次除法映射至[0,1]
                float depthOffset = depth - LinearEyeDepth(i.positionCS.z,_ZBufferParams); // i.positionCS.z是经过齐次除法和映射后的深度值
                float depthOffsetNormal = saturate(depthOffset / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthShallowColor,_DepthDeepColor,depthOffsetNormal);

                // 大致过程就是获取随机数调整waveOffsetNormal
                float waveOffsetNormal = 1 - saturate(depthOffset / _WaveMaxDistance); // 取浅片元
                float2 waveUV = float2(i.uv.x,(waveOffsetNormal + _WaveSpeed * _Time.y) * _WaveCount); 

                float wave = tex2D(_WaveTexture,waveUV).r * waveOffsetNormal * _WaveStrength; //噪声取样
                wave = step(_WaveCutOff,wave);
                finalColor = lerp(waterColor,_WaveColor,waveOffsetNormal + wave);

                float foamOffsetNormal = saturate(depthOffset / _FoamMaxDistance); // 取深片元
                float2 foamUV = i.uv * _FoamScale +  _FoamDirection * _FoamSpeed * _Time.y; // UV移动
                foamUV += tex2D(_SurfaceDistortion,foamUV + _FoamDirection * _FoamDistortionSpeed * _Time.y); // UV扰动
                float foamSample = tex2D(_SurfaceNoise,foamUV).r * foamOffsetNormal;
                foamSample = smoothstep(_FoamCutOff -_FoamFeather,_FoamCutOff+_FoamFeather,foamSample);

                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light light = GetMainLight(shadowCoord,i.positionWS,1);
                float shadowMask = 1 - light.shadowAttenuation;

                finalColor = lerp(finalColor,_FoamColor,foamSample);
                return lerp(finalColor,finalColor * float4(_GlossyEnvironmentColor.xyz,1),shadowMask);
            }
            ENDHLSL
        }
    }
}
