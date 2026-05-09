{ prev }:
with prev.lib.kernel;
{

  # Networking
  ATM = prev.lib.mkForce no;
  LLC = prev.lib.mkForce no;
  LOWPAN = prev.lib.mkForce no;
  IEEE802154 = prev.lib.mkForce no;
  HAMRADIO = prev.lib.mkForce no;
  AX25 = prev.lib.mkForce no;
  NETROM = prev.lib.mkForce no;
  ROSE = prev.lib.mkForce no;
  SLIP = prev.lib.mkForce no;

  # NIC vendors
  NET_VENDOR_3COM = prev.lib.mkForce no;
  NET_VENDOR_DEC = prev.lib.mkForce no;
  NET_VENDOR_VIA = prev.lib.mkForce no;
  NET_VENDOR_ADAPTEC = prev.lib.mkForce no;
  NET_VENDOR_AGERE = prev.lib.mkForce no;
  NET_VENDOR_ALACRITECH = prev.lib.mkForce no;
  NET_VENDOR_ALTEON = prev.lib.mkForce no;
  NET_VENDOR_AMAZON = prev.lib.mkForce no;
  NET_VENDOR_AMD = prev.lib.mkForce no;
  NET_VENDOR_AQUANTIA = prev.lib.mkForce no;
  NET_VENDOR_ARC = prev.lib.mkForce no;
  NET_VENDOR_ATHEROS = prev.lib.mkForce no;
  NET_VENDOR_BROADCOM = prev.lib.mkForce no;
  NET_VENDOR_CADENCE = prev.lib.mkForce no;
  NET_VENDOR_CAVIUM = prev.lib.mkForce no;
  NET_VENDOR_CHELSIO = prev.lib.mkForce no;
  NET_VENDOR_CISCO = prev.lib.mkForce no;
  NET_VENDOR_CORTINA = prev.lib.mkForce no;
  NET_VENDOR_DAVICOM = prev.lib.mkForce no;
  NET_VENDOR_EMULEX = prev.lib.mkForce no;
  NET_VENDOR_ENGLEDER = prev.lib.mkForce no;
  NET_VENDOR_EZCHIP = prev.lib.mkForce no;
  NET_VENDOR_FUNGIBLE = prev.lib.mkForce no;
  NET_VENDOR_GOOGLE = prev.lib.mkForce no;
  NET_VENDOR_HISILICON = prev.lib.mkForce no;
  NET_VENDOR_HUAWEI = prev.lib.mkForce no;
  NET_VENDOR_I825XX = prev.lib.mkForce no;
  NET_VENDOR_ADI = prev.lib.mkForce no;
  NET_VENDOR_LITEX = prev.lib.mkForce no;
  NET_VENDOR_MARVELL = prev.lib.mkForce no;
  NET_VENDOR_MELLANOX = prev.lib.mkForce no;
  NET_VENDOR_META = prev.lib.mkForce no;
  NET_VENDOR_MICREL = prev.lib.mkForce no;
  NET_VENDOR_MICROCHIP = prev.lib.mkForce no;
  NET_VENDOR_MICROSEMI = prev.lib.mkForce no;
  NET_VENDOR_MICROSOFT = prev.lib.mkForce no;
  NET_VENDOR_MUCSE = prev.lib.mkForce no;
  NET_VENDOR_MYRI = prev.lib.mkForce no;
  NET_VENDOR_NI = prev.lib.mkForce no;
  NET_VENDOR_NATSEMI = prev.lib.mkForce no;
  NET_VENDOR_NETERION = prev.lib.mkForce no;
  NET_VENDOR_NETRONOME = prev.lib.mkForce no;
  NET_VENDOR_8390 = prev.lib.mkForce no;
  NET_VENDOR_NVIDIA = prev.lib.mkForce no;
  NET_VENDOR_OKI = prev.lib.mkForce no;
  NET_VENDOR_PACKET_ENGINES = prev.lib.mkForce no;
  NET_VENDOR_PENSANDO = prev.lib.mkForce no;
  NET_VENDOR_QLOGIC = prev.lib.mkForce no;
  NET_VENDOR_BROCADE = prev.lib.mkForce no;
  NET_VENDOR_QUALCOMM = prev.lib.mkForce no;
  NET_VENDOR_RDC = prev.lib.mkForce no;
  NET_VENDOR_RENESAS = prev.lib.mkForce no;
  NET_VENDOR_ROCKER = prev.lib.mkForce no;
  NET_VENDOR_SAMSUNG = prev.lib.mkForce no;
  NET_VENDOR_SEEQ = prev.lib.mkForce no;
  NET_VENDOR_SILAN = prev.lib.mkForce no;
  NET_VENDOR_SIS = prev.lib.mkForce no;
  NET_VENDOR_SOLARFLARE = prev.lib.mkForce no;
  NET_VENDOR_SOCIONEXT = prev.lib.mkForce no;
  NET_VENDOR_STMICRO = prev.lib.mkForce no;
  NET_VENDOR_SUN = prev.lib.mkForce no;
  NET_VENDOR_SYNOPSYS = prev.lib.mkForce no;
  NET_VENDOR_TEHUTI = prev.lib.mkForce no;
  NET_VENDOR_TI = prev.lib.mkForce no;
  NET_VENDOR_VERTEXCOM = prev.lib.mkForce no;
  NET_VENDOR_WANGXUN = prev.lib.mkForce no;
  NET_VENDOR_WIZNET = prev.lib.mkForce no;
  NET_VENDOR_XILINX = prev.lib.mkForce no;

  FDDI = prev.lib.mkForce no;
  HIPPI = prev.lib.mkForce no;
  CAN_DEV = prev.lib.mkForce no;

  # DSA
  B53 = prev.lib.mkForce no;
  NET_DSA_BCM_SF2 = prev.lib.mkForce no;
  NET_DSA_LOOP = prev.lib.mkForce no;
  NET_DSA_HIRSCHMANN_HELLCREEK = prev.lib.mkForce no;
  NET_DSA_MT7530 = prev.lib.mkForce no;
  NET_DSA_MV88E6XXX = prev.lib.mkForce no;
  NET_DSA_QCA8K = prev.lib.mkForce no;
  NET_DSA_XRS700X = prev.lib.mkForce no;
  NET_DSA_REALTEK = prev.lib.mkForce no;
  NET_DSA_SMSC_LAN9303 = prev.lib.mkForce no;

  # Wireless
  WLAN_VENDOR_ADMTEK = prev.lib.mkForce no;
  WLAN_VENDOR_ATMEL = prev.lib.mkForce no;
  WLAN_VENDOR_BROADCOM = prev.lib.mkForce no;
  IWLEGACY = prev.lib.mkForce no;
  WLAN_VENDOR_INTERSIL = prev.lib.mkForce no;
  LIBERTAS = prev.lib.mkForce no;
  LIBERTAS_THINFIRM = prev.lib.mkForce no;
  MWIFIEX = prev.lib.mkForce no;
  MWL8K = prev.lib.mkForce no;

  MT7601U = prev.lib.mkForce no;
  MT76x0_COMMON = prev.lib.mkForce no;
  MT76x0U = prev.lib.mkForce no;
  MT76x0E = prev.lib.mkForce no;
  MT76x2_COMMON = prev.lib.mkForce no;
  MT76x2E = prev.lib.mkForce no;
  MT76x2U = prev.lib.mkForce no;
  MT7603E = prev.lib.mkForce no;
  MT7615_COMMON = prev.lib.mkForce no;
  MT7615E = prev.lib.mkForce no;
  MT7663_USB_SDIO_COMMON = prev.lib.mkForce no;
  MT7663U = prev.lib.mkForce no;
  MT7663S = prev.lib.mkForce no;
  MT7915E = prev.lib.mkForce no;
  MT7921S = prev.lib.mkForce no;
  MT7921U = prev.lib.mkForce no;
  MT7996E = prev.lib.mkForce no;
  MT7925_COMMON = prev.lib.mkForce no;
  MT7925E = prev.lib.mkForce no;
  MT7925U = prev.lib.mkForce no;
  MT76_SDIO = prev.lib.mkForce no;

  WLAN_VENDOR_MICROCHIP = prev.lib.mkForce no;
  WLAN_VENDOR_RALINK = prev.lib.mkForce no;
  WLAN_VENDOR_RSI = prev.lib.mkForce no;
  WLAN_VENDOR_SILABS = prev.lib.mkForce no;
  WLAN_VENDOR_ST = prev.lib.mkForce no;
  WLAN_VENDOR_TI = prev.lib.mkForce no;
  WLAN_VENDOR_ZYDAS = prev.lib.mkForce no;
  WLAN_VENDOR_QUANTENNA = prev.lib.mkForce no;

  MAC80211_HWSIM = prev.lib.mkForce no;
  VIRT_WIFI = prev.lib.mkForce no;
  WWAN = prev.lib.mkForce no;

  # Bluetooth
  BT_HCIBCM4377 = prev.lib.mkForce no;
  BT_HCIVHCI = prev.lib.mkForce no;
  BT_MRVL = prev.lib.mkForce no;
  BT_ATH3K = prev.lib.mkForce no;
  BT_QCOMSMD = prev.lib.mkForce no;
  BT_QCA = prev.lib.mkForce no;
  BT_HCIBFUSB = prev.lib.mkForce no;
  BT_HCIBPA10X = prev.lib.mkForce no;
  BT_HCIBCM203X = prev.lib.mkForce no;
  BT_HCIBLUECARD = prev.lib.mkForce no;
  BT_HCIBTUART = prev.lib.mkForce no;
  BT_HCIDTL1 = prev.lib.mkForce no;
  BT_HCIBT3C = prev.lib.mkForce no;
  BT_HCIUART = prev.lib.mkForce no;
}
