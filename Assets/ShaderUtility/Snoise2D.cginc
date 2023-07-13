            float3 mod289(float3 x)
            {
                return x - floor(x / 289.0) * 289.0;
            }

            float2 mod289(float2 x)
            {
                return x - floor(x / 289.0) * 289.0;
            }

            float3 permute(float3 x)
            {
                return mod289((x * 34.0 + 1.0) * x);
            }

            float3 taylorInvSqrt(float3 r)
            {
                return 1.79284291400159 - 0.85373472095314 * r;
            }

            float snoise(float2 v)
            {
                const float4 C = float4( 0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                                         0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                                         0.024390243902439); // 1.0 / 41.0
                // First corner
                float2 i  = floor(v + dot(v, C.yy));
                float2 x0 = v -   i + dot(i, C.xx);

                // Other corners
                float2 i1;
                i1.x = step(x0.y, x0.x);
                i1.y = 1.0 - i1.x;

                // x1 = x0 - i1  + 1.0 * C.xx;
                // x2 = x0 - 1.0 + 2.0 * C.xx;
                float2 x1 = x0 + C.xx - i1;
                float2 x2 = x0 + C.zz;

                // Permutations
                i = mod289(i); // Avoid truncation effects in permutation
                float3 p =
                  permute(permute(i.y + float3(0.0, i1.y, 1.0))
                                + i.x + float3(0.0, i1.x, 1.0));

                float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
                m = m * m;
                m = m * m;

                // Gradients: 41 points uniformly over a line, mapped onto a diamond.
                // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
                float3 x = 2.0 * frac(p * C.www) - 1.0;
                float3 h = abs(x) - 0.5;
                float3 ox = floor(x + 0.5);
                float3 a0 = x - ox;

                // Normalise gradients implicitly by scaling m
                m *= taylorInvSqrt(a0 * a0 + h * h);

                // Compute final noise value at P
                float3 g;
                g.x = a0.x * x0.x + h.x * x0.y;
                g.y = a0.y * x1.x + h.y * x1.y;
                g.z = a0.z * x2.x + h.z * x2.y;
                return 130.0 * dot(m, g);
            }

            float3 snoise_grad(float2 v)
            {
                const float4 C = float4( 0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                                         0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                                         0.024390243902439); // 1.0 / 41.0
                // First corner
                float2 i  = floor(v + dot(v, C.yy));
                float2 x0 = v -   i + dot(i, C.xx);

                // Other corners
                float2 i1;
                i1.x = step(x0.y, x0.x);
                i1.y = 1.0 - i1.x;

                // x1 = x0 - i1  + 1.0 * C.xx;
                // x2 = x0 - 1.0 + 2.0 * C.xx;
                float2 x1 = x0 + C.xx - i1;
                float2 x2 = x0 + C.zz;

                // Permutations
                i = mod289(i); // Avoid truncation effects in permutation
                float3 p =
                  permute(permute(i.y + float3(0.0, i1.y, 1.0))
                                + i.x + float3(0.0, i1.x, 1.0));

                float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
                float3 m2 = m * m;
                float3 m3 = m2 * m;
                float3 m4 = m2 * m2;

                // Gradients: 41 points uniformly over a line, mapped onto a diamond.
                // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
                float3 x = 2.0 * frac(p * C.www) - 1.0;
                float3 h = abs(x) - 0.5;
                float3 ox = floor(x + 0.5);
                float3 a0 = x - ox;

                // Normalise gradients
                float3 norm = taylorInvSqrt(a0 * a0 + h * h);
                float2 g0 = float2(a0.x, h.x) * norm.x;
                float2 g1 = float2(a0.y, h.y) * norm.y;
                float2 g2 = float2(a0.z, h.z) * norm.z;

                // Compute noise and gradient at P
                float2 grad =
                  -6.0 * m3.x * x0 * dot(x0, g0) + m4.x * g0 +
                  -6.0 * m3.y * x1 * dot(x1, g1) + m4.y * g1 +
                  -6.0 * m3.z * x2 * dot(x2, g2) + m4.z * g2;
                float3 px = float3(dot(x0, g0), dot(x1, g1), dot(x2, g2));
                return 130.0 * float3(grad, dot(m4, px));
            }

            uint Hash(uint s)
            {
                s ^= 2747636419u;
                s *= 2654435769u;
                s ^= s >> 16;
                s *= 2654435769u;
                s ^= s >> 16;
                s *= 2654435769u;
                return s;
            }

            float Random(uint seed)
            {
                return float(Hash(seed)) / 4294967295.0; // 2^32-1
            }

            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            void GradientNoise(float2 UV, float Scale, out float Out)
            {
                Out = unity_gradientNoise(UV * Scale) + 0.5;
            }