uniform float4 borderColor;
uniform float2 scale;

float4 mainImage(VertData v_in) : TARGET
{
    // Check if we're in the border area
    if (v_in.uv.x < 0 || v_in.uv.x > 1 || v_in.uv.y < 0 || v_in.uv.y > 1)
    {
        // Normalize UV to center coordinates (-1 to 1)
        float2 p = v_in.uv * 2.0 - 1.0;
        p.x *= uv_size.x / uv_size.y; // Correct aspect ratio
        
        // Create 45-degree rotated gradient for shine (bottom-left to top-right)
        float diagonalPos = p.x - p.y; // Changed from + to - for correct direction
        
        // Animation: move the gradient from bottom-left to top-right
        float time = elapsed_time * 2.0;
        float gradientCenter = -3.0 + fmod(time, 6.0); // Sweep across larger area
        
        // Create the shine gradient
        float shineWidth = 0.3;
        float distToCenter = abs(diagonalPos - gradientCenter);
        float shine = exp(-distToCenter * distToCenter / (shineWidth * shineWidth));
        
        // Adjust shine intensity
        shine = smoothstep(0.0, 1.0, shine * 0.4);
        
        // Shine color (bright white/gold)
        float3 shineColor = float3(1.5, 1.2, 0.8);
        
        // Blend shine with border color
        float3 finalColor = borderColor.rgb + shineColor * shine;
        
        return float4(finalColor, borderColor.a);
    }
    else
    {
        // We're inside the image area - return normal image
        float2 scaledUV = float2(
            (v_in.uv.x - 0.5) * scale.x + 0.5,
            (v_in.uv.y - 0.5) * scale.y + 0.5
        );

        // Check if scaled UV is still within bounds
        if (scaledUV.x >= 0.0 && scaledUV.x <= 1.0 && scaledUV.y >= 0.0 && scaledUV.y <= 1.0)
        {
            return image.Sample(textureSampler, scaledUV);
        }
        else
        {
            return float4(0, 0, 0, 0); // Transparent gap
        }
    }
}
