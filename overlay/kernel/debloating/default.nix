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

  # Legacy buses
  PCCARD = prev.lib.mkForce no;
  PCMCIA = prev.lib.mkForce no;
  FIREWIRE = prev.lib.mkForce no;
  PARPORT = prev.lib.mkForce no;
  PARPORT_PC = prev.lib.mkForce no;
  PRINTER = prev.lib.mkForce no;
  SERIAL_NONSTANDARD = prev.lib.mkForce no;

  # HID
  HID_A4TECH = prev.lib.mkForce no;
  HID_ACRUX = prev.lib.mkForce no;
  HID_GREENASIA = prev.lib.mkForce no;
  HID_HOLTEK = prev.lib.mkForce no;
  HID_PANTHERLORD = prev.lib.mkForce no;
  HID_PETALYNX = prev.lib.mkForce no;
  HID_SONY = prev.lib.mkForce no;

  # Kernel Debugging
  KPROBES = prev.lib.mkForce no;
  UPROBES = prev.lib.mkForce no;
  FTRACE = prev.lib.mkForce no;
  FUNCTION_TRACER = prev.lib.mkForce no;
  BPF_KPROBE_OVERRIDE = prev.lib.mkForce no;
  KGDB = prev.lib.mkForce no;
  KDB = prev.lib.mkForce no;
  KCOV = prev.lib.mkForce no;
  LATENCYTOP = prev.lib.mkForce no;
  DEBUG_PREEMPT = prev.lib.mkForce no;
  SCHEDSTATS = prev.lib.mkForce no;

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

  # Misc
  STAGING = prev.lib.mkForce no;
}
