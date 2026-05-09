{ prev }:
with prev.lib.kernel;
{
  # Virtualization extras
  XEN = prev.lib.mkForce no;
  XEN_NETDEV_FRONTEND = prev.lib.mkForce no;
  XEN_NETDEV_BACKEND = prev.lib.mkForce no;
  KVM_GUEST = prev.lib.mkForce no;
  INTEL_TDX_GUEST = prev.lib.mkForce no;
  ACRN_GUEST = prev.lib.mkForce no;
  BHYVE_GUEST = prev.lib.mkForce no;
  VMXNET3 = prev.lib.mkForce no;
  HYPERV_NET = prev.lib.mkForce no;
  VIRTIO_NET = prev.lib.mkForce no;
  PVH = prev.lib.mkForce no;
  PARAVIRT_CLOCK = prev.lib.mkForce no;
}
