static const float REPEAT = 5.0;

// Custom mod function for better wrapping behavior
float3 mod_wrap(float3 x, float y) { return x - y * floor(x / y); }

float2x2 rot(float a) {
  float c = cos(a);
  float s = sin(a);
  return float2x2(c, s, -s, c);
}

float sdBox(float3 p, float3 b) {
  float3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float box(float3 pos, float scale) {
  pos *= scale;
  float base = sdBox(pos, float3(0.4, 0.4, 0.1)) / 1.5;
  pos.xy *= 5.0;
  pos.y -= 3.5;
  pos.xy = mul(rot(0.75), pos.xy);
  float result = -base;
  return result;
}

float box_set(float3 pos, float currentTime) {
  float3 pos_origin = pos;

  pos = pos_origin;
  pos.y += sin(currentTime * 0.4) * 2.5;
  pos.xy = mul(rot(0.8), pos.xy);
  float box1 = box(pos, 2.0 - abs(sin(currentTime * 0.4)) * 1.5);

  pos = pos_origin;
  pos.y -= sin(currentTime * 0.4) * 2.5;
  pos.xy = mul(rot(0.8), pos.xy);
  float box2 = box(pos, 2.0 - abs(sin(currentTime * 0.4)) * 1.5);

  pos = pos_origin;
  pos.x += sin(currentTime * 0.4) * 2.5;
  pos.xy = mul(rot(0.8), pos.xy);
  float box3 = box(pos, 2.0 - abs(sin(currentTime * 0.4)) * 1.5);

  pos = pos_origin;
  pos.x -= sin(currentTime * 0.4) * 2.5;
  pos.xy = mul(rot(0.8), pos.xy);
  float box4 = box(pos, 2.0 - abs(sin(currentTime * 0.4)) * 1.5);

  pos = pos_origin;
  pos.xy = mul(rot(0.8), pos.xy);
  float box5 = box(pos, 0.5) * 6.0;

  pos = pos_origin;
  float box6 = box(pos, 0.5) * 6.0;

  float result = max(max(max(max(max(box1, box2), box3), box4), box5), box6);
  return result;
}

float map(float3 pos, float currentTime) {
  float3 pos_origin = pos;
  float box_set1 = box_set(pos, currentTime);
  return box_set1;
}

float4 mainImage(VertData v_in) : TARGET {
  float2 fragCoord = v_in.uv * uv_size;
  float2 p = (fragCoord.xy * 2.0 - uv_size.xy) / min(uv_size.x, uv_size.y);

  float3 ro = float3(0.0, -0.2, elapsed_time * 4.0);
  float3 ray = normalize(float3(p, 1.5));
  ray.xy = mul(rot(sin(elapsed_time * 0.03) * 5.0), ray.xy);
  ray.yz = mul(rot(sin(elapsed_time * 0.05) * 0.2), ray.yz);

  float t = 0.1;
  float3 col = float3(0.0, 0.0, 0.0);
  float ac = 0.0;

  for (int i = 0; i < 99; i++) {
    float3 pos = ro + ray * t;
    pos = mod_wrap(pos - 2.0, 4.0) - 2.0;
    float currentTime = elapsed_time - float(i) * 0.01;

    float d = map(pos, currentTime);
    d = max(abs(d), 0.01);
    ac += exp(-d * 23.0);
    t += d * 0.55;
  }

  col = float3(ac * 0.02, ac * 0.02, ac * 0.02);
  col += float3(0.0, 0.2 * abs(sin(elapsed_time)), 0.5 + sin(elapsed_time) * 0.2);

  return float4(col, 1.0 - t * (0.02 + 0.02 * sin(elapsed_time)));
}
