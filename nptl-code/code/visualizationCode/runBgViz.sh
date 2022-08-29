#!/bin/bash
## to let both machines use the same license file
#sudo ifconfig eth1 hw ether 80:ee:73:13:c2:33 # debug 12/7/2017 trying without this
##sudo ifconfig eth1 hw ether 80:ee:73:13:c0:6b
## FOR T7 Sessions, comment second line, change first line to eth1.
sudo ifconfig enp0s31f6 hw ether 4C:BB:58:D3:0A:69
#export DISPLAY=:0
export DISPLAY=:1
#export DISPLAY=:2

sudo /usr/local/MATLAB/R2014b/bin/matlab -nodesktop -nosplash -r "addpath('/home/nptl/code/visualizationCode/'); runBgViz"
#sudo /usr/local/MATLAB/R2012b/bin/matlab -nodesktop -nosplash -r "addpath('/home/nptl/code/visualizationCode/'); runBgViz"
#export DISPLAY=:1
#sudo /usr/local/MATLAB/R2014b/bin/matlab -nodesktop -nosplash -r "addpath('/home/nptl/code/visualizationCode/'); cd('/home/nptl/code/visualizationCode/'); runBgViz"

