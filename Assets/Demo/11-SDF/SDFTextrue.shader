Shader "Unlit/SDFTextrue"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CircleRadius("Circle Radius",float) = 0.5
        _CircleOffsetScale("Circle Offset",vector) = (0,0,1,1)
        _SDFTexture("SDF Texture",2D) = "white"{}
        _SDFThreshold("SDF Threshold",Range(0,1)) = 0.5
        _Lerp("SDF Lerp",Range(0,1)) = 0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
        }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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

            sampler2D _MainTex;
            sampler2D _SDFTexture;
            float4 _MainTex_ST;
            float4 _SDFTexture_ST;

            float _SDFThreshold;
            float _Lerp;

            float _CircleRadius;
            float4 _CircleOffsetScale;
 
            float circle_sdf(fixed2 coord,fixed radius)
            {
                float distance = length(coord);
                return  (distance - radius);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 sdfCol = tex2D(_SDFTexture, i.uv);

                fixed2 uv = ((i.uv - 0.5) * _CircleOffsetScale.zw) + _CircleOffsetScale.xy;

                float circle1 = circle_sdf(uv,_CircleRadius);
                float circle2 = circle_sdf(uv - 2 * _CircleOffsetScale.xy,_CircleRadius);
                float circle3 = circle_sdf(uv - _CircleOffsetScale.xy + _CircleOffsetScale.yx ,_CircleRadius);
                float circle4 = circle_sdf(uv - _CircleOffsetScale.xy - _CircleOffsetScale.yx ,_CircleRadius);

                float circle = min(min(min(circle1,circle2),circle3),circle4);

                return lerp((1 - (sdfCol.r)) - _SDFThreshold,circle,_Lerp) <= 0 ;
            }
            ENDCG
        }
    }
}
