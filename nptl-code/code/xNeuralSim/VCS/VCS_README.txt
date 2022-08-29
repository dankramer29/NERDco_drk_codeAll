VCS README
created by Dan Bacher, 2010

BRIEF DESCRIPTION:
VCS is a "Velocity Control Simulator".  It is a simple matlab program that 
captures mouse position and encoded a unique pattern of neural activity based 
on that mouse position.  Behind the scenes there are "virtual neurons" located
at the corners of the screen.  96 channels are broken up into banks of neurons
located at these corners.  Each neuron is linearly tuned to the distance the 
mouse cursor is from it's particular corner.  So, for example, for a fake neuron
tuned 45 deg (up and right), if the cursor is in the upper right corner, it 
fires at its maximum rate, if the cursor were in the upper left or lower right,
it would fire at baseline, and if the cursor is in lower left it would fire
below baseline.  Also, if you click the mouse, a unique "click pattern" is 
generated across 96 channels.  

SETUP:
- use VCS on a laptop with matlab
- connect the laptop to the cart network
- set a static IP on the laptop to 192.168.137.x, where x is greater than 4
	(I for some reason use 192.168.137.8)
- in matlab move to the VCS directory, or add directory to your path

USE:
run VCS.m
- move your mouse to match the velocity of the cursor (not position)
	i.e. for a rightward cursor movement, you would start with your mouse
	     in the center of the screen, move right and reach the right
	     when the cursor hits its max velocity, and move back to center
             as the cursor is coming to a stop
- click a couple times during a click instruction