Shader "Custom/CloudsControl"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Cloud Color", Color) = (1,1,1,1)
		_SubColor("Subsurface Color", Color) = (0.15,0.6,0.9,1)
		_Speed("Speed", Range(0,100)) = 1
		_Offset("Secondary Offset", Range(0,2)) = 0
		_Scale("Secondary Scale", Range(0,2)) = 1
		_Speed2("Secondary Speed", Range(-2,4)) = 1
		_Depth("Depth", Range(0.05,2)) = 0.05
		_Displacement("Displacement", Range(0, 100.0)) = 0.1
		_DirectionX("Direction Control X", Range(-1,1)) = 1
		_DirectionY("Direction Control Y", Range(-1,1)) = 1
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 100
			Cull Back
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 dcolor : COLOR;
				float4 screenPos : TEXCOORD2;
			};

			sampler2D _CameraDepthTexture; // automatically set up by Unity. Contains the scene's depth buffer
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Depth;
			float _Displacement;
			float _Speed;
			float _Offset;
			float _Scale;
			float _Speed2;

			fixed4 _Color;
			fixed4 _SubColor;

			fixed _DirectionX;
			fixed _DirectionY;

			fixed2 dir;

			v2f vert (appdata v)
			{
				v2f o;

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				dir = fixed2(_DirectionX, _DirectionY);

				float2 worldScale = float2(
					length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x))* 0.03, // scale x axis
					length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)) * 0.03 // scale y axis
					);

				//get position irrelevant of scale, rotation, position
				float2 Pos = v.vertex.xz * worldScale + mul(unity_ObjectToWorld, v.vertex).xz * 0.03 - v.vertex.xz * worldScale;

				o.dcolor = (tex2Dlod(_MainTex, float4((Pos + dir*_Time.x * _Speed * 0.05) * _MainTex_ST.xy, 0, 0)) + tex2Dlod(_MainTex, float4((Pos * _Scale + dir * _Speed2 * _Time.x * _Speed * 0.05 + _Offset) * _MainTex_ST.xy, 0, 0))) / 2;
				
				v.vertex.xyz += v.normal * o.dcolor * _Displacement;

				o.vertex = UnityObjectToClipPos(v.vertex);
				
				o.screenPos = ComputeScreenPos(o.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//Get the distance to the camera from the depth buffer for this point
				float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r);
				//Actual distance to the camera
				float fragZ = i.screenPos.a;

				//calculate cloudy falloff
				float DepthIntersect = saturate(_Depth * (sceneZ - fragZ));

				float invCol = i.dcolor.x;// *-1 + 1;
				//fade to subsurfaceCol
				fixed4 col = lerp(_SubColor, _Color, invCol);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return float4(col.xyz,DepthIntersect);// *float4(col.x, col.y, col.z, factor);
			}
			ENDCG
		}
	}
}
