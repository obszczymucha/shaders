from __future__ import annotations

import asyncio

try:
    import obsws_python as obs
except ImportError:
    obs = None

OBSWS_AVAILABLE = obs is not None


async def trigger_vendor_reload(
    host: str = "192.168.1.198",
    port: int = 4455,
    password: str | None = None,
    source_name: str = "Shader 3",
    filter_name: str = "Ring of Fire",
) -> bool | None:
    """Trigger reload using CallVendorRequest"""
    print("🔥 Triggering shader reload using CallVendorRequest...")

    if not obs:
        print("❌ obsws_python not available")
        return None

    try:
        client = obs.ReqClient(host=host, port=port, password=password)
        print("✅ Connected to OBS WebSocket")

        response = client.call_vendor_request(
            vendor_name="shader_filter",
            request_type="reload_effect",
            request_data={"sourceName": source_name, "filterName": filter_name},
        )

        print("🚀 Vendor request sent successfully!")
        print(f"📋 Response: {response}")

        # Handle response data safely
        response_data = getattr(response, "response_data", None)
        if response_data and response_data.get("success"):
            print("✅ Shader reload successful!")
            return True

        if response_data and response_data.get("error"):
            print(f"❌ Shader reload failed: {response_data['error']}")
            return False

        print("⚠️  Unknown response format")
        return None

    except (ConnectionError, OSError) as e:
        print(f"❌ Error: {e}")
        print(r"\nTroubleshooting:")
        print("1. Make sure OBS is running")
        print("2. Make sure obs-websocket plugin is installed and enabled")
        print("3. Make sure obs-shaderfilter plugin is loaded")
        print(f"4. Check source name '{source_name}' exists")
        print(f"5. Check filter name '{filter_name}' exists on that source")
        return None


async def main():
    print("=" * 60)
    print("🔥 OBS Shader Filter Vendor Reload Test")
    print("=" * 60)
    print("Using CallVendorRequest to shader_filter vendor")
    print("Target: Source 'Shader 3' → Filter 'Ring of Fire'")
    print()

    if OBSWS_AVAILABLE:
        await trigger_vendor_reload()
    else:
        print("❌ obsws_python not available")
        print(r"\nInstall with:")
        print("  pip install obsws-python")
        return

    print(r"\n" + "=" * 60)
    print("✨ Test completed!")
    print("Check OBS logs for vendor request messages")


if __name__ == "__main__":
    asyncio.run(main())
