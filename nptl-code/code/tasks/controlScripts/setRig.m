function setRig(selection)

    global modelConstants;

    rigs = {'t6','t5','t8','t8medialonly','t9','t7','development','dev'};
	validRig = 0;
        commandLine = false;
        % skip selection if there's user-defined input
        if defined('selection')
            rigCmp = strcmp(selection, rigs);
            validRig = 1; commandLine = true; 
        end

	while ~validRig 
		selection = input('Please set participant [t5/t8/t9/dev]: ', 's');
                rigCmp = strcmp(selection, rigs);
		validRig = any(rigCmp);
		if ~validRig
			fprintf('ParticipantID incorrect. Please try again.\n');
		end
	end

        modelConstants.rig = rigs{rigCmp};

        %% set the NIC and array parameters
        switch modelConstants.rig
            case 't5'
                modelConstants.xpcNICConfig = xpcNICConfigWest();
                modelConstants.arrayConfig = arrayConfigT5();
                modelConstants.cerebus.cbmexVer = '60502';
                modelConstants.isSim = false;
            case 't6'
                modelConstants.xpcNICConfig = xpcNICConfigWest();
                modelConstants.arrayConfig = arrayConfigT6();
                modelConstants.cerebus.cbmexVer = '601';
                modelConstants.isSim = false;
%             case 't8'
%                 modelConstants.xpcNICConfig = xpcNICConfigWest();
%                 modelConstants.arrayConfig = arrayConfigT8();
%                 modelConstants.cerebus.cbmexVer = '603';
%                 modelConstants.arrayConfig.numArrays = 2;
%                 modelConstants.isSim = false;
            case {'t8','t8medialonly'}
                modelConstants.rig = 't8';
                modelConstants.xpcNICConfig = xpcNICConfigWest();
                modelConstants.arrayConfig = arrayConfigT8(3);
                modelConstants.cerebus.cbmexVer = '603';
                modelConstants.isSim = false;
            case 't9'
                modelConstants.xpcNICConfig = xpcNICConfigEast();
                modelConstants.arrayConfig = arrayConfigT9(1); %default config: array 1 is lateral, array 2 is medial
                modelConstants.cerebus.cbmexVer = '605';
                modelConstants.isSim = false;
            case 't7'
                modelConstants.xpcNICConfig = xpcNICConfigEast();
                modelConstants.arrayConfig = arrayConfigT7(1); %default config: array 1 is lateral, array 2 is medial
                modelConstants.cerebus.cbmexVer = '603';
                modelConstants.isSim = false;
            case {'development', 'dev'}
                modelConstants.rig = 't5';
                modelConstants.isSim = true;
                modelConstants.xpcNICConfig = xpcNICConfigWest();
                modelConstants.arrayConfig = arrayConfigT5(); %default config: array 1 is lateral, array 2 is medial
                modelConstants.cerebus.cbmexVer = '603';
        end
end