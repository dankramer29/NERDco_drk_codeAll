function sessionList = getT5_2D_CL_Datasets()
    sessionList = {'t5.2016.09.16',[3 4 5 6 7 8 9 10 11 12 14 18],'east'
        't5.2016.09.19',[1 3 4 5 6 7 8 9 10 15 16 17 19 20 21 23 26 27 28 30 31 32],'east'
        't5.2016.09.26',[7 12 13 19 21 24 29 32],'west'
        't5.2016.09.28',[4 6 7 8 9 10 16 18 19 22 24 25 29 35],'west'
        't5.2016.10.03',[10 14 15 27 29 30 31],'west'
        't5.2016.10.05',[8 9 11 12 13 14 16 17 18 21 22],'west'
        't5.2016.10.07',[2 3 4 5 6 8 9 10 11 14 15 16 17 18],'west'
        't5.2016.10.10',[5 8 10 11 12 14 15 16 17 20 21 22 24 25 26 28 29 30],'west'
        't5.2016.10.12',[4 10 12 13 14 17 18 19 22 23 25 26 28 29 30 31],'west'
        't5.2016.10.13',[5 7 8 9 13 14 15 17 18 19 21 22 24],'west'
        't5.2016.10.17',[2 4],'west'
        't5.2016.10.19',[2 4],'west'
        't5.2016.10.24',[3 5 17 19 26 28 34 38 41 45],'west'
        't5.2016.10.26',[3 5 9 13 23 28 34],'west'
        't5.2016.10.31',[3 5 6 7 8 9],'west'
        't5.2016.12.06',[3 5],'west'
        't5.2016.12.08',[5 7],'west'
        't5.2016.12.15',[4 8 11 12 13 14 17 18 19],'west'
        't5.2016.12.16',[6 8],'west'
        't5.2016.12.19',[3 5],'west'
        't5.2016.12.21',[3 6 12 13 15 16 19 20 21 23],'west'
        't5.2017.01.04',[4 7],'west'
        't5.2017.01.30',[28 29],'west'
        't5.2017.02.15',[19 21 22 23 24],'west'
        't5.2017.02.22',[5 6 7 8 9 10],'west'
        't5.2017.03.30',[10 11 12 14],'west'
        't5.2017.04.26',[15 16 17 18],'west'
        't5.2017.05.24',[16 17 18 19],'west'
        't5.2017.05.31',[3 5],'west'
        't5.2017.07.07',[2 3],'west'
        't5.2017.07.31',[18 19 20 21],'west'
        't5.2017.08.04',[7 8],'west'
        't5.2017.08.07',[6 7 8],'west'
        't5.2017.09.20',[4 5 6 7 8 9 10 11 12],'west'
        };

    %'t5.2016.09.16' Brandman's CLAUS 1st day, tried several different
    %imageries, all calibrating continuously in CL. Used GP
    %'t5.2016.09.19' Brandman's CLAUS 2nd day, compared standard calibration
    %routine to CALUS calibrated GP decoder. Contains grid and radial blocks.
    %'t5.2016.09.21' 1st day CL with west coast software. Tried several
    %different imageries.
    %'t5.2016.09.28' 2nd day CL with west coast software. Poker chip, track
    %ball, joystick imageries. 
    %'t5.2016.10.03' More 2D CL with different imageries
    %'t5.2016.10.05' 2D CL + HMM click (left hand squeeze). Grid task with
    %click selection. Fiddled with thresholds.
    %'t5.2016.10.07' 2D CL + HMM click. Grid task.
    %'t5.2016.10.10' 2D CL + HMM click. Grid task.
    %'t5.2016.10.12' 2D CL + HMM click. Grid task. Keyboard at the end (not
    %included).
    %'t5.2016.10.13' 2D CL + HMM click. Grid task.
    %'t5.2016.10.17' 2D CL + HMM click. Keyboard practice. Just including 1
    %calibration block and 1 grid block at the beginning. 
    %'t5.2016.10.19' 2D CL + HMM click. Keyboard practice. Just including 1
    %calibration block and 1 grid block at the beginning. 
    %'t5.2016.10.24' 2D CL + HMM click. Keyboard & Grid data. Just including
    %calibration and grid blocks.
    %'t5.2016.10.26' 2D CL + HMM click. Keyboard & Grid data. Just including
    %calibration and grid blocks.
    %'t5.2016.10.31' 2D CL + HMM click. Monthly Fitts & Tablet practice. Just including
    %monthly fitts data & calibration.
    %'t5.2016.12.06' 2D CL + HMM click. Tablet practice. Just including grid & calibration.
    %'t5.2016.12.08' 2D CL + HMM click. Tablet practice. Just including grid & calibration.
    %'t5.2016.12.15' 2D CL + HMM click. All grid blocks. Some dwell only. Not
    %sure what is going on here.
    %'t5.2016.12.16' 2D CL + HMM click. Tablet practice. Just including grid & calibration.
    %'t5.2016.12.19' 2D CL + HMM click. Tablet practice. Just including grid & calibration.
    %'t5.2016.12.21' 2D CL + HMM click. Tablet day that seemed not to be
    %working well. Re-calibrated the filters a lot. Including calibration data.
    %'t5.2017.01.04' 2D CL + HMM click. Tablet practice. Just including grid & calibration.
    %'t5.2017.01.30' 3D CL + HMM click. Just including 2 blocks of 2D Fitts at
    %the end.
    %'t5.2017.02.15' 3D CL + HMM click. Just including 2 blocks of 2D Fitts and 2 blocks of Radial8 at
    %the end.
    %'t5.2017.02.22' 2D CL + HMM click. PBS Newshour. Grid task and keyboard.
    %Just including grid task & calibration.
    %'t5.2017.03.30' 5.0D vertical rod & monthly Fitts. Including monthly Fitts
    %blocks with no click (?).
    %'t5.2017.04.26' 4.1D & monthly Fitts. Including monthly Fitts
    %blocks with click.
    %'t5.2017.05.24' 4.0D low gain. Including monthly Fitts blocks with no
    %click.
    %'t5.2017.05.31' Tablet RTI session with click. Including calibration
    %blocks at the beginning.
    %'t5.2017.07.07' Tablet RTI session with click. Including calibration
    %blocks at the beginning.
    %'t5.2017.07.31' 2+2D session with monthly Fitts at the end. Including monthly Fitts
    %blocks.
    %'t5.2017.08.04' Tablet RTI session with click. Including calibration
    %blocks at the beginning.
    %'t5.2017.08.08' Tablet RTI session with click. Including calibration
    %blocks at the beginning.
    %'t5.2017.09.20' Speech session with monthly Fitts and extra Raidal8 blocks
    %at the end with no click. Including all those.
end
