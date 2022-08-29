function flipTime = linuxSetupScreen(data)
global taskParams;

%% all the relevant info is in the "data" field of the packet, deconstruct it
taskParams.reinitializeScreen = true;

persistent prevClickState;
persistent velscalingWarning;

if isempty(prevClickState)
    prevClickState = 0;
end

persistent lastReceivedPacket;
persistent lastOutputPacket;
persistent HIDFID;
persistent integratedVelocity;
HIDFILENAME = '/tmp/hidMouse';
persistent eventBuffer;
if isempty(eventBuffer)
    eventBuffer = uint8(zeros(1, 24));
    velScalingWarning = false;
end


persistent armFID;

toPythonFILENAME = '/tmp/toPython';

persistent armEventBuffer; % bytes to python

if isempty(armEventBuffer)

    armEeventBuffer = uint8(zeros(1, 17));

	% first 8 bytes: x vel
	% second 8 bytes: y vel
	% last byte, click state

end

HACK_ARM_VEL_SCALING = 400;

switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        global screenParams;
        m.packetType = data.state;
        
        % Potential hack if you need to invert y more permanently ALEXA
%         data.cursorVelocity(2) = -1*data.cursorVelocity(2); 

        switch m.packetType
            case LinuxStates.STATE_INIT
            case LinuxStates.STATE_PAUSE
            case LinuxStates.STATE_FREE_RUN
                %disp(['Target Device: ' num2str(data.targetDevice)])
                %disp(['Cursor Pos: ', num2str(data.cursorPosition(1))])
                disp(['Cursor Vels: ', num2str(data.cursorVelocity(1))])
                switch data.targetDevice
                    case uint16(linuxConstants.DEVICE_LINUX)
                        %disp(sprintf('x:%g, y:%g', data.cursorPosition(1),data.cursorPosition(2)));
                        if any(data.outputVelocityScaling ~= 1) && ~velScalingWarning
                            disp('warning:outputVelocityScaling not implemented for DEVICE_LINUX');
                            velScalingWarning = true;
                        end
                        mouseControllerThreadless('SET',uint32(data.cursorPosition(1)+960),uint32(data.cursorPosition(2)+540));
                        if (prevClickState ~= uint16(DiscreteStates.CLICK_MAIN)) && ...
                                (data.clickState == uint16(DiscreteStates.CLICK_MAIN))
                            % mouse button down on click
                            mouseControllerThreadless('CLICK_MAIN',uint32(1));
                        elseif (prevClickState == uint16(DiscreteStates.CLICK_MAIN)) && ...
                                (data.clickState ~= uint16(DiscreteStates.CLICK_MAIN))
                            % release mouse button afterwards
                            mouseControllerThreadless('CLICK_MAIN',uint32(0));
                        end
                        prevClickState = data.clickState;
                    case uint16(linuxConstants.DEVICE_HIDCLIENT)
                        
                        %% initialize stuff
                        if isempty(HIDFID)
                            HIDFID = fopen(HIDFILENAME, 'a');
                        end
                        
                        if isempty(lastReceivedPacket) || data.clock < lastReceivedPacket
                            lastReceivedPacket = data.clock - 1;
                            integratedVelocity = zeros(2,1);
                            lastOutputPacket = data.clock-data.screenUpdateRate;
                        end
                        
                        %% check to make sure packet timestamps are reasonable (not dropping)
                        if data.clock-lastReceivedPacket ~= 1
                            fprintf('linuxSetupScreen: may be dropping packets: %i\n', data.clock-lastReceivedPacket);
                        end
                        lastReceivedPacket = data.clock;
                        
                        %% only send mouse velocity events at update rate
                        if lastReceivedPacket - lastOutputPacket >= data.screenUpdateRate
                            %% send out a packet
                            %fprintf('sending out a packet, X:%i, Y:%i\n',int32(integratedVelocity(1)), int32(integratedVelocity(2)));
                            % handle mouse X event
                            eventBuffer(17:18) = typecast(uint16(2), 'uint8'); % EV_REL
                            eventBuffer(19:20) = typecast(uint16(0), 'uint8'); % ABS_X
                            eventBuffer(21:24) = typecast(int32(integratedVelocity(1)), 'uint8');
                            
                            fwrite(HIDFID, eventBuffer); % write x movement
                            
                            % handle mouse Y event
                            eventBuffer(17:18) = typecast(uint16(2), 'uint8'); % EV_REL
                            eventBuffer(19:20) = typecast(uint16(1), 'uint8'); % ABS_Y
                            eventBuffer(21:24) = typecast(int32(integratedVelocity(2)), 'uint8');
                            
                            fwrite(HIDFID, eventBuffer); % write y movement
                            
                            lastOutputPacket = lastReceivedPacket;
                            integratedVelocity = integratedVelocity*0;
                        else
                            %% integrate velocities
                            integratedVelocity = integratedVelocity + data.cursorVelocity(:).*data.outputVelocityScaling(:);
                        end
                        
                        % click logic
                        
                        if (prevClickState ~= uint16(DiscreteStates.CLICK_MAIN)) && ...
                                (data.clickState == uint16(DiscreteStates.CLICK_MAIN))
                            % mouse button down on click
                            
                            %fprintf(1, 'click down!\n');
                            
                            eventBuffer(17:18) = typecast(uint16(1), 'uint8'); % EV_KEY
                            eventBuffer(19:20) = typecast(uint16(272), 'uint8'); % BTN_LEFT
                            eventBuffer(21:24) = typecast(int32(1), 'uint8');
                            
                            fwrite(HIDFID, eventBuffer); % write button down
                            
                            
                        elseif (prevClickState == uint16(DiscreteStates.CLICK_MAIN)) && ...
                                (data.clickState ~= uint16(DiscreteStates.CLICK_MAIN))
                            % release mouse button afterwards
                            
                            %fprintf(1, 'click up!\n');
                            
                            eventBuffer(17:18) = typecast(uint16(1), 'uint8'); % EV_KEY
                            eventBuffer(19:20) = typecast(uint16(272), 'uint8'); % BTN_LEFT
                            eventBuffer(21:24) = typecast(int32(0), 'uint8');
                            
                            fwrite(HIDFID, eventBuffer); % write button up
                            
                        end
                        prevClickState = data.clickState;

                    
                    case uint16(linuxConstants.DEVICE_ARM)

                        if any(data.outputVelocityScaling ~= 1) && ~velScalingWarning
                            disp('warning:outputVelocityScaling not implemented for DEVICE_ARM');
                            velScalingWarning = true;
                        end
                        
                        %% initialize stuff
                        if isempty(armFID)
                            armFID = fopen(toPythonFILENAME, 'a');
                        end
                        
                        if isempty(lastReceivedPacket) || data.clock < lastReceivedPacket
                            lastReceivedPacket = data.clock - 1;
                            integratedVelocity = zeros(2,1);
                            lastOutputPacket = data.clock-data.screenUpdateRate;
                        end

                        %% check to make sure packet timestamps are reasonable (not dropping)
                        if data.clock-lastReceivedPacket ~= 1
                            fprintf('armSetup: may be dropping packets: %i\n', data.clock-lastReceivedPacket);
                        end
                        lastReceivedPacket = data.clock;
                        
                        %% integrate velocities
                        integratedVelocity = integratedVelocity + data.cursorVelocity(:)*HACK_ARM_VEL_SCALING;
                        
                        %% only send mouse velocity events at update rate
                        if lastReceivedPacket - lastOutputPacket >= data.screenUpdateRate
                            armEventBuffer(01:08) = typecast( double( integratedVelocity(1) ), 'uint8' );
                            armEventBuffer(09:16) = typecast( double( integratedVelocity(2) ), 'uint8' );
                            armEventBuffer(17) = typecast( uint8(data.clickState), 'uint8');
                            
                            fwrite(armFID, armEventBuffer); % write packet
                            
                            lastOutputPacket = lastReceivedPacket;
                            integratedVelocity = integratedVelocity*0;
%                        else
                        end

                        % click logic
                        
                        if (prevClickState ~= uint16(DiscreteStates.CLICK_MAIN)) && ...
                                (data.clickState == uint16(DiscreteStates.CLICK_MAIN))
                            % mouse button down on click
                            
                           % armEventBuffer(19:20) = typecast(uint16(512), 'uint8');
                            
                           % fwrite(armFID, armEventBuffer); % write button down
                            
                            
                        elseif (prevClickState == uint16(DiscreteStates.CLICK_MAIN)) && ...
                                (data.clickState ~= uint16(DiscreteStates.CLICK_MAIN))
                            % release mouse button afterwards
                            
                           % armEventBuffer(19:20) = typecast(uint16(512), 'uint8');
                            
                           % fwrite(armFID, armEventBuffer); % write button up
                            
                        end
                        prevClickState = data.clickState;
                        
                        
                end
                
                
            case LinuxStates.STATE_END
                if data.targetDevice == uint16(linuxConstants.DEVICE_HIDCLIENT) && ~isempty(HIDFID)
                    fclose(HIDFID);
                end
                if data.targetDevice == uint16(linuxConstants.DEVICE_ARM) && ~isempty(toArmFID)
                    fclose(toArmFID);
                end
                taskParams.quit = true;
                initializeScreen();
                
        end
    case EngineTypes.SOUND
        global soundParams;
        if ~isfield(soundParams,'lastSoundTime')
            soundParams.lastSoundTime = data.lastSoundTime;
        end
        
        if data.lastSoundTime ~= soundParams.lastSoundTime
            soundParams.lastSoundTime = data.lastSoundTime;
            m.packetType = data.lastSoundState;
            switch m.packetType
                case LinuxStates.SOUND_STATE_CLICK
                        PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.clickSound);
                        PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
        
end
flipTime = GetSecs()-taskParams.startTime;
