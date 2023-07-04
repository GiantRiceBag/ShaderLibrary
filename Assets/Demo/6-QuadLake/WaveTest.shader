Shader "Unlit/WaveTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

        inline float2 unity_voronoi_noise_randomVector (float2 UV, float offset)
        {
            float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
            UV = frac(sin(mul(UV, m)) * 46839.32);
            return float2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
        }

        void Unity_Voronoi_float(float2 UV, float AngleOffset, float CellDensity, out float Out, out float Cells)
        {
            float2 g = floor(UV * CellDensity);
            float2 f = frac(UV * CellDensity);
            float t = 8.0;
            float3 res = float3(8.0, 0.0, 0.0);

            for(int y=-1; y<=1; y++)
            {
                for(int x=-1; x<=1; x++)
                {
                    float2 lattice = float2(x,y);
                    float2 offset = unity_voronoi_noise_randomVector(lattice + g, AngleOffset);
                    float d = distance(lattice + offset, f);
                    if(d < res.x)
                    {
                        res = float3(d, offset.x, offset.y);
                        Out = res.x;
                        Cells = res.y;
                    }
                }
            }
        }

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - 0.5;
                float len = (length(uv) - _Time.y * 0.2) * 30;
                float delta = atan2(uv.y,uv.x);
                float2 polorCoord = float2(len,delta);
                float2 rawPolorCoord = float2(length(uv),delta);

                float noise,cell;
                Unity_Voronoi_float(polorCoord,_Time.y,5,noise,cell);
                return smoothstep(noise-0.1,noise+0.1,sin(len));
            }
            ENDCG
        }
    }
}
