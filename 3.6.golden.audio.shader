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
  // Persistent variable for audio smoothing
  // This will retain its value between function calls
  static float smoothed_audio = 0.0;

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
  float angle = elapsed_time * i;
  float cos_angle = cos(angle);
  float sin_angle = sin(angle);
  float cos_angle_offset = cos(angle + 33.0); // The vec4(0,33,11,0) offsets
  float sin_angle_offset = sin(angle + 33.0);

  // Proper 2D rotation matrix: [cos -sin; sin cos]
  float2 v = mul_mat2(float4(cos_angle, -sin_angle, sin_angle, cos_angle), c) / i;

  // Waves cumulative total for coloring
  float2 w = float2(0, 0);

  float audio = audio_magnitude > 0.63 ? 0.02 : 0.0;

  // Loop through waves
  for (float j = 1.0; j < 10.0; j += 1.0) {
    w += 1.0 + sin(v);
    // Distort coordinates
    v += (0.5 + (audio*10)) * sin(v.yx * j + elapsed_time) / j + 0.5;
  }

  // Acretion disk radius
  float disk_radius = length(sin(v / 0.3) * 0.4 + c * (3.0 + d));

  // Red/blue gradient
  // Calculate intensity using the original formula but we'll only use it for the red channel
  float intensity = 1.0 - exp(-exp(c.x * 0.6)
                              // Wave coloring
                              / w.x
                              // Acretion disk brightness
                              / (2.0 + disk_radius * disk_radius / 4.0 - disk_radius)
                              // Center darkness
                              / ((0.5 - 0) + 1.0 / a)
                              // Rim highlight
                              / (0.03 - audio + abs(length(p) - 0.7)));

  // Calculate the original result to get proper alpha channel
  float4 original_result = 1.0 - exp(-exp(c.x * float4(0.6, -0.4, -1, 0))
                                     // Wave coloring
                                     / w.xxxx
                                     // Acretion disk brightness
                                     / (2.0 + disk_radius * disk_radius / 4.0 - disk_radius)
                                     // Center darkness
                                     / (0.5 + 1.0 / a)
                                     // Rim highlight
                                     / (0.03 + abs(length(p) - 0.7)));

  // Calculate an average brightness to detect shine areas
  float brightness = (original_result.r + original_result.g + original_result.b) / 3.0;

  // Simpler approach with smooth transitions
  float4 result;
  // Start with pure red based on the intensity calculation
  result.r = intensity;
  result.g = intensity;

  // For white highlights - use whiteness factor to blend towards white
  // This creates a smooth transition from red to white for bright areas
  float whiteness = smoothstep(0.8, 0.95, brightness);
  result.r = intensity;
  result.g = intensity;
  result.b = intensity;

  // Add a subtle orange tint to mid-tones (avoid green/blue)
  // This adds orange to mid-brightness areas but not to whites or deep reds
  float orange_factor = smoothstep(0.2, 0.5, brightness) * (1.0 - whiteness);
  result.r += result.r * orange_factor * 0.28;
  result.g += result.r * orange_factor * 0.08;

  // Apply to alpha channel
  result.a = original_result.a;

  // Apply tail fadeout - reduce brightness for extended flame areas
  float distance_from_center = length(p);
  float fadeout_start_distance = 0.8;
  float fadeout_end_distance = 1.2;
  float fadeout_strength = 1.0;
  float tail_fadeout = smoothstep(fadeout_start_distance, fadeout_end_distance, distance_from_center);
  result *= (1.0 - tail_fadeout * fadeout_strength);

  // Apply saturation adjustment (increase value above 1.0 for higher saturation)
  float saturation_factor = 5.8; // Adjust this value to control saturation

  return adjust_saturation(result, saturation_factor);
}
