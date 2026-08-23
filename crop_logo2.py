from PIL import Image

def crop_image(input_path, output_path):
    img = Image.open(input_path)
    width, height = img.size
    # Crop 25 pixels from all sides
    left = 25
    top = 25
    right = width - 25
    bottom = height - 25
    cropped = img.crop((left, top, right, bottom))
    cropped.save(output_path)
    print(f"Cropped image to {cropped.size} and saved to {output_path}")

original = '/Users/rushabhdesai/.gemini/antigravity/brain/f2613528-186f-4c31-81da-0b27fae6b4ff/media__1779555204380.png'
crop_image(original, 'assets/image/bamBamLogo.png')
crop_image(original, 'assets/image/bamabam_2.png')

icon_original = '/Users/rushabhdesai/.gemini/antigravity/brain/f2613528-186f-4c31-81da-0b27fae6b4ff/media__1779555234440.png'
crop_image(icon_original, 'assets/image/bam_bam_icon.png')
