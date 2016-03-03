function [outTC] = convert_task2tc(inDir,TR,lengthTC,keyword)

% Loads in a 3 column format text file (for use with FSL), outputs a
%   timecourse that is convolved with an HRF and is at the temporal
%   resolution of the timeseries in question.
%
%   Usage:
%       [outTC] = convert_task2tc(inDir,TR,lengthTC,keyword)
%
%   Written by Andrew S Bock Oct 2015

%% set defaults
if ~exist('keyword','var')
    keyword = '_valid';
end
sampR = 1000;
%% Find condition files with 
f = listdir(fullfile(inDir,['*' keyword '*']),'files');
%% Load condition files, pull out time points, convert to msec
c = cell([1,length(f)]);
for i = 1:length(f)
    tmp = load(fullfile(inDir,f{i}));
    c{i} = round(tmp(:,1:2)*sampR);
end
%% Create conditions (sample rate = 1 msec)
tcLength = lengthTC*TR*sampR;
tc = zeros(tcLength,length(f));
for i = 1:length(c)
    tmp = c{i};
    for j = 1:size(tmp,1)
        ind = tmp(j,1)+1:(tmp(j,1)+1 + tmp(j,2));
        ind(ind>tcLength) = [];
        tc(ind,i) = 1;
    end
end
%% Create HRF, convolve with timecourses
HRF = doubleGammaHrf(1/sampR);
for i = 1:size(tc,2);
    tmp = conv(tc(:,i),HRF);
    tmpTC(:,i) = tmp(1:tcLength);
end
%% Downsample to resolution of TR
for i = 1:size(tmpTC,2)
    outTC(:,i) = downsample(tmpTC(:,i),TR*sampR);
end