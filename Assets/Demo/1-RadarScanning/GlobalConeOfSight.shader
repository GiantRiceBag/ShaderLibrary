Shader "Unlit/GlobalConeOfSight"
{
    Properties
    {
        [Toggle]_Invert("Invert",float) = 0
        _Origin("Origin",VECTOR) = (0.5,0.5,0,0)
        _SightRadius("Sight Radius",Range(0,1)) = 0.5
        _SightAngle("Sight Angle",float) = 30
        _ScanSpeed("Scaning Speed",float) = 1
        _SightColor("Sight Color",COLOR) = (1,0,0,1)
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparents"
            "Queue"="Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define PI 3.1415926535

            #pragma shader_feature _INVERT_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 positionWS : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4x4 _MatrixVP;

            float _SightRadius;
            float _SightAngle;
            float _ScanSpeed;

            float4 _Origin;
            float4 _SightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.positionWS = mul(UNITY_MATRIX_M,v.vertex);
                return o;
            }

            float GetCullingResult(float4 positionWS)
            {
                float4 positionPS_DepthCam = mul(_MatrixVP,positionWS);
                float3 ndc = positionPS_DepthCam.xyz / positionPS_DepthCam.w;
                ndc = (ndc + 1) / 2;
                float sampleDepth = 1 - SAMPLE_DEPTH_TEXTURE(_MainTex,sampler_MainTex,ndc.xy);
                return ndc.z < sampleDepth;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - _Origin.xy;
                float len = length(uv);
                float radius = _SightRadius > len;
                float currentAngle = atan2(uv.y,uv.x) / PI * 180;
                float sightRange = smoothstep(-_SightAngle,0,currentAngle) - smoothstep(0,_SightAngle,currentAngle);
                float sight = sightRange * radius * GetCullingResult(i.positionWS);
                
                float3 destCol = lerp(float3(0,0,0),_SightColor.rgb,saturate(sight));
                return float4(destCol,saturate(sight));
            }
            ENDHLSL
        }
    }
}
