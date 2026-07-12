DefinitionBlock ("", "SSDT", 2, "RETBL", "X1605KBL", 0x00000001)
{
	/*
	 * ASUS Vivobook X1605ZA keyboard-backlight feature override.
	 *
	 * The factory ACPI NVS flag _SB.KBLC bit 7 indicates that a
	 * keyboard backlight is fitted. On non-backlit factory SKUs it is
	 * clear, even after a compatible backlit keyboard is installed.
	 *
	 * The stock DSDT uses this bit to gate both:
	 *   - DSTS(ASUS_WMI_DEVID_KBD_BACKLIGHT)
	 *   - EC query notifications for the keyboard-light hotkeys
	 *
	 * Set the bit during ACPI device initialization, before asus-wmi
	 * probes the ATKD WMI interface.
	 */
	External (\_SB.KBLC, FieldUnitObj)

	Scope (\_SB)
	{
		Device (KBLF)
		{
			Name (_HID, "RET0001")
			Name (_UID, One)

			Method (_STA, 0, NotSerialized)
			{
				Return (0x0F)
			}

			Method (_INI, 0, NotSerialized)
			{
				KBLC |= 0x80
			}
		}
	}
}
