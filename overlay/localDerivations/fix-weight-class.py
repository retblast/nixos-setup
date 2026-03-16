#!/usr/bin/env python3
import os
from pathlib import Path
from defcon import Font

# Weight class mapping based on standard naming
WEIGHT_CLASSES = {
    'Thin': 100,
    'Light': 300,
    'Regular': 400,
    'Medium': 500,
    'Bold': 700,
    'Black': 900
}

def add_weight_class_to_ufo(ufo_path):
    """Add openTypeOS2WeightClass to a UFO's fontinfo.plist"""
    font = Font(ufo_path)
    
    # Determine weight from filename
    ufo_name = Path(ufo_path).stem
    weight_class = 400  # default to Regular
    
    for weight_name, weight_value in WEIGHT_CLASSES.items():
        if weight_name in ufo_name:
            weight_class = weight_value
            break
    
    # Set weight class
    font.info.openTypeOS2WeightClass = weight_class
    print(f"  Set weight class to {weight_class}")
    font.save()

# Process all UFO files
for ufo in Path('.').glob('*.ufo'):
    print(f"Adding weight class to {ufo}")
    add_weight_class_to_ufo(str(ufo))
