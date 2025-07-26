float3 mod_wrap(float3 x, float y) {
    return x - y * floor(x / y);
}

float sdf(float3 pos) {
    pos = mod_wrap(pos, 10.0);
    return length(pos - float3(5.0, 5.0, 5.0)) - 1.0;
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv * 2.0 - 1.0;
    uv.x *= uv_size.x / uv_size.y;

    float3 origin = float3(0.0, 5.0, 0.0) * elapsed_time;
    float angle = radians(elapsed_time * 3.0);
    float2x2 rot = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = mul(uv, rot);

    float3 ray_dir = float3(sin(uv.x), cos(uv.x) * cos(uv.y), sin(uv.y));
    float3 ray_pos = origin;
    float ray_length = 0.0;

    [unroll]
    for (int i = 0; i < 7; ++i) {
        float dist = sdf(ray_pos);
        ray_length += dist;
        ray_pos += ray_dir * dist;
        ray_dir = normalize(ray_dir + float3(uv.x, 0.0, uv.y) * dist * 0.3);
    }

    float d = sdf(ray_pos);
    float3 o = cos(float3(d, d, d) + float3(6.0, 0.0, 0.5));
    o *= smoothstep(38.0, 20.0, ray_length);

    return float4(o, 1.0);
}
