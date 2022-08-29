function initializeRobot()
% Created 10 February 2017 by Sergey
% Initially cloned from cursor task (initializeCursor.m)
% but over time they will diverge. The robot-specific things should
% happen here.

global modelConstants;
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

global redisCon;
if isempty(redisCon)
    redisCon = redis();%'localhost', 6379);
end

global taskParams;
taskParams.handlerFun = @robotUpdateAfterEachXPCpacket;
switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        robotConstants % creates some global variables needed for robot.
       
        global screenParams;
        global isCursorShowing
        isCursorShowing= true;
        HideCursor();
        % not sure any of the above 4 lines needed -SDS
        % BJ: is HideCursor the thing that sends cursor to crazy
        % coordinates? 

        % Pre-setup that needs to happen on Robox:
        % 1.)
        % ~/kinova-jaco-driver/applications-linux/jaco6-driver-redis ./jaco6_driver
        % This puts into Torque Control and allows Redis communication
        % with the robot itself.
        % 2.) ~/scl-bmi/applications-linux/scl_redis_ctrl/sh runjaco.sh
        % This will compute torques based on velocity keys using
        % operation space control. This is derived from /applications-linux/___ within SCL.

        % These initializatons were for the SCL-torque control development
        % path. They are ignored by Will's position control code.        
        % Set 0 velocities before enabling torque control
        redisCon.set('scl::robot::kinovajaco6::traj::vgoal', sprintf('%0.4f %0.4f %0.4f', 0, 0, 0 ) );
        fprintf('Setting initial Kinova velocity to 0\n')
        % Allow torque control
        redisCon.set('scl::robot::kinovajaco6::fgc_command_enabled', sprintf('%.0f', 1 ) );
        fprintf('Enabling torque control 0\n')
        % Send robot to its home position
        redisCon.set('scl::robot::kinovajaco6::traj::xgoal', sprintf('%0.4f %0.4f %0.4f', ROBOT_HOME(1), ROBOT_HOME(2), ROBOT_HOME(3) ) );
        fprintf('Setting initial Kinova position to task-home (%.4f %.4f %.4f)\n', ROBOT_HOME(1), ROBOT_HOME(2), ROBOT_HOME(3))


    case EngineTypes.SOUND
        global soundParams;

        % use this sound for success
        l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/EC_go.wav'])';
        soundParams.successSound = l(1,:);
        % use the standard beep for Go
        soundParams.goSound = soundParams.beep;
        l=wavread(['~/' modelConstants.vizDir '/sounds/rigaudio/C#C_failure.wav'])';
        soundParams.failSound = l(1,:);
        soundParams.lastSoundTime = 0;

        %% tapping sound for over targets
        l=loadvar(['~/' modelConstants.vizDir '/sounds/tap.mat'],'sound');
        % scale down volume
        l = 1.2*l;
        soundParams.overSound = l(1,:);
end
