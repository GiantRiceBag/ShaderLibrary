Shader "Unlit/Bloodstain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TestValue("Test Value",float) = 1
    }
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
                // ����ϵͳ�̳�����
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

            float _TestValue;

            fixed4 floatToColor(float value){
                return fixed4(value,value,value,1);
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float seed = i.texcoord.z;  // �̳������  StableRandomX ����������Ψһ  
                float time = i.texcoord.w; // �̳���������AgePercent �����׼������ʱ�� 0->1
                time = abs(_SinTime.w);

                float tp = 1 - time;
                float radius = 1 - tp * tp * tp * tp; // ͼ�ΰ뾶 0->1

                float2 uv = i.texcoord.xy - 0.5;

                // ����uv�Ƕ����ɷ�������
                float freq = lerp(1.2, 2.7, Random(seed * 48923.23));
                float n1 = snoise(atan2(uv.x, uv.y) * freq + seed * 764.2174);
                float n1p = pow(n1,6);

                // ԭ������
                float n2 = snoise(uv * 8 / radius + seed * 1481.28943);

                // ��Ϸ������ߺ�ԭ������
                // Potential = radius + noise * radius ^ 3;
                float p = radius * (0.23 + radius * radius * (n1p * 0.9 + n2 * 0.07));

                // Antialiased thresholding
                float l = length(uv);
                float a = smoothstep(l - 0.01, l, p); // Բ���ȡ

                return half4(i.color.rgb, i.color.a * a);
            }
            ENDCG
        }
    }

    
}
