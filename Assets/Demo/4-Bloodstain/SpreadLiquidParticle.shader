Shader "LSQ/Effect/Liquid/Spread Particle"
{
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent" 
            "IgnoreProjector"="true" 
            "DisableBatching"="true"
        }

		Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/ShaderUtility/Snoise2D.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                half4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 texcoord : TEXCOORD0;
                half4 color : COLOR;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                // Parameters from the particle system
                float seed = i.texcoord.z;
                float time = i.texcoord.w;

                // Animated radius parameter
                float tp = 1 - time;
                float radius = 1 - tp * tp * tp * tp;

                // Zero centered UV
                float2 uv = i.texcoord.xy - 0.5;

                // Noise 1 - Radial curve
                float freq = lerp(1.2, 2.7, Random(seed * 48923.23));
                float n1 = snoise(atan2(uv.x, uv.y) * freq + seed * 764.2174);

                // I prefer steep curves, so use sixth power.
                float n1p = n1 * n1;
                n1p = n1p * n1p * n1p;

                // Noise 2 - Small dot
                float n2 = snoise(uv * 8 / radius + seed * 1481.28943);

                // Potential = radius + noise * radius ^ 3;
                float p = radius * (0.23 + radius * radius * (n1p * 0.9 + n2 * 0.07));

                // Antialiased thresholding
                float l = length(uv);
                float a = smoothstep(l - 0.01, l, p);

                return half4(i.color.rgb, i.color.a * a);
            }
            ENDCG
        }
    }
}
