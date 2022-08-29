%
% 

wavin = audioread( '/Users/sstavisk/Desktop/R_t5.2019.01.23_B1_trial0001.wav');
FsAudio = 30000;

warning off MATLAB:iofun:UnsupportedEncoding;
tg = tgRead( 'R_t5_2019_01_23_B1_trial0001.TextGrid', 'Unicode' ) % Unicode must be specified or it won't work if there are IPA characters.


myPhoneme = [];
myStartS = [];
for i = 1 : numel( tg.tier{1}.Label )
    if ~isempty( tg.tier{1}.Label{i} )
        myPhoneme{end+1} = tg.tier{1}.Label{i};
        myStartS(end+1) = tg.tier{1}.T1(i);
    end
end

figh = figure;
plot( wavin )
for i = 1 : numel( myPhoneme )
    line([myStartS(i) myStartS(i)].*FsAudio, [-0.5 0.5], 'Color', 'k')
end