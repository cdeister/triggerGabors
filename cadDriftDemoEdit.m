function cadDriftDemoEdit(angle, cyclespersecond, f, drawmask, gratingsize)
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 2);


if nargin < 5
    gratingsize = [];
end

if isempty(gratingsize)
    % By default the visible grating is 400 pixels by 400 pixels in size:
    gratingsize = 400;
end

if nargin < 4
    drawmask = [];
end

if isempty(drawmask)
    % By default, we mask the grating by a gaussian transparency mask:
    drawmask=1;
end;

if nargin < 3
    f = [];
end

if isempty(f)
    % Grating cycles/pixel: By default 0.05 cycles per pixel.
    f=0.05;
end;

if nargin < 2
    cyclespersecond = [];
end

if isempty(cyclespersecond)
    % Speed of grating in cycles per second: 1 cycle per second by default.
    cyclespersecond=5;
end;

if nargin < 1
    angle = [];
end

if isempty(angle)
    % Angle of the grating: We default to 30 degrees.
    angle=180;
end;

movieDurationSecs=20;   % Abort demo after 20 seconds.

% Define Half-Size of the grating image.
texsize=gratingsize / 2;

% Screen('Preference', 'SkipSyncTests', 1);

try

%     AssertOpenGL;
    screens=Screen('Screens');
    screenNumber=1;

    % Find the color values which correspond to white and black: Usually
    % black is always 0 and white 255, but this rule is not true if one of
    % the high precision framebuffer modes is enabled via the
    % PsychImaging() commmand, so we query the true values via the
    % functions WhiteIndex and BlackIndex:
    white=WhiteIndex(screenNumber)*1;
    black=BlackIndex(screenNumber)*1;

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
    gray=round((white+black)/2);

    % This makes sure that on floating point framebuffers we still get a
    % well defined gray. It isn't strictly neccessary in this demo:
    if gray == white
        gray=white / 2;
    end

    % Contrast 'inc'rement range for given white and gray values:
    inc=white-gray;

    % Open a double buffered fullscreen window and set default background
    % color to gray:
    [w screenRect]=Screen('OpenWindow',screenNumber, gray);

    if drawmask
        % Enable alpha blending for proper combination of the gaussian aperture
        % with the drifting sine grating:
        Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    end
    
    % Calculate parameters of the grating:
    
    % First we compute pixels per cycle, rounded up to full pixels, as we
    % need this to create a grating of proper size below:
    p=ceil(1/f);
    
    % Also need frequency in radians:
    fr=f*2*pi;
    
    % This is the visible size of the grating. It is twice the half-width
    % of the texture plus one pixel to make sure it has an odd number of
    % pixels and is therefore symmetric around the center of the texture:
    visiblesize=2*texsize+1;

    % Create one single static grating image:
    %
    % We only need a texture with a single row of pixels(i.e. 1 pixel in height) to
    % define the whole grating! If the 'srcRect' in the 'Drawtexture' call
    % below is "higher" than that (i.e. visibleSize >> 1), the GPU will
    % automatically replicate pixel rows. This 1 pixel height saves memory
    % and memory bandwith, ie. it is potentially faster on some GPUs.
    %
    % However it does need 2 * texsize + p columns, i.e. the visible size
    % of the grating extended by the length of 1 period (repetition) of the
    % sine-wave in pixels 'p':
    x = meshgrid(-texsize:texsize + p, 1);
    
    % Compute actual cosine grating:
    grating=gray + inc*cos(fr*x);
    assignin('base','gratingd',grating);
    gratingtex=Screen('MakeTexture', w, grating);
    mask=ones(2*texsize+1, 2*texsize+1, 2) * gray;
    [x,y]=meshgrid(-1*texsize:1*texsize,-1*texsize:1*texsize);
    mask(:, :, 2)= round(white * (1 - exp(-((x/200).^2)-((y/200).^2))));
    gPlus=(gratingsize+1);
    
    % the middle of the grating is 
    assignin('base','tCenter',fix(gratingsize/2))
    targOffset=[200+angle,-200+angle];

    
    yOff=targOffset(2);
    xOff=targOffset(1);
    mask(:, :, 2)=circshift(mask(:, :, 2),[yOff,xOff]);
    mask(:,gPlus+xOff:gPlus,2)=max(grating);
    mask(gPlus+yOff:gPlus,:,2)=max(grating);
    assignin('base','testMask',mask);
    masktex=Screen('MakeTexture', w, mask);
    assignin('base','masktexT',masktex);

    % Query maximum useable priorityLevel on this system:
    priorityLevel=MaxPriority(w); %#ok<NASGU>

    % We don't use Priority() in order to not accidentally overload older
    % machines that can't handle a redraw every 40 ms. If your machine is
    % fast enough, uncomment this to get more accurate timing.
    %Priority(priorityLevel);
    
    % Definition of the drawn rectangle on the screen:
    % Compute it to  be the visible size of the grating, centered on the
    % screen:
    dstRect=[0 0 visiblesize visiblesize];
    dstRect=CenterRect(dstRect, screenRect);

    % Query duration of one monitor refresh interval:
    ifi=Screen('GetFlipInterval', w);
    disp(ifi)
    
    % Translate that into the amount of seconds to wait between screen
    % redraws/updates:
    
    % waitframes = 1 means: Redraw every monitor refresh. If your GPU is
    % not fast enough to do this, you can increment this to only redraw
    % every n'th refresh. All animation paramters will adapt to still
    % provide the proper grating. However, if you have a fine grating
    % drifting at a high speed, the refresh rate must exceed that
    % "effective" grating speed to avoid aliasing artifacts in time, i.e.,
    % to make sure to satisfy the constraints of the sampling theorem
    % (See Wikipedia: "Nyquist?Shannon sampling theorem" for a starter, if
    % you don't know what this means):
    waitframes = 1;
    
    % Translate frames into seconds for screen update interval:
    waitduration = waitframes * ifi;
    p=1/f;
    shiftperframe= cyclespersecond * p * waitduration;

    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp as timing baseline for our redraw loop:
    vbl=Screen('Flip', w);

    % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
    vblendtime = vbl + movieDurationSecs;
    i=0;
    
    % Animationloop:
    while vbl < vblendtime
        % Shift the grating by "shiftperframe" pixels per frame:
        % the mod'ulo operation makes sure that our "aperture" will snap
        % back to the beginning of the grating, once the border is reached.
        % Fractional values of 'xoffset' are fine here. The GPU will
        % perform proper interpolation of color values in the grating
        % texture image to draw a grating that corresponds as closely as
        % technical possible to that fractional 'xoffset'. GPU's use
        % bilinear interpolation whose accuracy depends on the GPU at hand.
        % Consumer ATI hardware usually resolves 1/64 of a pixel, whereas
        % consumer NVidia hardware usually resolves 1/256 of a pixel. You
        % can run the script "DriftTexturePrecisionTest" to test your
        % hardware...
        xoffset = mod(i*shiftperframe,p);
        i=i+1;

        % Define shifted srcRect that cuts out the properly shifted rectangular
        % area from the texture: We cut out the range 0 to visiblesize in
        % the vertical direction although the texture is only 1 pixel in
        % height! This works because the hardware will automatically
        % replicate pixels in one dimension if we exceed the real borders
        % of the stored texture. This allows us to save storage space here,
        % as our 2-D grating is essentially only defined in 1-D:
        srcRect=[xoffset 0 xoffset + visiblesize visiblesize];
        
        % Draw grating texture, rotated by "angle":
        Screen('DrawTexture', w, gratingtex, srcRect, dstRect, angle);

        if drawmask==1
            % Draw gaussian mask over grating:
            Screen('DrawTexture', w, masktex, [], dstRect, angle);
        end

        % Flip 'waitframes' monitor refresh intervals after last redraw.
        % Providing this 'when' timestamp allows for optimal timing
        % precision in stimulus onset, a stable animation framerate and at
        % the same time allows the built-in "skipped frames" detector to
        % work optimally and report skipped frames due to hardware
        % overload:
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);

        % Abort demo if any key is pressed:
        if KbCheck
            break;
        end
    end
    Priority(0);
    sca;

catch
    sca;
    Priority(0);
    psychrethrow(psychlasterror);
end 
return;
