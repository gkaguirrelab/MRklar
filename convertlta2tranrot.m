function [x,y,z,pitch,yaw,roll] = convertlta2tranrot(ltaFile)

% Converts a Freesurfer .lta file to translation and rotation values
%
%   Usage:
%   [x,y,z,pitch,yaw,roll] = convertlta2tranrot(ltaMat)
%
%   Written by Andrew S Bock Apr 2016

%% Load in the data from the .lta file
fid = fopen(ltaFile);
A = fread(fid,'char');
Achar = char(A');
fclose(fid);
%% Pull out the 4x4 matrix
startInd = strfind(Achar,'1 4 4');
endInd = strfind(Achar,'src volume info');
strMat = Achar(startInd+6:endInd-1);
blankInds = strfind(strMat,' ');
blankInds = [1,blankInds];
outMat = nan(4,4);
for i = 1:length(blankInds)-1
    outMat(i) = str2double(strMat(blankInds(i):blankInds(i+1)-1));
end
outMat = outMat';
%% Save the relevant values
R = outMat(1:3,1:3);
[angles] = rotmat2angles(R);
pitch = angles(1);
yaw = angles(2);
roll = angles(3);
x = outMat(1,4);
y = outMat(2,4);
z = outMat(3,4);