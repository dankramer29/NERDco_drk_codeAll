%% screen vizualization enumerated type NEW FOR VIZ
classdef (Enumeration) cursorConstants < Simulink.IntEnumType
    enumeration
        % Cursor task variants. Use same code-base but there are
        % conditional statements throughout that execute differently
        % depending on the task mode
        TASK_CENTER_OUT(1)
        TASK_PINBALL(2)
        TASK_NEURAL_OUT_MOTOR_BACK(3)
        TASK_CENTER_OUT_NO_BACK(4)
        TASK_GRIDLIKE(5) % N dimensional grid task logic 
        TASK_NOTARGETS(6) % free explore, no targets added SDS Feb 2017
        TASK_RANDOM(7) % N dimesnional, targets appear in random location within workspace boundaries.
                       % target size is chosen from the specified
                       % targetDiameter multiplied by a random multiplier 
                       % from the list randomTaskSizeMultipliers
        TASK_RAYS(8)   % Radial Angle Yolked Selection. Targets appear as specified, but when 
                       % cursor is further than 0.5*target_diameter away
                       % from the origin, a selection is made based on
                       % which target's vector angle the current cursor
                       % coordinate is closest too. 
                       %
                       % Sergey April 2017
        TASK_FCC(9)    % High-D keyboard. Spatial target is determined by closest 
                       % target. Radial target is selected by clsoest
                       % radial coordinate.
                       % Sergey May 2017
        TASK_SEQ(10) %FRW Movement sequence task
        TASK_MULTICLICK(11) %SNF for multiclick. 
        TASK_HEAD_REPORT(12) %SNF for DM
        TASK_BCI_REPORT(13) %SNF for DM. This was previously 11 but I don't think it's used so I swapped it so multiclick could stay 11
        
        %% just need these to bound memory usage, increase if we'll ever do larger blocks
        MAX_TARGETS(140) % 
        MAX_DIAMETERS(10); % determines size of randomTaskTargetDiameters and randomTaskTargetRotDiameters
        MAX_TILES_PER_DIM(10) % Used to preallocate matrix of edges for each dimension of grid-like task. SDS Dec 2016
                              % Increase if working in lower D and planning
                              % on a denser grid.
        NUM_DIMENSIONS(5) % dimensionality of the cursor task. . Made 5 from 4 on March 10 2017
        MAX_CLICK_DIMS(1) %SNF for multiclick - probably don't need it to be 5 b
        INPUT_TYPE_MOUSE_RELATIVE(1)
        INPUT_TYPE_THUMB_INDEX_POS_TO_POS(2)
        INPUT_TYPE_IMU_POS_TO_POS(3)
        INPUT_TYPE_IMU_POS_TO_VEL(4)
        INPUT_TYPE_INDEX_IMU_POS_TO_VEL(5)
        INPUT_TYPE_THUMB_INDEX_POS_TO_VEL(6)
        INPUT_TYPE_INDEX_IMU_POS_TO_POS(7)
        INPUT_TYPE_MOUSE_ABSOLUTE(8)
        INPUT_TYPE_DECODE_V(9)
        INPUT_TYPE_AUTO_PLAY(10)
        INPUT_TYPE_AUTO_ACQUIRE(11)
        INPUT_TYPE_NONE(12)
        INPUT_TYPE_HEAD_MOUSE(13)
        INPUT_TYPE_HEAD_CURSORSTILL(14)
        INPUT_TYPE_CURSOR_HEADSTILL(15)
        INPUT_TYPE_CURSOR_AND_HEAD(16)
        INPUT_TYPE_AUTO_ACQUIRE_HS(17) %head still
        INPUT_TYPE_WIA_HEAD(18) %all wia conditions combined in a single block
        
        TARGET_TYPE_DWELL(1)
        TARGET_TYPE_CLICK(2)
        TARGET_TYPE_LCLICK(3) % SNF multiclick                                                                                                                       -
        TARGET_TYPE_RCLICK(4) % SNF multiclick                                                                                                                       -
        TARGET_TYPE_2CLICK(5) % SNF multiclick                                                                                                                       -
        TARGET_TYPE_SCLICK(6) % SNF multiclick
        OUTPUT_TYPE_CURSOR(1) % old PsychToolbox cursor
        OUTPUT_TYPE_ROBOT(2) % physical or simulated robot arm endpoint
        OUTPUT_TYPE_SCLCURSOR(3) % cursor rendered in SCL SDS Nov 3 2016
        
        % Vizualization objects - can be used to toggle different graphical
        % representations of the cursor on the display side
        OBJECT_SPHERE(1)
        OBJECT_ROD(2)    % has a "bulge" to give it a polarity. Vertical orientation.
        OBJECT_HAMMER(3) % "T" with "handle" horizontal by default
        
        %WIA EXPERIMENTS
        WIA_NOT_ACTIVE(1)
        WIA_IMAGINE_ONLY(2)
        WIA_WATCH_IMAGINE_ATTEMPT(3)
        WIA_WATCH_ONLY(4)
        WIA_DO_ONLY(5)
        WIA_IMAGINE_ONLY_NO_HC(6) %no head cursor visible
        
        %YANG
        YANG_NUM_TASKS(20)
        YANG_NUM_TARGETS(4)
        
        %BACKGROUNDS (SET VIA displayObject parameter)
        BACKGROUND_QUAD_CARDINAL(10)
        BACKGROUND_QUAD_JOINTS(11)
        BACKGROUND_QUAD_CARDINAL_JOINTS(12)
        BACKGROUND_DUAL_JOYSTICK(13)
        BACKGROUND_QUAD_CARDINAL_CLOSER(14)
    end
end