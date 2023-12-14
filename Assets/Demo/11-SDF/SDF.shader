Shader "Unlit/SDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Color",Color) = (1,1,1,1)
        _CircleRadius("Circle Radius",Float) = 0.5
        _BoxRightTopPoint("Box Right Top Point",Vector) = (0.5,0.5,0,0)
        _BoxRoundCornerRadius("Round Corner",Range(0,1)) = 0.03
        _SDF_Lerp("Lerp",Range(0,1)) = 0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
             "Opaque"="Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

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
            float4 _MainTex_ST;
            fixed2 _BoxRightTopPoint;
            float _CircleRadius;
            float _SDF_Lerp;
            float _BoxRoundCornerRadius;

             // 圆 SDF
            /*
             *  目标点     圆形半径
             */
            float circle_sdf(fixed2 coord,fixed radius)
            {
                float distance = length(coord);
                return  (distance - radius);
            }

            // 圆角Box SDF
            /*
             *  目标点     矩形右上角点坐标    圆角半径
             */
            float box_sdf(fixed2 coord,fixed2 rectPoint,fixed roundCornerRadius)
            {
                fixed2 d = abs(coord) - rectPoint + roundCornerRadius;
                return (length(max(d,0)) + min(max(d.x,d.y),0)) - roundCornerRadius;
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
                fixed2 uv_center =(i.uv - 0.5);
                float sdf = lerp(circle_sdf(uv_center,_CircleRadius),box_sdf(uv_center,_BoxRightTopPoint,_BoxRoundCornerRadius),_SDF_Lerp) <= 0;
                fixed4 col = tex2D(_MainTex, i.uv) * sdf;
                return abs(col);
            }
            ENDCG
        }
    }
}
