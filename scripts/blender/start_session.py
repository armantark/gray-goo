"""Enable the audited addon in a dedicated, temporary Blender profile."""
import addon_utils
import bpy

addon_utils.enable("blendermcp", default_set=True, persistent=True)
bpy.context.preferences.addons["blendermcp"].preferences.telemetry_consent = False
bpy.context.scene.blendermcp_auto_start_server = False
bpy.context.preferences.filepaths.save_version = 0
print("GRAY_GOO_BLENDER_READY telemetry=false")
