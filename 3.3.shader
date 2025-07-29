// Helper function for 2x2 matrix multiplication
float2 mul_mat2(float4 m, float2 v) { return float2(m.x * v.x + m.y * v.y, m.z * v.x + m.w * v.y); }

float4 mainImage(VertData v_in) : TARGET {
  // Iterator and attenuation (distance-squared)
  float i = 0.2, a;

  // Resolution for scaling and centering
  float2 r = uv_size;

  // Convert normalized UV back to fragment coordinates, then apply original logic
  float2 F = v_in.uv * r;

  // Centered ratio-corrected coordinates
  float2 p = (F + F - r) / r.y / 0.7;

  // Diagonal vector for skewing
  float2 d = float2(-1, 1);

  // Blackhole center
  float2 b = p - i * d;

  // Rotate and apply perspective
  float2 c = mul_mat2(float4(1, 1, d / (0.1 + i / dot(b, b))), p);

  // Calculate attenuation
  a = dot(c, c);

  // Rotate into spiraling coordinates
  float angle = 0.5 * log(a) + elapsed_time * i;
  float4 trig = float4(0, 33, 11, 0);
  float2 v =
      mul_mat2(float4(cos(angle + trig.x), cos(angle + trig.y), cos(angle + trig.z), cos(angle + trig.w)), c) / i;

  // Waves cumulative total for coloring
  float2 w = float2(0, 0);

  // Loop through waves
  for (i = 0.2; i < 9.0; i += 1.0) {
    w += 1.0 + sin(v);
    // Distort coordinates
    v += 0.7 * sin(v.yx * (i + 1.0) + elapsed_time) / (i + 1.0) + 0.5;
  }

  // Acretion disk radius
  i = length(sin(v / 0.3) * 0.4 + c * (3.0 + d));

  // Red/blue gradient
  float4 result = 1.0 - exp(-exp(c.x * float4(0.6, -0.4, -1, 0))
                            // Wave coloring
                            / w.xyyx
                            // Acretion disk brightness
                            / (2.0 + i * i / 4.0 - i)
                            // Center darkness
                            / (0.5 + 1.0 / a)
                            // Rim highlight
                            / (0.03 + abs(length(p) - 0.7)));

  return result;
}
