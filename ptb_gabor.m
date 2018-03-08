useSerial=1;

gSize=900;
nonsymmetric=0;
if useSerial==1
    featherPath='COM36';
    featherBaud=9600;
    feather=serial(featherPath,'BaudRate',featherBaud);
    fopen(feather);
    flushinput(feather);
else
end

PsychDefaultSetup(2);
screenid = 1;   
Screen('Preference', 'SkipSyncTests', 2);
Screen('Preference', 'Verbosity', 0);
PsychImaging('PrepareConfiguration');

white = WhiteIndex(screenid);
grey = white / 2; 

% Initial stimulus params for the gabor patch:
res = 1*[gSize gSize];
phase = 0;
sc = 50.0;
freq = .05;
tilt = 0;
contrast = 0;
aspectratio = 1.0;

tContrast = 0;
tOrient = 0;
tSFreq=0;
tTFreq=0;
lastContrast=0;
xOff=175;
yOff=-175;

rect = [];
win = PsychImaging('OpenWindow', screenid, 0.5, rect);

tw = res(1);
th = res(2);
x=tw/2;
y=th/2;

trialNum=0;
tTime={};
tCntr=0;
cScale=10;

if useSerial==1
    % drain the buffer
    while feather.BytesAvailable>0
        fscanf(feather);
    end
else
end


[gabortex,gabRec] = CreateProceduralGabor(win, tw, th, nonsymmetric, [0.5 0.5 0.5 0.0]);
Screen('DrawTexture', win, gabortex, [], OffsetRect(gabRec,xOff,yOff), tilt, [], [], [], [],...
    kPsychDontDoRotation, [phase, freq, sc, contrast, aspectratio, 0, 0, 0]);


% Perform initial flip to gray background and sync us to the retrace:
vbl = Screen('Flip', win);
ts = vbl;
count = 0;
totmax = 0;


runningTask=1;
anCount=0;
mDir=-1;

while runningTask
    anCount=anCount+1;
    
    if useSerial==1
        if feather.BytesAvailable>0 
            tempBuf=fscanf(feather);                                           
            splitBuf=strsplit(tempBuf,',');
            if strcmp(splitBuf{1},'v')
                disp('ser');
                tilt = str2num(splitBuf{2});
                contrast=str2num(splitBuf{3})*cScale;
                freq=str2num(splitBuf{4})*0.001;
                tTFreq=20;
                runningTask = str2num(splitBuf{6});
            else
            end 
        else 
        end
    elseif useSerial==0
        if anCount>1000
            freq=0.048;
        else
        end
        
        if anCount>2000
            runningTask=0;
        else
        end
    end
    
    % animation stuff

    phase = anCount * 10;
    aspectratio = 1 + tilt; %anCount * 0.01;
    Screen('DrawTexture', win, gabortex, [], OffsetRect(gabRec,xOff,yOff), tilt,...
        [], [], [], [], kPsychDontDoRotation, ...
        [(mDir*phase), freq, sc, contrast, aspectratio, 0, 0, 0]);
    Screen('Flip', win);
%     if KbCheck
%             break;
%     end






end

tend = Screen('Flip', win);
avgfps = count / (tend - ts);
fprintf('The average framerate was %f frames per second.\n', avgfps);

sca;
if useSerial==1
    fclose(feather)
    delete(feather)
else
end
