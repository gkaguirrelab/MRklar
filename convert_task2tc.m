function [outTC] = convert_task2tc(bold_dir,TR,lengthTC)

% Loads in a 3 column format text file (for use with FSL), outputs a
%   timecourse that is convolved with an HRF and is at the temporal
%   resolution of the timeseries in question.
%
%   Usage:
%       [outTC] = convert_task2tc(bold_dir,TR,lengthTC)
%
%   Written by Andrew S Bock Oct 2015

%% Find condition files
f = listdir(fullfile(bold_dir,'*condition_*'),'files');
%% Load condition files, pull out time points, convert to msec
for i = 1:length(f)
    tmp = load(fullfile(bold_dir,f{i}));
    c(i,:,:) = round(tmp(:,1:2)*1000);
end
%% Create timecourses (sample rate = 1 msec)
tcLength = lengthTC*TR*1000;
tc = zeros(tcLength,length(f));
for i = 1:size(c,1)
    for j = 1:size(c,2)
        ind = (c(i,j,1)+1):(c(i,j,1)+1 + c(i,j,2));
        ind(ind>tcLength) = [];
        tc(ind,i) = 1;
    end
end
%% Create HRF, convolve with timecourses
HRF = doubleGammaHrf(1/1000);
for i = 1:size(tc,2);
    tmp = conv(tc(:,i),HRF);
    tmpTC(:,i) = tmp(1:tcLength);
end
%% Downsample to resolution of TR
for i = 1:size(tmpTC,2)
    outTC(:,i) = downsample(tmpTC(:,i),TR*1000);
end