#!/usr/bin/python
# Uses the Pillow fork of Python Imaging Library (PIL) - http://python-pillow.org/ 
#
# On Windows - 
#		Install Python 2.7
# 		Download ez_setup.py from https://bootstrap.pypa.io/ez_setup.py to C:\Python27
# 		run ez_setup.py
# 		From the \Python27\Scripts folder, run easy_install.exe pillow
# 
# On Mac -
#       pip install Pillow
#

# Convert image to bitmap for use with BBC Micro

import sys


import gzip
import struct
import sys
import binascii
import math
import json
import os
import PIL

from PIL import Image
import PIL.ImageOps  

def quantizetopalette(silf, palette, dither=False):
    """Convert an RGB or L mode image to use a given P image's palette."""

    silf.load()

    # use palette from reference image
    palette.load()
    if palette.mode != "P":
        raise ValueError("bad mode for palette image")
    if silf.mode != "RGB" and silf.mode != "L":
        raise ValueError(
            "only RGB or L mode images can be quantized to a palette"
            )
    im = silf.im.convert("P", 1 if dither else 0, palette.im)
    # the 0 above means turn OFF dithering
    return silf._makeself(im)

if len(sys.argv) != 3:
    print "img2bitmap.py <infile> <outfile>"
    exit()

infile = sys.argv[1]
outfile = sys.argv[2]

print "converting " + infile + " to " + outfile


img = Image.open(infile)					
iw = img.size[0]
ih = img.size[1]	


print "image w=" + str(iw) + " h=" + str(ih)


option_scale = 0
option_width = 32
option_height = 32
option_square = 1
option_pad = 0
option_palette = 1






# force image to be square and/or padded
if option_square != 0 or option_pad != 0:

    rw = iw
    rh = ih

    pad_x = 0
    pad_y = 0
    if option_pad != 0:
        #print "n"

        pad_x = (option_pad * rw / 100) * 2
        pad_y = (option_pad * rh / 100) * 2
        #print "image w=" + str(rw) + " h=" + str(rh) + " padx=" + str(pad_x) + " pady=" + str(pad_y)
        rw += pad_x
        rh += pad_y
        #print "new image w=" + str(rw) + " h=" + str(rh) + " padx=" + str(pad_x) + " pady=" + str(pad_y)
        #xoffset += pad_x / 2
        #yoffset += pad_y / 2
    
    if option_square != 0 and rw != rh:
        print "do squaring"
        if rw > rh:
            pad_y += (rw - rh)
            rh = rw
            print "square image w=" + str(rw) + " h=" + str(rh) + " padx=" + str(pad_x) + " pady=" + str(pad_y)
            #print "a"
        else:	
            pad_x += (rh - rw)
            rw = rh
            print "square image w=" + str(rw) + " h=" + str(rh) + " padx=" + str(pad_x) + " pady=" + str(pad_y)
            #print "b"
    
    xoffset = pad_x / 2
    yoffset = pad_y / 2


        

    
    #print "square to " + str(rw) + " x " + str(rh) + " xoff=" + str(xoffset) + " yoff=" + str(yoffset)
    
    # create a new blank canvas at the target size and copy the original image to its centre
    #c = img.getpixel((0,0))	# use the top left colour of the image as the bg color
    c = (0,0,0,0) # use transparent colour as the pad bg color
    newimg = Image.new('RGBA', (rw, rh), c) 
    newimg.paste(img, (xoffset, yoffset, xoffset+iw, yoffset+ih) )
    img = newimg
    
    iw = img.size[0]
    ih = img.size[1]		

# apply image scaling - scale, width or height
scale_ratio_x = 1.0
scale_ratio_y = 1.0

if option_scale != 0:
    scale_ratio_x = scale_ratio_y = float(option_scale) / 100.0
else:	
    if option_width != 0 and option_height == 0:
        scale_ratio_x = scale_ratio_y = float(option_width) / float(iw)
    else:	
        if option_width == 0 and option_height != 0:
            scale_ratio_x = scale_ratio_y = float(option_height) / float(ih)
        else:
            if option_width !=0 and option_height != 0:
                scale_ratio_x = float(option_width) / float(iw)
                scale_ratio_y = float(option_height) / float(ih)
                
#print "scale ratio x=" + str(scale_ratio_x) + " y=" + str(scale_ratio_y)


# apply image scaling - scale, width or height
ow = iw
oh = ih
if scale_ratio_x != 1.0 or scale_ratio_y != 1.0:
    ow = int( round( float(iw) * scale_ratio_x ) )
    oh = int( round( float(ih) * scale_ratio_y ) )
    

# we only handle retina for images that are being resized
if ow != iw or oh != ih:
    print "resizing image w=" + str(ow) + " h=" + str(oh)
    
    # resample the image to target size
    img = img.resize((ow, oh), PIL.Image.ANTIALIAS)						

# save the processed image
if option_palette != 0:
    print "quantizing"
    pal_image= Image.new("P", (1,1))
    pal_image.putpalette( (0,0,0, 255,0,0, 0,255,0, 255,255,0, 0,0,255, 255,0,255, 0,255,255, 255,255,255) + (0,0,0)*248)
#    pal_image.putpalette( (0,0,255, 255,0,0, 0,255,0, 255,255,0, 0,0,255, 255,0,255, 0,255,255, 255,255,255) + (0,0,255)*248)

    #img = img.convert("RGB").quantize(colors=8,palette=pal_image)		
    img = quantizetopalette(img.convert("RGB"), pal_image, dither=False)				

img.save("test.png", "png")


for y in range(0,oh):
    s = "EQUB "
    for x in range(0,ow):
        s += str( 144+img.getpixel( (x,y) ) ) 
        if x < ow-1:
            s += ","

    print s


print "Done."
