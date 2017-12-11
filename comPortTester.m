%% open
featherPath='/dev/cu.usbmodem3003971';
featherBaud=9600;
feather=serial(featherPath,'BaudRate',featherBaud);
fopen(feather);
flushinput(feather);

%% try some variables
% all writes end with an >
% all writes start with a variable flag:
% f= temporal freq; s= spatial freq; t=trial number; o=orientaion; r=reset

fprintf(feather,'f90>');
fprintf(feather,'o90>');
fprintf(feather,'t9>');

%% reset the variables

fprintf(feather,'r1>');

%% close and clean up
fclose(feather)
delete(feather)
clear all
