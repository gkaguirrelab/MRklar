function [x,y,z,pitch,yaw,roll] = convertMAT2tranrot(MATFile)

% Converts a FSL MAT motion file to translation and rotation values
%
%   Usage:
%   [x,y,z,pitch,yaw,roll] = convertlta2tranrot(ltaMat)
%
%   Written by Andrew S Bock Apr 2016

%% Load in the data from the MAT file
outMat = load(MATFile);
%% Save the relevant values
R = outMat(1:3,1:3);
[angles] = rotmat2angles(R);
pitch = angles(1);
yaw = angles(2);
roll = angles(3);
x = outMat(1,4);
y = outMat(2,4);
z = outMat(3,4);