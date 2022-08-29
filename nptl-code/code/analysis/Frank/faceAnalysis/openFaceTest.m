dat=readtable('/Users/frankwillett/Data/Derived/faceAnalysis/MRDay1Test.csv');
hp = dat{:,{'pose_Tx','pose_Ty','pose_Tz','pose_Rx','pose_Ry','pose_Rz'}};
gaze = dat{:,{'gaze_0_x','gaze_0_y','gaze_0_z','gaze_1_x','gaze_1_y','gaze_1_z'}};
blink = dat{:,{'AU45_c'}};
% AU1 Inner brow raiser I
% AU2 Outer brow raiser I
% AU4 Brow lowerer I
% AU5 Upper lid raiser I
% AU6 Cheek raiser I
% AU7 Lid tightener P
% AU9 Nose wrinkler I
% AU10 Upper lip raiser I
% AU12 Lip corner puller I
% AU14 Dimpler I
% AU15 Lip corner depressor I
% AU17 Chin raiser I
% AU20 Lip stretched I
% AU23 Lip tightener P
% AU25 Lips part I
% AU26 Jaw drop I
% AU28 Lip suck P
% AU45 Blink P

%%
dat=readtable('/Users/frankwillett/Data/Derived/faceAnalysis/eyeTest.csv');
hp = dat{:,{'pose_Tx','pose_Ty','pose_Tz','pose_Rx','pose_Ry','pose_Rz'}};
gaze = dat{:,{'gaze_0_x','gaze_0_y','gaze_0_z','gaze_1_x','gaze_1_y','gaze_1_z','gaze_angle_x','gaze_angle_y'}};
blink = dat{:,{'AU45_c'}};