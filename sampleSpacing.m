function out = sampleSpacing(dicomFile)

% Calculates the 'SampleSpacing' using the formula:
%
% DwellTime = 1 / (PixelBandwidthInReadOutDirection * nReadOut * 2)
%
%   nReadOut is hard-coded to = 256
%
%   Based on:
%   https://www.mail-archive.com/hcp-users%40humanconnectome.org/msg00899.html
%
%   Written by Andrew S Bock Aug 2016

%% Calculate the sample spacing
tmp = dicominfo(dicomFile);
out = 1/(double(tmp.PixelBandwidth) * double(tmp.Rows) * 2);