// Helper function for 2x2 matrix multiplication
float2 mul_mat2(float4 m, float2 v) { return float2(m.x * v.x + m.y * v.y, m.z * v.x + m.w * v.y); }

// Helper function to adjust saturation of a color - component by component approach
float4 adjust_saturation(float4 color, float saturation) {
  // Convert to grayscale using luminance values
  float gray = color.r * 0.299 + color.g * 0.587 + color.b * 0.114;

  // Manual linear interpolation between gray and original color
  float r = gray + saturation * (color.r - gray);
  float g = gray + saturation * (color.g - gray);
  float b = gray + saturation * (color.b - gray);

  return float4(r, g, b, color.a);
}

float4 mainImage(VertData v_in) : TARGET {
  // Rotation angle in degrees and conversion to radians
  // Create a ping-pong effect between 0 and 1
  float t = fmod(elapsed_time * 0.02, 2.0);
  if (t > 1.0)
    t = 2.0 - t; // Reverse direction for second half of cycle
  // Apply smoothstep for easing and scale to 0-90 degrees
  float rotation_degrees = smoothstep(0.0, 1.0, t) * 90.0;
  float rotation = rotation_degrees * 0.0174533; // Convert to radians (PI/180)

  // Iterator and attenuation (distance-squared)
  float i = 0.2, a;

  // Resolution for scaling and centering
  float2 r = uv_size;

  // Convert normalized UV to fragment coordinates with Y-flip for DirectX
  float2 F = float2(v_in.uv.x * r.x, (1.0 - v_in.uv.y) * r.y);

  // Centered ratio-corrected coordinates
  float2 p = (F + F - r) / r.y / 0.7;

  // Apply 45-degree rotation to the coordinates
  float cos_rot = cos(rotation);
  float sin_rot = sin(rotation);
  float2 p_rotated = mul_mat2(float4(cos_rot, -sin_rot, sin_rot, cos_rot), p);
  p = p_rotated;

  // Diagonal vector for skewing
  float2 d = float2(-1, 1);

  // Blackhole center
  float2 b = p - i * d;

  // Rotate and apply perspective
  float2 perspective_scale = d / (0.1 + i / dot(b, b));
  float2 c = mul_mat2(float4(1, 1, perspective_scale.x, perspective_scale.y), p);

  // Calculate attenuation
  a = dot(c, c);

  // Rotate into spiraling coordinates
  float angle = 0.5 * log(a) + elapsed_time * i;
  float cos_angle = cos(angle);
  float sin_angle = sin(angle);
  float cos_angle_offset = cos(angle + 33.0); // The vec4(0,33,11,0) offsets
  float sin_angle_offset = sin(angle + 33.0);

  // Proper 2D rotation matrix: [cos -sin; sin cos]
  float2 v = mul_mat2(float4(cos_angle, -sin_angle, sin_angle, cos_angle), c) / i;

  // Waves cumulative total for coloring
  float2 w = float2(0, 0);

  // Loop through waves
  for (float j = 1.0; j < 9.0; j += 1.0) {
    w += 1.0 + sin(v);
    // Distort coordinates
    v += 0.7 * sin(v.yx * j + elapsed_time) / j + 0.5;
  }

  // Acretion disk radius
  float disk_radius = length(sin(v / 0.3) * 0.4 + c * (3.0 + d));

  // Red/blue gradient
  float4 result = 1.0 - exp(-exp(c.x * float4(0.6, -0.4, -1, 0))
                            // Wave coloring
                            / w.xxxx
                            // Acretion disk brightness
                            / (2.0 + disk_radius * disk_radius / 4.0 - disk_radius)
                            // Center darkness
                            / (0.5 + 1.0 / a)
                            // Rim highlight
                            / (0.03 + abs(length(p) - 0.7)));

  // Apply saturation adjustment (increase value above 1.0 for higher saturation)
  float saturation_factor = 1.5; // Adjust this value to control saturation
  return adjust_saturation(result, saturation_factor);
}
