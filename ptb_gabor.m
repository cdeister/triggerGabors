%% open com
featherPath='/dev/cu.usbmodem2762721';
featherBaud=9600;
feather=serial(featherPath,'BaudRate',featherBaud);
fopen(feather);
flushinput(feather);

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
    
% 
% set up trials etc.
numTrials = 1;                    
   
k=0;
lastK=k;    
h=0;
timeout=25000;

% default values
contrast = 1;
orientation = 0;
tempfreq = 0;
runningTask=1;

% drain the buffer
while feather.BytesAvailable>0
    fscanf(feather);
end

while h<=timeout
    
    if feather.BytesAvailable>0 
        tempBuf=fscanf(feather);                                           
        splitBuf=strsplit(tempBuf,',');
        disp(tempBuf)
        
        if strcmp(splitBuf{1},'o')
            setOrientation = str2num(splitBuf{2});
            if setOrientation>0
                orientation=setOrientation;
            else
            end
        else
        end
        
        if strcmp(splitBuf{1},'u')
            setContrast = str2num(splitBuf{2});
            if setContrast>0
                contrast=setContrast;
                contrast=1;
            else
            end
        else
        end

        if strcmp(splitBuf{1},'t')
            setTempFreq = str2num(splitBuf{2});
            if setTempFreq>0
                tempFreq=setTempFreq;
            else
            end
        else
        end
        
        if strcmp(splitBuf{1},'r')
            setRunningTask = str2num(splitBuf{2});
            if setRunningTask>0
                runningTask=setRunningTask;
            else
            end
        else
        end
        
    else 
    end
    
    % Dimension of the region of Gabor in pixels
    gaborDimPix = windowRect(4) / 2;

    % Sigma of Gaussian
    sigma = gaborDimPix / 7;
    aspectRatio = 1.0;
    phase = 0;

    % Spatial Frequency (Cycles Per Pixel)
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
