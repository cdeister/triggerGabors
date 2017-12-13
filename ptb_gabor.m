%% open com
featherPath='/dev/cu.usbmodem3099121';
featherBaud=9600;
feather=serial(featherPath,'BaudRate',featherBaud);
fopen(feather);
flushinput(feather);

% setup vars
% Clear  the workspace
% clearvars -except orientList n numTrials freqList  

% Setup PTB with default values
PsychDefaultSetup(2);

% Set the screen number to the secondary monitor if there is one
screenNumber = max(Screen('Screens'));   

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2; 

% Skip sync tests
Screen('Preference', 'SkipSyncTests', 2); 

%%
% Open the screen
[window, windowRect] = PsychImaging('OpenWindow',...
    screenNumber, grey, [], 32, 2,[], [],kPsychNeed32BPCFloat);
    

numTrials = 1;                    
   
orientList = [0,20,40,80,120];
freqList = [1,2,4,8,16,32];                                                           
               
k=0;
lastK=k;    
h=0;
contrast = 0.0;
orientation = 0;
runningTask=1;

% drain the buffer
while feather.BytesAvailable>0
    fscanf(feather);
end

while runningTask==1 || h<=10000
    
    if feather.BytesAvailable>0 
        tempBuf=fscanf(feather);                                           
        splitBuf=strsplit(tempBuf,',');
        
        if strcmp(splitBuf{1},'o')
            orientation = str2num(splitBuf{2});
        else
        end
        
        if strcmp(splitBuf{1},'c')
            contrast = str2num(splitBuf{2});
        else
        end
        
        if strcmp(splitBuf{1},'r')
            runningTask = str2num(splitBuf{2});
        else
        end
        
    else 
    end
    
    % Dimension of the region of Gabor in pixels
    gaborDimPix = windowRect(4) / 2;

    % Sigma of Gaussian
    sigma = gaborDimPix / 7;

    % Gabor Parameters
    tempor = randi(numel(orientList));
    

    aspectRatio = 1.0;
    phase = 0;

    % Spatial Frequency (Cycles Per Pixel)
    tempfreq = 30;
    numCycles = 10;
    freq = numCycles / gaborDimPix;

    backgroundOffset = [0.5 0.5 0.5 0.0];
    disableNorm = 1;          
    preContrastMultiplier = 0.5;
    gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
        backgroundOffset, disableNorm, preContrastMultiplier);

    % Randomise the phase of the Gabors and make a properties matrix.
    propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0];

    % Draw the Gabor
    Screen('DrawTextures', window, gabortex, [], [], orientation, [], [], [], [],...
        kPsychDontDoRotation, propertiesMat');

    % Flip to the screen
    Screen('Flip', window);
    h=h+1;
%   KbStrokeWait;

end




sca;

%%
% close and clean up
fclose(feather)
delete(feather)
clear all
