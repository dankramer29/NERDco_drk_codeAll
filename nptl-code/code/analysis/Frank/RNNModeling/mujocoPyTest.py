import mujoco_py
import matplotlib.pyplot as plt
from os.path import dirname
import numpy as np

model = mujoco_py.load_model_from_path("/Users/frankwillett/Documents/mjpro150/model/arm_hand.xml")
sim = mujoco_py.MjSim(model,nsubsteps=10)
allPos = np.zeros([100,9])

for x in range(100):
	sim.step()
	allPos[x,0:3] = sim.data.get_body_xpos("upperarm")
	allPos[x,3:6] = sim.data.get_body_xpos("forearm")
	allPos[x,6:9] = sim.data.get_body_xpos("palm")

upperarm = allPos[:,0:3]
forearm = allPos[:,3:6]
palm = allPos[:,6:9]

plt.figure()
plt.plot(upperarm[:,0], upperarm[:,2],'o')
plt.plot(forearm[:,0], forearm[:,2],'o')
plt.plot(palm[:,0], palm[:,2],'o')
plt.axis('equal')
plt.show()