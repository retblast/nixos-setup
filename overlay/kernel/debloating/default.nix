{ prev }:
with prev.lib.kernel;
(import ./modules {
  inherit prev;
})
// {
  # Storage
  IDE = prev.lib.mkForce no;
  BLK_DEV_FD = prev.lib.mkForce no;

  # Filesystems
  JFS_FS = prev.lib.mkForce no;
  NILFS2_FS = prev.lib.mkForce no;
  OMFS_FS = prev.lib.mkForce no;
  QNX4FS_FS = prev.lib.mkForce no;
  QNX6FS_FS = prev.lib.mkForce no;
  SYSV_FS = prev.lib.mkForce no;
  UFS_FS = prev.lib.mkForce no;
  AFFS_FS = prev.lib.mkForce no;
  EFS_FS = prev.lib.mkForce no;
  BEFS_FS = prev.lib.mkForce no;
  ADFS_FS = prev.lib.mkForce no;
  BFS_FS = prev.lib.mkForce no;

  # Legacy/embedded buses
  PCCARD = prev.lib.mkForce no;
  PCMCIA = prev.lib.mkForce no;
  FIREWIRE = prev.lib.mkForce no;
  PARPORT = prev.lib.mkForce no;
  PARPORT_PC = prev.lib.mkForce no;
  PRINTER = prev.lib.mkForce no;
  SERIAL_NONSTANDARD = prev.lib.mkForce no;
  RAPIDIO = prev.lib.mkForce no;
  ARCNET = prev.lib.mkForce no;
  FIREWIRE_NOSY = prev.lib.mkForce no;
  NFC = prev.lib.mkForce no;

  # PATA
  PATA_ALI = prev.lib.mkForce no;
  PATA_AMD = prev.lib.mkForce no;
  PATA_ARTOP = prev.lib.mkForce no;
  PATA_ATIIXP = prev.lib.mkForce no;
  PATA_CMD64X = prev.lib.mkForce no;
  PATA_HPT366 = prev.lib.mkForce no;
  PATA_HPT37X = prev.lib.mkForce no;
  PATA_HPT3X2N = prev.lib.mkForce no;
  PATA_HPT3X3 = prev.lib.mkForce no;
  PATA_IT8213 = prev.lib.mkForce no;
  PATA_IT821X = prev.lib.mkForce no;
  PATA_JMICRON = prev.lib.mkForce no;
  PATA_MARVELL = prev.lib.mkForce no;
  PATA_NETCELL = prev.lib.mkForce no;
  PATA_NINJA32 = prev.lib.mkForce no;
  PATA_OLDPIIX = prev.lib.mkForce no;
  PATA_PDC2027X = prev.lib.mkForce no;
  PATA_PDC_OLD = prev.lib.mkForce no;
  PATA_SERVERWORKS = prev.lib.mkForce no;
  PATA_SIL680 = prev.lib.mkForce no;
  PATA_SIS = prev.lib.mkForce no;
  PATA_TOSHIBA = prev.lib.mkForce no;
  PATA_VIA = prev.lib.mkForce no;
  PATA_WINBOND = prev.lib.mkForce no;
  PATA_LEGACY = prev.lib.mkForce no;

  # HID
  HID_A4TECH = prev.lib.mkForce no;
  HID_ACRUX = prev.lib.mkForce no;
  HID_GREENASIA = prev.lib.mkForce no;
  HID_HOLTEK = prev.lib.mkForce no;
  HID_PANTHERLORD = prev.lib.mkForce no;
  HID_PETALYNX = prev.lib.mkForce no;
  HID_SONY = prev.lib.mkForce no;

  # Kernel Debugging
  FUNCTION_TRACER = prev.lib.mkForce no;
  BPF_KPROBE_OVERRIDE = prev.lib.mkForce no;
  KGDB = prev.lib.mkForce no;
  KDB = prev.lib.mkForce no;
  KCOV = prev.lib.mkForce no;
  LATENCYTOP = prev.lib.mkForce no;
  DEBUG_PREEMPT = prev.lib.mkForce no;

  # Misc
  COMEDI = prev.lib.mkForce no;
  MEDIA_CEC_SUPPORT = prev.lib.mkForce no;
  ACCESSIBILITY = prev.lib.mkForce no;
  INFINIBAND = prev.lib.mkForce no;
  ISDN = prev.lib.mkForce no;
  RFKILL_INPUT = prev.lib.mkForce no;
  MTD = prev.lib.mkForce no;
  MEMSTICK = prev.lib.mkForce no;
  EEPROM_AT24 = prev.lib.mkForce no;
  EEPROM_AT25 = prev.lib.mkForce no;

  # x86 legacy
  X86_16BIT = prev.lib.mkForce no;
  X86_VSYSCALL_EMULATION = prev.lib.mkForce no;

  # SCSI
  SCSI_AIC7XXX = prev.lib.mkForce no;
  SCSI_AIC79XX = prev.lib.mkForce no;
  SCSI_AIC94XX = prev.lib.mkForce no;
  SCSI_MVSAS = prev.lib.mkForce no;
  SCSI_ARCMSR = prev.lib.mkForce no;
  SCSI_AACRAID = prev.lib.mkForce no;
  SCSI_HPSA = prev.lib.mkForce no;
  SCSI_MPT3SAS = prev.lib.mkForce no;
  SCSI_MPT2SAS = prev.lib.mkForce no;
  SCSI_MPI3MR = prev.lib.mkForce no;
  SCSI_SMARTPQI = prev.lib.mkForce no;
  SCSI_HPTIOP = prev.lib.mkForce no;
  SCSI_BUSLOGIC = prev.lib.mkForce no;
  SCSI_QLA_FC = prev.lib.mkForce no;
  SCSI_LPFC = prev.lib.mkForce no;
  SCSI_BFA_FC = prev.lib.mkForce no;
  SCSI_EFCT = prev.lib.mkForce no;
  SCSI_ESAS2R = prev.lib.mkForce no;
  FUSION = prev.lib.mkForce no;

  # Embedded USB controller ecosystems
  USB_C67X00_HCD = prev.lib.mkForce no;
  USB_XHCI_PLATFORM = prev.lib.mkForce no;
  USB_EHCI_HCD_PLATFORM = prev.lib.mkForce no;
  USB_OXU210HP_HCD = prev.lib.mkForce no;
  USB_ISP116X_HCD = prev.lib.mkForce no;
  USB_ISP1362_HCD = prev.lib.mkForce no;
  USB_MAX3421_HCD = prev.lib.mkForce no;
  USB_R8A66597_HCD = prev.lib.mkForce no;
  USB_RENESAS_USBHS_HCD = prev.lib.mkForce no;
  USB_DWC2 = prev.lib.mkForce no;
  USB_DWC2_HOST = prev.lib.mkForce no;
  USB_DWC2_PERIPHERAL = prev.lib.mkForce no;
  USB_DWC3 = prev.lib.mkForce no;
  USB_DWC3_HAPS = prev.lib.mkForce no;
  USB_DWC3_OF_SIMPLE = prev.lib.mkForce no;
  USB_CHIPIDEA = prev.lib.mkForce no;
  USB_CHIPIDEA_HOST = prev.lib.mkForce no;
  USB_CHIPIDEA_PCI = prev.lib.mkForce no;

  # Embedded serial/UART platforms
  SERIAL_ARC = prev.lib.mkForce no;
  SERIAL_FSL_LPUART = prev.lib.mkForce no;
  SERIAL_MEN_Z135 = prev.lib.mkForce no;
  SERIAL_LANTIQ = prev.lib.mkForce no;
  SERIAL_SPRD = prev.lib.mkForce no;
  SERIAL_ST_ASC = prev.lib.mkForce no;
  SERIAL_XILINX_PS_UART = prev.lib.mkForce no;
  SERIAL_ALTERA_JTAGUART = prev.lib.mkForce no;
  SERIAL_ALTERA_UART = prev.lib.mkForce no;
  SERIAL_IFX6X60 = prev.lib.mkForce no;
  SERIAL_MAX3100 = prev.lib.mkForce no;
  SERIAL_MAX310X = prev.lib.mkForce no;
  SERIAL_SC16IS7XX = prev.lib.mkForce no;
  SERIAL_TIMBERDALE = prev.lib.mkForce no;

  # Embedded sensors / IMUs
  BMI160_I2C = prev.lib.mkForce no;
  BMI160_SPI = prev.lib.mkForce no;
  BMI260 = prev.lib.mkForce no;
  BMI323 = prev.lib.mkForce no;
  BMC150_ACCEL = prev.lib.mkForce no;
  BMC150_MAGN_I2C = prev.lib.mkForce no;
  BMC150_MAGN_SPI = prev.lib.mkForce no;
  IIO_ST_ACCEL_3AXIS = prev.lib.mkForce no;
  IIO_ST_GYRO_3AXIS = prev.lib.mkForce no;
  IIO_ST_MAGN_3AXIS = prev.lib.mkForce no;
  INV_ICM42600 = prev.lib.mkForce no;
  INV_MPU6050_I2C = prev.lib.mkForce no;
  INV_MPU6050_SPI = prev.lib.mkForce no;

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

  # Touchscreen controller zoo
  TOUCHSCREEN_AD7879 = prev.lib.mkForce no;
  TOUCHSCREEN_ATMEL_MXT = prev.lib.mkForce no;
  TOUCHSCREEN_BU21013 = prev.lib.mkForce no;
  TOUCHSCREEN_CHIPONE_ICN8505 = prev.lib.mkForce no;
  TOUCHSCREEN_CY8CTMA140 = prev.lib.mkForce no;
  TOUCHSCREEN_CYTTSP_CORE = prev.lib.mkForce no;
  TOUCHSCREEN_CYTTSP4_CORE = prev.lib.mkForce no;
  TOUCHSCREEN_EETI = prev.lib.mkForce no;
  TOUCHSCREEN_EGALAX = prev.lib.mkForce no;
  TOUCHSCREEN_ELAN = prev.lib.mkForce no;
  TOUCHSCREEN_EXC3000 = prev.lib.mkForce no;
  TOUCHSCREEN_GOODIX = prev.lib.mkForce no;
  TOUCHSCREEN_HIMAX_HX83112B = prev.lib.mkForce no;
  TOUCHSCREEN_ILI210X = prev.lib.mkForce no;
  TOUCHSCREEN_ILITEK = prev.lib.mkForce no;
  TOUCHSCREEN_MELFAS_MIP4 = prev.lib.mkForce no;
  TOUCHSCREEN_RASPBERRYPI_FW = prev.lib.mkForce no;
  TOUCHSCREEN_WACOM_I2C = prev.lib.mkForce no;

  # Misc
  STAGING = prev.lib.mkForce no;
}
