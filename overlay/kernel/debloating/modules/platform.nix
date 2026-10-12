{ prev }:
with prev.lib.kernel;
{
  ## Things related to platforms like CPU, SoC

  # AMD Things
  AMD_AE4DMA = prev.lib.mkForce no;
  AMD_PTDMA = prev.lib.mkForce no;
  AMD_QDMA = prev.lib.mkForce no;
  IOMMU_PT_AMDV1 = prev.lib.mkForce no;

  # PINCTL
  PINCTRL_AMD = prev.lib.mkForce no;
  PINCTRL_MCP23S08 = prev.lib.mkForce no;
  PINCTRL_SINGLE = prev.lib.mkForce no;
  PINCTRL_SX150X = prev.lib.mkForce no;
  PINCTRL_BAYTRAIL = prev.lib.mkForce no;
  PINCTRL_CHERRYVIEW = prev.lib.mkForce no;
  PINCTRL_BROXTON = prev.lib.mkForce no;
  PINCTRL_GEMINILAKE = prev.lib.mkForce no;
  PINCTRL_ICELAKE = prev.lib.mkForce no;
  PINCTRL_JASPERLAKE = prev.lib.mkForce no;
  # needed by things in Taihou
  PINCTRL_TIGERLAKE = prev.lib.mkForce yes;
  PINCTRL_CANNONLAKE = prev.lib.mkForce no;
  PINCTRL_CEDARFORK = prev.lib.mkForce no;
  PINCTRL_DENVERTON = prev.lib.mkForce no;
  PINCTRL_ELKHARTLAKE = prev.lib.mkForce no;
  PINCTRL_EMMITSBURG = prev.lib.mkForce no;
  PINCTRL_LEWISBURG = prev.lib.mkForce no;
  PINCTRL_SUNRISEPOINT = prev.lib.mkForce no;

  # Multi-Function Devices
  MFD_ACT8945A = prev.lib.mkForce no;
  MFD_AXP20X = prev.lib.mkForce no;
  MFD_DA9052_SPI = prev.lib.mkForce no;
  MFD_DA9052_I2C = prev.lib.mkForce no;
  MFD_MC13XXX = prev.lib.mkForce no;
  MFD_MAX14577 = prev.lib.mkForce no;
  MFD_MAX77693 = prev.lib.mkForce no;
  MFD_RK808 = prev.lib.mkForce no;
  MFD_RT4831 = prev.lib.mkForce no;
  MFD_SM501 = prev.lib.mkForce no;
  MFD_TPS65217 = prev.lib.mkForce no;
  MFD_WM8400 = prev.lib.mkForce no;

  # Laptop support
  EEPC_LAPTOP = prev.lib.mkForce no;
  ACER_WMI = prev.lib.mkForce no;
  ALIENWARE_WMI = prev.lib.mkForce no;
  HP_WMI = prev.lib.mkForce no;
  DELL_WMI = prev.lib.mkForce no;
  DELL_SMBIOS = prev.lib.mkForce no;
  THINKPAD_ACPI = prev.lib.mkForce no;
  SAMSUNG_LAPTOP = prev.lib.mkForce no;
  MSI_LAPTOP = prev.lib.mkForce no;
  LG_LAPTOP = prev.lib.mkForce no;
  HUAWEI_WMI = prev.lib.mkForce no;

  # AMD CPU frequency
  X86_AMD_PSTATE = prev.lib.mkForce no;

  # KVM for AMD (keep KVM_INTEL if you use VMs)
  KVM_AMD = prev.lib.mkForce no;
  KVM_AMD_SEV = prev.lib.mkForce no;

  # AMD power/perf stuff
  SENSORS_FAM15H_POWER = prev.lib.mkForce no;
  SENSORS_K8TEMP = prev.lib.mkForce no;
  SENSORS_K10TEMP = prev.lib.mkForce no;

  # AMD IOMMU (you have Intel IOMMU)
  AMD_IOMMU = prev.lib.mkForce no;
  AMD_IOMMU_V2 = prev.lib.mkForce no;

  # AMD ATL/EDAC
  AMD_ATL = prev.lib.mkForce no;

  # AMD uncore/node
  AMD_NB = prev.lib.mkForce no;
  AMD_NODE = prev.lib.mkForce no;

  # AMD SFH (sensor hub - AMD laptops only)
  AMD_SFH_HID = prev.lib.mkForce no;

  # AMD PMC/PMF (power management for AMD)
  AMD_PMC = prev.lib.mkForce no;
  AMD_PMF = prev.lib.mkForce no;
  AMD_3D_VCACHE = prev.lib.mkForce no;
  AMD_HFI = prev.lib.mkForce no;
  AMD_WBRF = prev.lib.mkForce no;
  AMD_ISP_PLATFORM = prev.lib.mkForce no;

  # AMD HSMP
  AMD_HSMP = prev.lib.mkForce no;

  # AMD crypto/CCP
  CRYPTO_DEV_CCP = prev.lib.mkForce no;
  CRYPTO_DEV_SP_CCP = prev.lib.mkForce no;
  CRYPTO_DEV_CCP_CRYPTO = prev.lib.mkForce no;
  CRYPTO_DEV_SP_PSP = prev.lib.mkForce no;

  # AMD EDAC
  EDAC_SKX = prev.lib.mkForce no; # Intel but worth checking

  # CPU - Intel only
  PROCESSOR_SELECT = yes;
  CPU_SUP_AMD = prev.lib.mkForce no;
  CPU_SUP_HYGON = prev.lib.mkForce no;
  CPU_SUP_CENTAUR = prev.lib.mkForce no;
  CPU_SUP_ZHAOXIN = prev.lib.mkForce no;
  X86_MCE_AMD = prev.lib.mkForce no;
  AMD_NUMA = prev.lib.mkForce no;
  AMD_MEM_ENCRYPT = prev.lib.mkForce no;
  PERF_EVENTS_AMD_POWER = prev.lib.mkForce no;
  PERF_EVENTS_AMD_UNCORE = prev.lib.mkForce no;
  PERF_EVENTS_AMD_BRS = prev.lib.mkForce no;

}
