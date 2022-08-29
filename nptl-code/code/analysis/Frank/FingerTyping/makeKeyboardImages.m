
%1 2 3 4 5 6 7 8 9 0 - = <-
%tab q w e r t y u i o p [ ] \
%caps a s d f g h j k l ; ' enter
%shift z x c v b n m , . / shift
%space

keyLabels = {'1','2','3','4','5','6','7','8','9','0','-','=','<-',...
    'q','w','e','r','t','y','u','i','o','p',...
    'a','s','d','f','g','h','j','k','l',';','''',...
    'shift','z','x','c','v','b','n','m',',','.','/',...
    'lSpace','rSpace'};

imageLoc = [900, 73, 23;
    901 123, 23;
    902 171 23;
    903 220 23;
    904 268 23;
    905 318 23;
    906 366 23;
    907 414 23;
    908 464 23;
    909 513 23;
    910 561 23;
    911 611 23;
    912 672 23;

    913 97 72;
    914 147 72;
    915 194 72;
    916 243 72;
    917 292 72;
    918 343 72;
    919 391 72;
    920 438 72;
    921 488 72;
    922 537 72;
    
    923 109 121;
    924 158 121;
    925 207 121;
    926 256 121;
    927 305 121;
    928 353 121;
    929 403 121;
    930 452 121;
    931 500 121;
    932 550 121;
    933 600 121;
    
    934 29 170;
    935 133 170;
    936 183 170;
    937 233 170;
    938 280 170;
    939 328 170;
    940 380 170;
    941 427 170;
    942 476 170;
    943 525 170;
    944 573 170;
    
    945 281 223;
    946 375 223;];
   
circleRad = 50;
colors = [0.8 0 0; 0 0.8 0];
figSize = [680         352        1025*0.7         406*0.7];
saveDir = ['/Users/frankwillett/Data/Derived/KeyboardImages/'];
epochNames = {'delay','go'};

%load image
kbImage = imread('coloredKeyboard.jpg');

%%
%single keys
figure('Position',figSize);
set(gca,'position',[0 0 1 1],'units','normalized');
for keyIdx=1:size(imageLoc,1)
    for epochIdx=1:2
        cla;
        hold on;

        image(kbImage);
        pos = [imageLoc(keyIdx,2)-circleRad/2, imageLoc(keyIdx,3)-circleRad/2, circleRad, circleRad];
        rectangle('Position', pos, 'Curvature', [1 1], 'LineWidth', 5, 'EdgeColor', colors(epochIdx,:));
        axis equal;
        set(gca,'YDir','reverse');
        
        axis tight;
        axis off;
        
        saveas(gcf,[saveDir 'keyboard_' num2str(imageLoc(keyIdx,1)) '_' epochNames{epochIdx} '.jpg'],'jpg');
    end
end

%%
%words
numberStart = 947;
words =  {{'p','i','n'},{'c','a','t'},{'c','o','n','e'},{'z','e','r','o'}};
figure('Position',figSize);
set(gca,'position',[0 0 1 1],'units','normalized');
for wordIdx=1:length(words)
    for epochIdx=1:2
        cla;
        hold on;

        image(kbImage);
        
        word = words{wordIdx};
        for letterIdx=1:length(word)
            keyIdx = find(strcmp(keyLabels, word{letterIdx}));
            pos = [imageLoc(keyIdx,2)-circleRad/2, imageLoc(keyIdx,3)-circleRad/2, circleRad, circleRad];
            rectangle('Position', pos, 'Curvature', [1 1], 'LineWidth', 5, 'EdgeColor', colors(epochIdx,:));
        end
        
        axis equal;
        set(gca,'YDir','reverse');
        
        axis tight;
        axis off;
        
        saveas(gcf,[saveDir 'keyboard_' num2str(numberStart+(wordIdx-1)) '_' epochNames{epochIdx} '.jpg'],'jpg');
    end
end

%%
%home row pairs
keyPairs = zeros(45,2);

currIdx=1;
for key1=1:10
    for key2=(key1+1):10
        keyPairs(currIdx,:) = [key1, key2];
        currIdx = currIdx + 1;
    end
end

homeRowKeys = {'a','s','d','f','lSpace','rSpace','j','k','l',';'};
homeRowIdx = [];
for k=1:length(homeRowKeys)
    homeRowIdx(k) = find(strcmp(keyLabels, homeRowKeys{k}));
end

numberStart = 951;
figure('Position',figSize);
set(gca,'position',[0 0 1 1],'units','normalized');
for pairIdx=1:length(keyPairs)
    for epochIdx=1:2
        cla;
        hold on;

        image(kbImage);
        
        for letterIdx=1:2
            keyIdx = homeRowIdx(keyPairs(pairIdx,letterIdx));
            pos = [imageLoc(keyIdx,2)-circleRad/2, imageLoc(keyIdx,3)-circleRad/2, circleRad, circleRad];
            rectangle('Position', pos, 'Curvature', [1 1], 'LineWidth', 5, 'EdgeColor', colors(epochIdx,:));
        end
        
        axis equal;
        set(gca,'YDir','reverse');
        
        axis tight;
        axis off;
        
        saveas(gcf,[saveDir 'keyboard_' num2str(numberStart+(pairIdx-1)) '_' epochNames{epochIdx} '.jpg'],'jpg');
    end
end

%%
%triplets, quads, all keys
rightHandHomeIdx = homeRowIdx(6:end);

keyOn = zeros(0,5);
currIdx = 0;

for x1=1:2
    for x2=1:2
        for x3=1:2
            for x4=1:2
                for x5=1:2
                    currIdx = currIdx + 1;
                    keyOn(currIdx,:) = [x1==2, x2==2, x3==2, x4==2, x5==2];
                end
            end
        end
    end
end

triplePlus = sum(keyOn,2)>=3;
keyOn = keyOn(triplePlus,:);

numberStart = 4000;
figure('Position',figSize);
set(gca,'position',[0 0 1 1],'units','normalized');
for setIdx=1:size(keyOn,1)
    for epochIdx=1:2
        cla;
        hold on;

        image(kbImage);
        
        for letterIdx=1:5
            if ~keyOn(setIdx,letterIdx)
               continue;
            end
            
            keyIdx = rightHandHomeIdx(letterIdx);
            pos = [imageLoc(keyIdx,2)-circleRad/2, imageLoc(keyIdx,3)-circleRad/2, circleRad, circleRad];
            rectangle('Position', pos, 'Curvature', [1 1], 'LineWidth', 5, 'EdgeColor', colors(epochIdx,:));
        end
        
        axis equal;
        set(gca,'YDir','reverse');
        
        axis tight;
        axis off;
        
        saveas(gcf,[saveDir 'keyboard_' num2str(numberStart+(setIdx-1)) '_' epochNames{epochIdx} '.jpg'],'jpg');
    end
end

%%
%more words
numberStart = 4016;
words =  {'pin','cat','cone','zero','fad','lad','vote','quote',...
    'lazy','dog','jumps','quick','brown','fox','the','over','runner','hammer','untill'};
figure('Position',figSize);
set(gca,'position',[0 0 1 1],'units','normalized');
for wordIdx=1:length(words)
    for epochIdx=1:2
        cla;
        hold on;

        image(kbImage);
        
        word = words{wordIdx};
        for letterIdx=1:length(word)
            keyIdx = find(strcmp(keyLabels, word(letterIdx)));
            pos = [imageLoc(keyIdx,2)-circleRad/2, imageLoc(keyIdx,3)-circleRad/2, circleRad, circleRad];
            rectangle('Position', pos, 'Curvature', [1 1], 'LineWidth', 5, 'EdgeColor', colors(epochIdx,:));
        end
        
        axis equal;
        set(gca,'YDir','reverse');
        
        axis tight;
        axis off;
        
        saveas(gcf,[saveDir 'keyboard_' num2str(numberStart+(wordIdx-1)) '_' epochNames{epochIdx} '.jpg'],'jpg');
    end
end



    
    
    
    
    
    
    
    
    
    
    
