from PIL import Image

def crop_image(input_path, output_path):
    img = Image.open(input_path)
    # The image is 290x282. The border is on the left and right edges.
    # Let's crop 15 pixels from left, 15 from right, 5 from top, 5 from bottom
    width, height = img.size
    left = 15
    top = 5
    right = width - 15
    bottom = height - 5
    cropped = img.crop((left, top, right, bottom))
    cropped.save(output_path)
    print(f"Cropped image saved to {output_path}")

crop_image('assets/image/bamBamLogo.png', 'assets/image/bamBamLogo.png')
crop_image('assets/image/bamabam_2.png', 'assets/image/bamabam_2.png')
