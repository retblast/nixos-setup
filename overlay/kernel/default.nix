{
  prev,
}:
with prev.lib.kernel;
{
  # for scx
  BPF_JIT_ALWAYS_ON = prev.lib.mkForce yes;
  PROVE_LOCKING = yes;
  DEBUG_ATOMIC_SLEEP = yes;
  DEBUG_LOCKDEP = yes;

  # Zswap stuff
  ZSWAP_SHRINKER_DEFAULT_ON = yes;
  ZSMALLOC_STAT = yes;
  ZSMALLOC_CHAIN_SIZE = freeform "10";

  # mgLRU statistics support
  LRU_GEN_STATS = yes;

  # Compile optimized for this CPU
  X86_NATIVE_CPU = yes;

  # Extra zram stuff
  ZRAM_MEMORY_TRACKING = yes;
  ZRAM_TRACK_ENTRY_ACTIME = yes;

  # Module compression
  MODULE_COMPRESS_XZ = prev.lib.mkForce no;
  MODULE_COMPRESS_ZSTD = yes;

  # Hibernation compressor
  HIBERNATION_COMP_LZ4 = yes;
  HIBERNATION_DEF_COMP = freeform "lz4";

  # Number of supported CPUs
  NR_CPUS = prev.lib.mkForce (freeform "16");
}
// (import ./debloating {
  inherit prev;
})
