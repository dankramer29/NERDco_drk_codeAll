#!/bin/bash

sudo killall MATLAB


#export DISPLAY=:0
export DISPLAY=:1
#export DISPLAY=:2

# note -iconic so out of sight. Remove that flag when you want to debug
xterm -geometry 100x30-0-0 -iconic -e "sh /home/nptl/code/visualizationCode/runBgViz.sh; read -n1" &   
#xterm -geometry 100x30-0-0 -e "sh /home/nptl/code/visualizationCode/runBgViz.sh; read -n1" &   
#SPAWNED=$!
#disown -h $SPAWNED

xterm -geometry 100x30-0-0 -iconic -e "sh /home/nptl/code/visualizationCode/runBgSound.sh; read -n1" &
#xterm -geometry 100x30-0-0 -e "sh /home/nptl/code/visualizationCode/runBgSound.sh; read -n1" &

#SPAWNED=$!
#disown -h $SPAWNED

## move the mouse to the bottom right corner
xdotool mousemove 1920 1280