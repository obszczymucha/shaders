float4 mainImage(VertData v_in) : TARGET {
  // Iterator and attenuation (distance-squared)
  float i = 0.2;
  float a;

  // Resolution for scaling and centering
  float2 r = uv_size.xy;

  // Centered ratio-corrected coordinates
  float2 F = v_in.uv * uv_size;
  float2 p = (F + F - r) / r.y / 0.7;

  float oscillation = sin(elapsed_time * 0.05) * 0.5 + 0.5;             // Value between 0 and 1
  float angleDegrees = 20.0 + smoothstep(0.0, 1.0, oscillation) * 65.0; // Smoothly interpolate between 20 and 85
  float angle = radians(angleDegrees);
  float2x2 rotationMatrix = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
  p = mul(rotationMatrix, p);

  p.y = -p.y; // Apply horizontal flip (mirror across y-axis)
  p.x = -p.x; // Apply vertical flip (mirror across x-axis)

  // Diagonal vector for skewing
  float2 d = float2(-1.0, 1.0);

  // Blackhole center
  float2 b = p - i * d;

  // Rotate and apply perspective
  float perspectiveFactor = 0.1 + i / dot(b, b);
  float2x2 perspectiveMatrix = float2x2(1.0, 1.0, d.x / perspectiveFactor, d.y / perspectiveFactor);
  float2 c = mul(perspectiveMatrix, p); // Changed order: matrix * vector

  // Calculate a for the spiral rotation
  a = dot(c, c);

  // Rotate into spiraling coordinates
  float spiralAngle = 0.5 * log(a) + elapsed_time * i;
  float2x2 spiralMatrix =
      float2x2(cos(spiralAngle), -sin(spiralAngle + 33.0), sin(spiralAngle + 11.0), cos(spiralAngle)) / i;
  float2 v = mul(spiralMatrix, c); // Changed order: matrix * vector

  // Waves cumulative total for coloring
  float2 w = float2(0.0, 0.0);

  // Loop through waves
  for (int iter = 0; iter < 8; iter++) {
    i += 1.0;
    // Distort coordinates
    v += 0.7 * sin(v.yx * i + elapsed_time) / i + 0.5;
    // Add to wave total
    w += 1.0 + sin(v);
  }

  // Acretion disk radius
  i = length(sin(v / 0.3) * 0.4 + c * (3.0 + d));

  // Calculate color components
  float4 colorBase = float4(0.2, -0.4, -1.0, 0.0);
  float4 expArg = c.x * colorBase;
  float4 expResult = exp(expArg);

  // Wave coloring factor
  float4 waveColor = float4(w.x / 2., w.y, w.y, w.x);

  // Acretion disk brightness
  float diskBrightness = 2.0 + i * i / 4.0 - i;

  // Center darkness
  float centerDarkness = 0.1 + 1.0 / a;

  // Rim highlight
  float rimHighlight = 0.03 + abs(length(p) - 0.7);

  // Final color calculation
  float4 result = 1.0 - exp(-expResult / waveColor / diskBrightness / centerDarkness / rimHighlight);

  return result;
}
