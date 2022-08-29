# Starts Will's robot controller on Robox. Note that this should be copied to NPTL home directory on Robox so it can be called easily
# SDS June 2017
echo "Starting Kinova velocity controller..."
cd stanford-nptl-jaco-driver/position-controller
./build/position-controller&

# also start the python script that sends the robot's data back to Simulink
x-terminal-emulator -e python ~/code/peripheralCode/redisReader/sendRobotDataToXPC.py&
