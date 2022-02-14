# Must pip install pillow

from PIL import Image

wheel = Image.open('transparentwheel.png').convert("RGBA")
chassis = Image.open('fordraptorchassis.png').convert("RGBA")


width = (chassis.width - wheel.width) // 2
# Calculate height to be at the center
height = (chassis.height - wheel.height) // 2

# Resize the wheel image
basewidth=220
wpercent = (basewidth/float(wheel.size[0]))
hsize = int((float(wheel.size[1])*float(wpercent)))
wheel = wheel.resize((basewidth,hsize), Image.ANTIALIAS)

width1 = chassis.width//3 - 60
width2 = 2 * chassis.width//3 + 25
height = 540
# Paste the frontImage at (width, height)
chassis.paste(wheel, (width1, height), wheel)
chassis.paste(wheel, (width2, height), wheel)

# Save this image
chassis.save("newfordraptor.png", format="png")
