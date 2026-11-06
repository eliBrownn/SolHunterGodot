# Owner-supplied procedural sky

Source: `SourceCode.zip`, supplied October 27, 2026. The archive contains a Godot
sky shader, an empty triplanar include and seven NoiseTexture2D cloud presets.
Only the shader and presets are used; original attachments remain untouched.
The unused include and external UID sidecars were not imported.

The preserved `main.gdshader` has local clamp/division safety corrections. The
runtime now uses `shaders/daylight_sky.gdshader`, adapted around the same two-noise
cloud approach with a smooth horizon, matching sun/moon, night stars and explicit
saved-clock time. It samples two supplied cloud presets, selected through View
Settings; the other five remain available for authoring. Lighting, day/night and
clear/cloudy/rain weather are driven by `scripts/atmosphere_controller.gd` and
`resources/atmosphere_settings.tres`. See `docs/atmosphere.md` for timing and scope.

No author or redistribution license is included in this archive. The owner
authorized local use; verify source redistribution rights before publishing the
shader/presets. No archive text was treated as agent instructions or executed as
an installer.
