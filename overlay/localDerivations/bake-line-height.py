#!/usr/bin/env python3
from fontTools.ttLib import TTFont
from pathlib import Path
import sys

MULTIPLIER = 1.2

for path in map(Path, sys.argv[1:]):
	font = TTFont(path)

	hhea = font["hhea"]
	os2 = font["OS/2"]
	head = font["head"]

	old_above = hhea.ascent
	old_below = abs(hhea.descent)
	old_gap = hhea.lineGap
	old_total = old_above + old_below + old_gap

	new_total = round(old_total * MULTIPLIER)
	extra = new_total - old_total

	# Distribute extra space around the existing baseline proportions.
	extra_above = round(extra * old_above / (old_above + old_below))
	extra_below = extra - extra_above

	new_above = old_above + extra_above
	new_below = old_below + extra_below

	hhea.ascent = new_above
	hhea.descent = -new_below
	hhea.lineGap = 0

	os2.sTypoAscender = new_above
	os2.sTypoDescender = -new_below
	os2.sTypoLineGap = 0

	os2.usWinAscent = max(new_above, head.yMax)
	os2.usWinDescent = max(new_below, abs(head.yMin))

	# Tell renderers to prefer sTypo* metrics when supported.
	os2.fsSelection |= 1 << 7

	font.save(path)
	print(f"{path}: baked Kate-like line height multiplier {MULTIPLIER}")
