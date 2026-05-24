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
  # Old Intel SOF generations
  SND_SOC_SOF_APOLLOLAKE = prev.lib.mkForce no;
  SND_SOC_SOF_BAYTRAIL = prev.lib.mkForce no;
  SND_SOC_SOF_BROADWELL = prev.lib.mkForce no;
  SND_SOC_SOF_CANNONLAKE = prev.lib.mkForce no;
  SND_SOC_SOF_COFFEELAKE = prev.lib.mkForce no;
  SND_SOC_SOF_COMETLAKE = prev.lib.mkForce no;
  SND_SOC_SOF_ELKHARTLAKE = prev.lib.mkForce no;
  SND_SOC_SOF_GEMINILAKE = prev.lib.mkForce no;
  SND_SOC_SOF_ICELAKE = prev.lib.mkForce no;
  SND_SOC_SOF_JASPERLAKE = prev.lib.mkForce no;
  SND_SOC_SOF_MERRIFIELD = prev.lib.mkForce no;
  SND_SOC_SOF_SKYLAKE = prev.lib.mkForce no;
  SND_SOC_SOF_TIGERLAKE = prev.lib.mkForce no;

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
  # DRM Panels
  DRM_PANEL_RASPBERRYPI_TOUCHSCREEN = prev.lib.mkForce no;
  DRM_PANEL_RAYDIUM_RM67191 = prev.lib.mkForce no;
  DRM_PANEL_RAYDIUM_RM68200 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_ATNA33XC20 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_DB7430 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_LD9040 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_S6D16D0 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_S6E3HA2 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_S6E63J0X03 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_S6E88A0_AMS452EF01 = prev.lib.mkForce no;
  DRM_PANEL_SAMSUNG_SOFEF00 = prev.lib.mkForce no;
  DRM_PANEL_SEIKO_43WVF1G = prev.lib.mkForce no;
  DRM_PANEL_SHARP_LQ101R1SX01 = prev.lib.mkForce no;
  DRM_PANEL_SHARP_LS037V7DW01 = prev.lib.mkForce no;
  DRM_PANEL_SITRONIX_ST7701 = prev.lib.mkForce no;
  DRM_PANEL_SITRONIX_ST7789V = prev.lib.mkForce no;
  DRM_PANEL_SONY_ACX565AKM = prev.lib.mkForce no;
  DRM_PANEL_TDO_TL070WSH30 = prev.lib.mkForce no;
  DRM_PANEL_TPO_TD028TTEC1 = prev.lib.mkForce no;
  DRM_PANEL_TPO_TPG110 = prev.lib.mkForce no;
  DRM_PANEL_TRULY_NT35597_WQXGA = prev.lib.mkForce no;
  DRM_PANEL_VISIONOX_R66451 = prev.lib.mkForce no;
  DRM_PANEL_VISIONOX_RM69299 = prev.lib.mkForce no;

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
  # PMIC / regulator forests
  REGULATOR_88PG86X = prev.lib.mkForce no;
  REGULATOR_ACT8865 = prev.lib.mkForce no;
  REGULATOR_AD5398 = prev.lib.mkForce no;
  REGULATOR_AXP20X = prev.lib.mkForce no;
  REGULATOR_DA9121 = prev.lib.mkForce no;
  REGULATOR_FAN53555 = prev.lib.mkForce no;
  REGULATOR_GPIO = prev.lib.mkForce no;
  REGULATOR_HI6421 = prev.lib.mkForce no;
  REGULATOR_MAX14577 = prev.lib.mkForce no;
  REGULATOR_MAX1586 = prev.lib.mkForce no;
  REGULATOR_MAX77503 = prev.lib.mkForce no;
  REGULATOR_MAX77802 = prev.lib.mkForce no;
  REGULATOR_MP8859 = prev.lib.mkForce no;
  REGULATOR_MT6311 = prev.lib.mkForce no;
  REGULATOR_PCA9450 = prev.lib.mkForce no;
  REGULATOR_PFUZE100 = prev.lib.mkForce no;
  REGULATOR_QCOM_RPM = prev.lib.mkForce no;
  REGULATOR_RT4801 = prev.lib.mkForce no;
  REGULATOR_RTMV20 = prev.lib.mkForce no;
  REGULATOR_TPS51632 = prev.lib.mkForce no;

  # Charger / battery controller jungle
  BATTERY_BQ27XXX = prev.lib.mkForce no;
  CHARGER_ADP5061 = prev.lib.mkForce no;
  CHARGER_AXP20X = prev.lib.mkForce no;
  CHARGER_BQ2415X = prev.lib.mkForce no;
  CHARGER_BQ24190 = prev.lib.mkForce no;
  CHARGER_BQ24735 = prev.lib.mkForce no;
  CHARGER_BQ2515X = prev.lib.mkForce no;
  CHARGER_DA9150 = prev.lib.mkForce no;
  CHARGER_GPIO = prev.lib.mkForce no;
  CHARGER_LT3651 = prev.lib.mkForce no;
  CHARGER_MANAGER = prev.lib.mkForce no;
  CHARGER_MAX14577 = prev.lib.mkForce no;
  CHARGER_MAX77976 = prev.lib.mkForce no;
  CHARGER_MT6360 = prev.lib.mkForce no;
  CHARGER_QCOM_SMBB = prev.lib.mkForce no;
  CHARGER_RT9467 = prev.lib.mkForce no;
  CHARGER_SMB347 = prev.lib.mkForce no;
  CHARGER_SURFACE = prev.lib.mkForce no;

  # Microsoft Surface ecosystem
  SURFACE_3_POWER_OPREGION = prev.lib.mkForce no;
  SURFACE_ACPI_NOTIFY = prev.lib.mkForce no;
  SURFACE_AGGREGATOR = prev.lib.mkForce no;
  SURFACE_AGGREGATOR_BUS = prev.lib.mkForce no;
  SURFACE_AGGREGATOR_CDEV = prev.lib.mkForce no;
  SURFACE_AGGREGATOR_HUB = prev.lib.mkForce no;
  SURFACE_DTX = prev.lib.mkForce no;
  SURFACE_GPE = prev.lib.mkForce no;
  SURFACE_HID = prev.lib.mkForce no;
  SURFACE_HOTPLUG = prev.lib.mkForce no;
  SURFACE_KBD = prev.lib.mkForce no;
  SURFACE_PLATFORM_PROFILE = prev.lib.mkForce no;
  SURFACE_PRO3_BUTTON = prev.lib.mkForce no;
}
