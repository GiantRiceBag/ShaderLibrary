Shader "Unlit/SimpleScroll"
{
    // ����������λ�������Mesh

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RollProcess("Roll Process",float) = 5
        _Angle("Angle",float) = 10
        _MaxRadius("Max radius",float) = 1
        _MinRadius("Min radius",float) = 0.3
        _RollSmooth("Roll smooth",float) = 1
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
            #define PI 3.1415926
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Angle;
            float _RollProcess;  // �������С�й� Max=max(vertex.x) Min=0
            float _MaxRadius;
            float _MinRadius;
            float _RollSmooth;

            v2f vert (appdata v)
            {
                v2f o;

                if(_RollProcess < v.positionOS.x){
                    half roll_angle ;
                    half roll_mask = abs(v.positionOS.x - _RollProcess);  // Խ�����ⲿ�ĵ� ��ת�Ƕ�Խ��
                    roll_angle = (roll_mask * _Angle - 90)/180 *PI;  // �Ƕ�ת����
                    
                    half roll_Radius = _MaxRadius + v.positionOS.x * (_MinRadius -_MaxRadius) / _RollSmooth; // Խ�����ⲿ�ĵ� ת���뾶Խ�� �����뾶-����ֵ��
   
                    half3 position_roll = 0; 
                    position_roll.x = roll_Radius * cos(roll_angle);
                    position_roll.y = roll_Radius * sin(roll_angle);
                    position_roll.z = v.positionOS.z;

                    half3 roll_center = half3(_RollProcess,roll_Radius,0); // ���������ƶ� y���ƶ�����Ϊת���뾶
                    position_roll += roll_center; 
                    v.positionOS = float4(position_roll,0);     
                }

                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
