Shader "Unlit/ConeOfSight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle]_Invert("Invert",float) = 0
        _Origin("Origin",VECTOR) = (0.5,0.5,0,0)
        _SightRadius("Sight Radius",Range(0,1)) = 0.5
        _SightAngle("Sight Angle",float) = 30
        _ScanSpeed("Scaning Speed",float) = 1
        _SightColor("Sight Color",COLOR) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define PI 3.1415926535
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            #pragma shader_feature _INVERT_ON

            sampler2D _MainTex;

            float _SightRadius;
            float _SightAngle;
            float _ScanSpeed;

            float4 _SightColor;
            float4 _Origin;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 Rotate(float2 uv,float rotation)
            {
                float sine,cosine;
                float angle = rotation * 2 * PI;
                sincos(angle,sine,cosine);
                #if _INVERT_ON
                    return float2(cosine*uv.x + sine*uv.y,-sine*uv.x + cosine*uv.y);
                #else
                    return float2(cosine*uv.x - sine*uv.y,sine*uv.x + cosine*uv.y);
                #endif
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                float2 uv = i.uv - _Origin.xy;
                uv = Rotate(uv,_Time.y * _ScanSpeed);
                float len = length(uv);
                float radius = _SightRadius > len;
                float currentAngle = atan2(uv.y,uv.x) / PI * 180;
                float sightRange = smoothstep(-_SightAngle,0,currentAngle) - smoothstep(0,_SightAngle,currentAngle);
                float sight = sightRange * radius;
                
                return lerp(fixed4(0,0,0,1),_SightColor,saturate(sight)); 
            }
            ENDCG
        }
    }
}
