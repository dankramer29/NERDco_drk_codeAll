%load('/Users/frankwillett/Downloads/noiseHardened_sphere_0.mat')
load('/Users/frankwillett/osim4d_sphere_0.mat')
addpath('/Users/frankwillett/Downloads/CaptureFigVid/CaptureFigVid/')

%pos = envState(:,[24 25 26]);
pos = envState(:,[10,11,12]);
targ = controllerInputs(:,1:3);
targList = unique(targ, 'rows');
plotIdx = 2:2:(length(trialStartIdx)-1);

figure;
hold on;
for trlIdx=1:length(plotIdx)
    loopIdx = trialStartIdx(plotIdx(trlIdx)):trialStartIdx(plotIdx(trlIdx)+1);
    plot3(pos(loopIdx,1), pos(loopIdx,2), pos(loopIdx,3), 'LineWidth', 2.0);
end
plot3(targList(:,1), targList(:,2), targList(:,3), 'ro');
%for targIdx=1:size(targList,1)
%    plot3([0.21,targList(targIdx,1)], [0,targList(targIdx,2)], [0.24,targList(targIdx,3)], ':', 'LineWidth', 2.0);
%end
axis equal;

OptionZ.FrameRate=15;OptionZ.Duration=5.5;OptionZ.Periodic=true;
CaptureFigVid([0,10;-360,10], 'noiseHardened',OptionZ)

%single-factor
outerIdx = 2:2:(length(trialStartIdx)-1);
targ = controllerInputs(trialStartIdx(outerIdx)+3,1:3);
[targList, ~, targCodes] = unique(targ, 'rows');

dPCA_out = apply_dPCA_simple( squeeze(rnnState), trialStartIdx(outerIdx), ...
    targCodes, [-25,150], 0.010, {'CD','CI'} );
lineArgs = cell(length(targList),1);
colors = jet(length(lineArgs))*0.8;
for l=1:length(lineArgs)
    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
end
oneFactor_dPCA_plot( dPCA_out,  -25:150, lineArgs, {'CD','CI'}, 'sameAxes');

%%
load('/Users/frankwillett/osim4d_sphere_0.mat')

joints = zeros(length(envState),7);
joints(:,1:4) = envState(:,[13,14,15,16]);
joints(:,5:7) = repmat([-5.36, 6.45, 1.39],length(joints),1);
timeStep = 0:0.01:size(joints,1)*0.01;

format = '%f';
for x=1:size(joints,2)
    format = [format, ' %f'];
end
format = [format, '\n'];

fid = fopen('motionSequence.sto','w');
fprintf(fid, 'inverse kinematics\n');
fprintf(fid, 'nRows=%d\n', size(joints,1));
fprintf(fid, 'nColumns=%d\n', size(joints,2)+1);
fprintf(fid, '\n');
fprintf(fid, '# SIMM Motion File Header:\n');
fprintf(fid, 'name inverse kinematics\n');
fprintf(fid, 'datacolumns %d\n', size(joints,2)+1);
fprintf(fid, 'datarows %d\n', size(joints,1));
fprintf(fid, 'otherdata %d\n', 1);
fprintf(fid, 'range %f %f\n', [timeStep(1), timeStep(end)]);
fprintf(fid, 'endheader\n');

fprintf(fid, 'time elv_angle shoulder_elv shoulder_rot elbow_flexion pro_sup deviation flexion\n');

for x=1:length(joints)
    fprintf(fid, format, [timeStep(x), joints(x,:)]);
end
fclose(fid);

%%
load('/Users/frankwillett/Documents/osim4d_sphere_gen13_0.mat')

%joints = zeros(length(envState),7);
%joints(:,1:4) = envState(:,[13,14,15,16]);
%joints(:,5:7) = repmat([-5.36, 6.45, 1.39],length(joints),1);

header =  {'time','sternoclavicular_r2','sternoclavicular_r3','unrotscap_r3','unrotscap_r2','acromioclavicular_r2', ...
                      'acromioclavicular_r3','acromioclavicular_r1','unrothum_r1','unrothum_r3','unrothum_r2', ...
                      'elv_angle','shoulder_elv','shoulder1_r2','shoulder_rot','elbow_flexion','pro_sup', ...
                      'deviation','flexion'}; 
joints = envJointsForVis*(180/pi);
timeStep = 0:0.01:size(joints,1)*0.01;
timeStep = timeStep(1:length(joints));

inDegrees = true;
writeOsimMotionFile('/Users/frankwillett/Documents/motionSequence.sto', [timeStep', joints], header, inDegrees );
             
header =  {'time','DELT1','DELT2','DELT3','SUPSP','INFSP','SUBSC','TMIN','TMAJ','PECM1','PECM2','PECM3','LAT1','LAT2',...
    'LAT3','CORB','TRIlong','TRIlat','TRImed','ANC','BIClong','BICshort','BRA','BRD'};

controls = controllerOutputs;
controls = (zscore(controls)+3)/6;
controls(controls<0)=0;
controls(controls>1)=1;
controls = controls*0.5;

timeStep = 0:0.01:size(joints,1)*0.01;
timeStep = timeStep(1:length(joints));

inDegrees = false;
writeOsimMotionFile('/Users/frankwillett/Documents/controls.sto', [timeStep', controls], header, inDegrees );

%%
%joints = zeros(length(envState),7);
%joints(:,1:4) = envState(:,[13,14,15,16]);
%joints(:,5:7) = repmat([-5.36, 6.45, 1.39],length(joints),1);

header =  {'time','sternoclavicular_r2','sternoclavicular_r3','unrotscap_r3','unrotscap_r2','acromioclavicular_r2', ...
                      'acromioclavicular_r3','acromioclavicular_r1','unrothum_r1','unrothum_r3','unrothum_r2', ...
                      'elv_angle','shoulder_elv','shoulder1_r2','shoulder_rot','elbow_flexion','pro_sup', ...
                      'deviation','flexion','DELT1','DELT2','DELT3','SUPSP','INFSP','SUBSC','TMIN','TMAJ','PECM1','PECM2','PECM3','LAT1','LAT2',...
                       'LAT3','CORB','TRIlong','TRIlat','TRImed','ANC','BIClong','BICshort','BRA','BRD'}; 

joints = envJointsForVis*(180/pi);
timeStep = 0:0.01:size(joints,1)*0.01;
timeStep = timeStep(1:length(joints));

controls = controllerOutputs;
controls = controls * 2;
controls(controls>1) = 1;
%controls = (zscore(controls)+3)/6;
%controls(controls<0)=0;
%controls(controls>1)=1;

inDegrees = true;
writeOsimMotionFile('/Users/frankwillett/Documents/motionSequenceAll_color3.sto', [timeStep', joints, controls], header, inDegrees );
      

%%
%joints = zeros(length(envState),7);
%joints(:,1:4) = envState(:,[13,14,15,16]);
%joints(:,5:7) = repmat([-5.36, 6.45, 1.39],length(joints),1);
inputFiles = {'/Users/frankwillett/Documents/osim4d_sphere_gen15_0.mat', 'osim4d_sphere_gen15_0'; ...
    '/Users/frankwillett/Documents/osim4d_sphere_gen28_0.mat', 'osim4d_sphere_gen28_0'; ...
    '/Users/frankwillett/Documents/osim7d_sphere_gen14_0.mat', 'osim7d_sphere_gen14_0'; ...
    '/Users/frankwillett/Documents/osim4d_velCost_0.mat', 'osim4d_velCost_0'; ...
    '/Users/frankwillett/Documents/osim4d_accCost_2_0.mat', 'osim4d_accCost_2_0'; ...
    '/Users/frankwillett/Documents/osim4d_accCost_3_0.mat', 'osim4d_accCost_3_0'; ...
    '/Users/frankwillett/Documents/osim4d_accCost_4_0.mat', 'osim4d_accCost_4_0'};

for fileIdx=1:length(inputFiles)
    load(inputFiles{fileIdx,1})

    if size(controllerOutputs,2)==23
        header =  {'time','sternoclavicular_r2','sternoclavicular_r3','unrotscap_r3','unrotscap_r2','acromioclavicular_r2', ...
                              'acromioclavicular_r3','acromioclavicular_r1','unrothum_r1','unrothum_r3','unrothum_r2', ...
                              'elv_angle','shoulder_elv','shoulder1_r2','shoulder_rot','elbow_flexion','pro_sup', ...
                              'deviation','flexion','DELT1','DELT2','DELT3','SUPSP','INFSP','SUBSC','TMIN','TMAJ','PECM1','PECM2','PECM3','LAT1','LAT2',...
                               'LAT3','CORB','TRIlong','TRIlat','TRImed','ANC','BIClong','BICshort','BRA','BRD', ...
                               'greenTarget_X','greenTarget_Y','greenTarget_Z','redTarget_X','redTarget_Y','redTarget_Z'}; 
    else
        header =  {'time','sternoclavicular_r2','sternoclavicular_r3','unrotscap_r3','unrotscap_r2','acromioclavicular_r2', ...
                      'acromioclavicular_r3','acromioclavicular_r1','unrothum_r1','unrothum_r3','unrothum_r2', ...
                      'elv_angle','shoulder_elv','shoulder1_r2','shoulder_rot','elbow_flexion','pro_sup', ...
                      'deviation','flexion','DELT1','DELT2','DELT3','SUPSP','INFSP','SUBSC','TMIN','TMAJ','PECM1','PECM2','PECM3','LAT1','LAT2',...
                       'LAT3','CORB','TRIlong','TRIlat','TRImed','ANC','SUP','BIClong','BICshort','BRA','BRD','ECRL', ...
                       'ECRB','ECU','FCR','FCU','PL','PT','PQ',...
                       'greenTarget_X','greenTarget_Y','greenTarget_Z','redTarget_X','redTarget_Y','redTarget_Z'}; 
    end

    joints = envJointsForVis*(180/pi);
    timeStep = 0:0.01:size(joints,1)*0.01;
    timeStep = timeStep(1:length(joints));

    controls = controllerOutputs;
    controls = controls * 3;
    controls(controls>1) = 1;
    %controls = (zscore(controls)+3)/6;
    %controls(controls<0)=0;
    %controls(controls>1)=1;

    greenTarget = zeros(length(joints),3);
    redTarget = zeros(length(joints),3);
    delayIdx = controllerInputs(:,end)==1;

    redTarget(delayIdx,:) = controllerInputs(delayIdx,1:3);
    redTarget(~delayIdx,1) = 10;

    greenTarget(~delayIdx,:) = controllerInputs(~delayIdx,1:3);
    greenTarget(delayIdx,1) = 10;

    inDegrees = true;
    writeOsimMotionFile(['/Users/frankwillett/Documents/motionSequence_' inputFiles{fileIdx,2} '.sto'], ...
        [timeStep', joints, controls, greenTarget, redTarget], header, inDegrees );
end

