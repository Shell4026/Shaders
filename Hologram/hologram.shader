Shader "VRC/Hologram"
{
    Properties
    {
		[MainTexture]_Texture("Main Texture", 2D) = "black" {}
		_Texture2("Hologram Texture", 2D) = "black" {}
		[HDR]_Color("Color", Color) = (0.53, 0.9, 1.0, 1.0)
		_Power("Outline Power", float) = 0.5
		_Speed("Scroll Speed", Range(0.0, 2.0)) = 0.25
		_Line("Line", float) = 1.5
		_Alpha("Alpha", Range(0.0, 10.0)) = 0.5
		_RandomSpeed("RandomSpeed", Range(0.0, 5.0)) = 0.5
		_RandomRange("RandomRange", float) = 0.1
		_RandomHeight("RandomHeight", float) = 0.01
		_Height("Height", float) = 100.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue"="Transparent"}
        LOD 200
		Cull off
		Blend SrcAlpha OneMinusSrcAlpha
		//GrabPass{"_GrabTexture"}
		Pass {
			ZWrite On
			ColorMask 0
			
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : Normal;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : Normal;
            };

            //sampler2D _GrabTexture;
			sampler2D _Texture;
			sampler2D _Texture2;
			float4 _Color;
			float _Power;
			float _Speed;
			float _Line;
			float _Alpha;
			float _RandomSpeed;
			float _RandomRange;
			float _RandomHeight;
			
			float random(float t)
			{
				return -1 + 2 * frac(sin(t) * 43758.5453123);
			}

            v2f vert (appdata v)
            {
				float seed = floor(_Time.y * _RandomSpeed)%_RandomSpeed * v.vertex.y * 5;
				float ran2 = step(0.9, random(seed));
				float is_flick = step(0.9 + 0.1 - _RandomSpeed * 0.1, random(_Time.y));
				float randir = random(_Time.y * floor(v.vertex.y / _RandomHeight)); 
				
				v.vertex.x += is_flick * randir * _RandomRange;
				
				v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.normal = mul(UNITY_MATRIX_MV, float4(v.normal, 0.0)).xyz;
				
                return o;
            }
			
            float4 frag (v2f i) : SV_Target
            {
				float4 color = float4(1.0, 1.0, 1.0, 1.0);
				return color;
            }
            ENDCG
		}
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
				float3 normal : Normal;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				//float4 grab_uv : TEXCOORD1;
                float4 vertex : SV_POSITION;
				float4 view_pos : TEXCOORD1;
				float4 world_pos : TEXCOORD2;
				float4 model_pos : TEXCOORD3;
				float3 normal : Normal;
            };

            //sampler2D _GrabTexture;
			sampler2D _Texture;
			sampler2D _Texture2;
			float4 _Color;
			float _Power;
			float _Speed;
			float _Line;
			float _Alpha;
			float _RandomSpeed;
			float _Height;
			float _RandomRange;
			float _RandomHeight;
			
			float random(float t)
			{
				return -1 + 2 * frac(sin(t) * 43758.5453123);
			}
			
			float2 random2(float2 st){
				st = float2(dot(st, float2(127.1, 311.7)),
							dot(st, float2(269.5, 183.3)));
						
				return -1 + 2 * frac(sin(st) * 43758.5453123);
			}
			
			float noise(float2 st){
				float2 i = floor(st);
				float2 f = frac(st);
				
				float2 u = f * f * (3.0 - 2.0 * f);
				
				return lerp(lerp(dot(random2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
								 dot(random2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
							lerp(dot(random2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
								 dot(random2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
			}
			
			float frensel(float3 cam_to_vert, float3 normal, float power)
			{
				float outline = 1.0 - abs(dot(normalize(cam_to_vert), normalize(normal)));
				return smoothstep(1.0 - power, 1.0, outline);
			}

            v2f vert (appdata v)
            {
				float seed = floor(_Time.y * _RandomSpeed)%_RandomSpeed * v.vertex.y * 5;
				float ran2 = step(0.9, random(seed));
				float is_flick = step(0.9 + 0.1 - _RandomSpeed * 0.1, random(_Time.y));
				float randir = random(_Time.y * floor(v.vertex.y / _RandomHeight)); 
				
				v.vertex.x += is_flick * randir * _RandomRange;
				
				v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.world_pos = mul(UNITY_MATRIX_M, v.vertex);
				o.view_pos = mul(UNITY_MATRIX_MV, v.vertex);
				o.normal = mul(UNITY_MATRIX_MV, float4(v.normal, 0.0)).xyz;
				o.model_pos = v.vertex;
				
                return o;
            }
			
            float4 frag (v2f i) : SV_Target
            {
				float4 color;
				//holgram
				{
					float3 v = i.view_pos;
					float fren = frensel(v, i.normal, _Power);
					
					float2 holo_uv = i.uv;
					holo_uv.y = (i.world_pos.y + _Time.y * _Speed * 0.1) * _Line;
					
					float4 main_tex = tex2D(_Texture, i.uv);
					float4 holo_tex = tex2D(_Texture2, holo_uv);
					
					float4 holo = float4(fren, fren, fren, 1.0) + holo_tex;

					color = holo * _Color * main_tex;
					color.a = _Alpha;
				}
				//dissolve
				{
					float noi = noise(i.uv*20);
					float cut = 0.9 - noi;

					color.a *= step(noi, (-i.model_pos.y - 1.0) + _Height);
				}
				return color;
            }
            ENDCG
        }
    }
}
