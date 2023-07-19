Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RollProcess("Roll Process",float) = 1
        _Angle("Angle",float) = 1
        _MaxRadius("Max radius",float) = 1
        _MinRadius("Min radius",float) = 0.3
        _RollSmooth("Roll smooth",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI 3.1415926

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
            float _RollProcess;
            float _Angle;
            float _MaxRadius;
            float _MinRadius;
            float _RollSmooth;

            v2f vert (appdata v)
            {
                v2f o;

                 float3 positionOS = v.vertex;
                 float Px = abs(positionOS.x);
                 if(_RollProcess < Px) // 决定卷的范围 范围内顶点保持不动
                 {
                    // 符号函数 大于0->1 小于0->-1
                    half dir = sign(positionOS.x); 

                     //从哪里开始卷
                    half roll_angle ;
                    half roll_mask = abs(Px - _RollProcess);  // 越靠近外部的点 其卷的程度越大  注意px是时刻保持不变的
                    roll_angle = (roll_mask * _Angle -90)/180 *PI;  // 角度转弧度

                    half roll_Radius = _MaxRadius + Px*(_MinRadius -_MaxRadius)/ _RollSmooth;
  
                    half3 position_roll = 0;  // 转极坐标
                    position_roll.x = roll_Radius * cos(roll_angle) * dir;
                    position_roll.y = roll_Radius * sin(roll_angle);
                    position_roll.z = positionOS.z;

                    half3 roll_center = half3(_RollProcess*dir,roll_Radius,0); // 旋转后整体移动 
                    position_roll += roll_center; 
                    positionOS = position_roll;     
                }
                o.vertex = UnityObjectToClipPos(positionOS);
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
