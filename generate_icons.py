#!/usr/bin/env python3

import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def create_function_icon(size):
    """Create a function icon similar to the SF Symbol 'function'"""
    # Create a new image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Calculate dimensions
    padding = size // 8
    icon_size = size - 2 * padding

    # Draw a rounded rectangle as the background
    rect_x1, rect_y1 = padding, padding
    rect_x2, rect_y2 = padding + icon_size, padding + icon_size
    draw.rounded_rectangle([rect_x1, rect_y1, rect_x2, rect_y2],
                         radius=size//10,
                         fill=(65, 105, 225, 255))  # Royal blue

    # Draw the function symbol (stylized 'f(x)')
    # We'll draw a simplified representation
    line_width = max(2, size // 20)

    # Draw a curve representing a function graph
    curve_points = []
    for i in range(icon_size - 20):
        x = rect_x1 + 10 + i
        # Simple sine wave
        y = rect_y1 + icon_size//2 + int(20 * np.sin(i * 0.1))
        curve_points.append((x, y))

    if len(curve_points) > 1:
        draw.line(curve_points, fill=(255, 255, 255, 255), width=line_width)

    # Draw some axis lines
    # Horizontal line (x-axis)
    draw.line([(rect_x1 + 5, rect_y1 + icon_size//2),
               (rect_x2 - 5, rect_y1 + icon_size//2)],
              fill=(255, 255, 255, 200), width=line_width//2)

    # Vertical line (y-axis)
    draw.line([(rect_x1 + icon_size//2, rect_y1 + 5),
               (rect_x1 + icon_size//2, rect_y2 - 5)],
              fill=(255, 255, 255, 200), width=line_width//2)

    return img

def main():
    # Create the AppIcon.appiconset directory if it doesn't exist
    iconset_dir = "Resources/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(iconset_dir, exist_ok=True)

    # Define the sizes we need for macOS app icons
    sizes = [
        (16, "AppIcon-16.png"),
        (32, "AppIcon-16@2x.png"),
        (32, "AppIcon-32.png"),
        (64, "AppIcon-32@2x.png"),
        (128, "AppIcon-128.png"),
        (256, "AppIcon-128@2x.png"),
        (256, "AppIcon-256.png"),
        (512, "AppIcon-256@2x.png"),
        (512, "AppIcon-512.png"),
        (1024, "AppIcon-512@2x.png")
    ]

    # Generate each icon size
    for size, filename in sizes:
        print(f"Creating {filename} ({size}x{size})...")
        icon = create_function_icon(size)
        icon.save(os.path.join(iconset_dir, filename))

    print("All icons generated successfully!")

if __name__ == "__main__":
    main()