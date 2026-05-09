{ prev }:
with prev.lib.kernel;
{
  ## Multimedia (Graphics, sound, etc) modules
  # Sound
  SND_ISA = prev.lib.mkForce no;
  SND_SB16 = prev.lib.mkForce no;
  SND_OPL3 = prev.lib.mkForce no;
  SND_ADLIB = prev.lib.mkForce no;
  SND_SOC_INTEL_AVS = prev.lib.mkForce no;
  SND_SOC_AVS = prev.lib.mkForce no;
  SND_SOC_AMD_ACP = prev.lib.mkForce no;
  SND_SOC_SOF_AMD_TOPLEVEL = prev.lib.mkForce no;
  SND_AMD_ACP_CONFIG = prev.lib.mkForce no;
  SND_SOC_AMD_ACP_COMMON = prev.lib.mkForce no;
  SND_SOC_ACPI_AMD_MATCH = prev.lib.mkForce no;
  SND_AMD_SOUNDWIRE_ACPI = prev.lib.mkForce no;

  # DRM
  DRM_RADEON = prev.lib.mkForce no;
  DRM_AMDGPU = prev.lib.mkForce no;
  DRM_ACCEL_AMDXDNA = prev.lib.mkForce no;
  DRM_NOUVEAU = prev.lib.mkForce no;
  DRM_VMWGFX = prev.lib.mkForce no;
  DRM_QXL = prev.lib.mkForce no;
  DRM_VIRTIO_GPU = prev.lib.mkForce no;
  DRM_BOCHS = prev.lib.mkForce no;
  DRM_CIRRUS_QEMU = prev.lib.mkForce no;
  DRM_VGEM = prev.lib.mkForce no;
  DRM_VKMS = prev.lib.mkForce no;
  DRM_GMA500 = prev.lib.mkForce no;
  DRM_AST = prev.lib.mkForce no;
  DRM_MGAG200 = prev.lib.mkForce no;
  DRM_HYPERV = prev.lib.mkForce no;
  DRM_ACCEL_HABANALABS = prev.lib.mkForce no;
  DRM_ACCEL_QAIC = prev.lib.mkForce no;
  DRM_ACCEL_IVPU = prev.lib.mkForce no;

  # Media
  MEDIA_ANALOG_TV_SUPPORT = prev.lib.mkForce no;
  MEDIA_RADIO_SUPPORT = prev.lib.mkForce no;
  MEDIA_DIGITAL_TV_SUPPORT = prev.lib.mkForce no;
  MEDIA_TEST_SUPPORT = prev.lib.mkForce no;
  USB_GSPCA = prev.lib.mkForce no;
  VIDEO_EM28XX = prev.lib.mkForce no;
  VIDEO_CX231XX = prev.lib.mkForce no;
  VIDEO_AU0828 = prev.lib.mkForce no;
  MEDIA_PCI_SUPPORT = prev.lib.mkForce no;
  RC_CORE = prev.lib.mkForce no;
}
