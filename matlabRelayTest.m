%%
% % ptb only, but with trigger out.
featherPath='/dev/cu.usbmodem1431';
featherBaud=9600;
feather=serial(featherPath,'BaudRate',featherBaud);
fopen(feather);
flushinput(feather);

%%
g=0;
while g<1000000
    if feather.BytesAvailable>0
        a=fscanf(feather);
        disp(a)
    end
    g=g+1;
end