Shader "Unlit/CircularLoadingBar"
{
    Properties
    {
        [NoScaleOffset]_MainTex("MainTex",2D) = "white"{}
        _Color_Unselected("Color Unselected",Color) = (0.5,0.5,0.5,1)
        [Space]
        [Toggle]_Hollow("Hollow",float) = 0
        [Space]
        _Radius("Radius",Range(0,1)) = 0.5
        _InnerRadius("Innver Radius",Range(0,1)) = 0.1
        [IntRange]_SegementAmount("Segment Amount",Range(1,16)) = 4 
        _SegmentSize("Segment Size",float) =  10
        _Speed("Speed",float) = 1
        [Toggle]_Invert("Invert",float) = 0
        [Space]
        _UVScale("UV Scale",float) = 1
        _UVAngleOffset("UV Angle Offset",float) = 0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma shader_feature _HOLLOW_ON
            #pragma shader_feature _INVERT_ON
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #define PI 3.14159
            #define DPI 6.23018

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _UVScale;
            float _UVAngleOffset;
            float _Radius;
            float _InnerRadius;

            int _SegementAmount;
            float _SegmentSize;
            float _Speed;

            float4 _Color_Unselected;

            float GetCullingResult(float2 polorCoord)
            {
                float cullingResult = step(polorCoord.x,_Radius);
                #if _HOLLOW_ON
                    _InnerRadius = min(_Radius,_InnerRadius);
                    cullingResult -= step(polorCoord.x,_InnerRadius);
                #endif

                float angleInteval = DPI / _SegementAmount; // radian
                float angle = polorCoord.y;
                for(int i = 0;i<_SegementAmount;i++){
                    cullingResult -= step(i * angleInteval,angle) - step(i * angleInteval + _SegmentSize/180 * PI,angle);
                }

                return saturate(cullingResult);
            }

            float4 GetColor(float2 polorCoord)
            {
                float result;
                float angle = polorCoord.y;
                float angleInteval = DPI / _SegementAmount; // radian

                int i = (_Time.y * _Speed) % _SegementAmount;
                #if _INVERT_ON
                    i = (_SegementAmount - 1 - i)%_SegementAmount;
                #endif
                result = (step(i * angleInteval + _SegmentSize/180 * PI,angle) - step((i+1) * angleInteval,angle));

                return lerp(_Color_Unselected,float4(1,1,1,1),result);
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv - 0.5;
                float r = length(uv);
                float delta = (abs((atan2(uv.y,uv.x) + PI) + _UVAngleOffset)) % DPI;
                float2 polorCoord = float2(r,delta);

                float cullingResult = GetCullingResult(polorCoord);
                float4 targetCol = GetColor(polorCoord);
                polorCoord *=  _UVScale;
                float4 col = tex2D(_MainTex,polorCoord) * targetCol;

                return float4(col.rgb,cullingResult);
                return float4(polorCoord,0,cullingResult);
            }
            ENDCG
        }
    }
}
