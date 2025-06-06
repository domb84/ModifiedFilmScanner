#!/usr/bin/python3

import sys
import cv2
import time
import numpy as np

from hdr_capture import HDRCapture
from HR8825 import HR8825
from threading import Thread


# Wolverine stepper motor
Motor1 = HR8825(dir_pin=13, step_pin=19, enable_pin=12, mode_pins=(16, 17, 20))
Motor1.SetMicroStep('hardward' ,'1/32step')

# Start the HDR capture thread
hdr = HDRCapture()
hdr.start()

def next_frame():
	# Move to next frame
	Motor1.TurnStep(Dir='forward', steps=50 * 32, stepdelay=0.000005)
	Motor1.Stop()
	# Motion settle time + camera queue process time
	time.sleep(0.4)
	

# Your code here; capture the film
for frame in range(int(sys.argv[1])):
	
	print(time.time())
	
	# Get multi exposured images
	images = hdr.get_images()
	
	x = Thread(target=next_frame)
	x.start()
	
	mm = False
	if mm == False:
		# Save individually exposed images
		print(f'- Saving separate jpeg images...')
		cv2.imwrite(f'output/film01_frame{frame}(0)EV-1.jpg', images[0])
		cv2.imwrite(f'output/film01_frame{frame}(1)EV-0.jpg', images[1])
		cv2.imwrite(f'output/film01_frame{frame}(2)EV+1.jpg', images[2])
		cv2.imwrite(f'output/film01_frame{frame}(3)EV+2.jpg', images[3])
	else:
		# Mertens merge images
		print(f'- mertens merge...')
		merge = cv2.createMergeMertens()
		merged = merge.process(images)
		# Normalize the image to 0.0 .. 1.0
		merged = cv2.normalize(merged, None, 0., 1., cv2.NORM_MINMAX)
		# Convert to 8bit
		merged = np.clip(merged * 255, 0, 255).astype(np.uint8)
		# Write to file
		cv2.imwrite(f'output/film01_frame{frame}.jpg', merged)

	x.join()

	print(f'- done')
	

hdr.stop()
hdr.join()