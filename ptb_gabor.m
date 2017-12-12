% %% open
% featherPath='/dev/cu.usbmodem3003971';
% featherBaud=9600;
% feather=serial(featherPath,'BaudRate',featherBaud);
% fopen(feather);
% flushinput(feather);

%%
% Clear  the workspace
clearvars -except orientList n numTrials freqList  

% Setup PTB with default values
PsychDefaultSetup(2);

% Set the screen number to the secondary monitor if there is one
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2; 

% Skip sync tests
Screen('Preference', 'SkipSyncTests', 2);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2,...
    [], [],  kPsychNeed32BPCFloat);

%% 
numTrials = 10;

orientList = [0,20,40,80,120];
freqList = [1,2,4,8,16,32];

%%
for n = 1:numTrials

% Dimension of the region of Gabor in pixels
gaborDimPix = windowRect(4) / 2;

% Sigma of Gaussian
sigma = gaborDimPix / 7;

% Gabor Parameters
tempor = randi(numel(orientList));
orientation = orientList(tempor);
contrast = 0.8;
aspectRatio = 1.0;
phase = 0;

% Spatial Frequency (Cycles Per Pixel)
tempfreq = randi(numel(freqList));
numCycles = freqList(tempfreq);
freq = numCycles / gaborDimPix;

% Build a procedural gabor texture 
% https://groups.yahoo.com/neo/groups/psychtoolbox/conversations/topics/9174
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

% Button press changes screen
KbStrokeWait;

end

sca;
