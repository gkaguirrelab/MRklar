function [outSignal] = filter_signal(inSignal,filtType,sampT,cutoffHzlow,cutoffHzhigh)

% Filters and input signal based on the specified 'filtType'
%
%   Usage:
%   [outSignal] = filter_signal(inSignal,filtType,sampPeriod,cutoffHzlow,cutoffHzhigh)
%
%   inputs:
%   inSignal - signal to be filtered
%   filtType - can be 'high', 'low', or 'band'
%   sampT - sampling period (e.g. TR for MRI)
%   cutoffHzlow - low frequency cutoff (Hz)
%   cutoffHzhigh - high frequency cutoff (Hz)
%
%   Written by Andrew S Bock Nov 2015

%% Filter data
switch filtType
    case 'high'
        disp('FiltType = ''high''');
        f_cutoff  = 1/(2*sampT);
        n = 5; %order
        Wn = cutoffHzlow/f_cutoff;
        FD = design(fdesign.highpass('N,F3dB',n,Wn),'butter');
        outSignal = filtfilt(FD.sosMatrix, FD.ScaleValues, inSignal);
    case 'low'
        disp('FiltType = ''low''');
        f_cutoff  = 1/(2*sampT);
        n = 5; %order
        Wn = cutoffHzhigh/f_cutoff;
        FD = design(fdesign.lowpass('N,F3dB',n,Wn),'butter');
        outSignal = filtfilt(FD.sosMatrix, FD.ScaleValues, inSignal);
    case 'band'
        disp('FiltType = ''band''');
        f_cutoff  = 1/(2*sampT);
        n = 4; %requires even order number
        Wn = [cutoffHzlow cutoffHzhigh]./f_cutoff;
        FD = design(fdesign.bandpass('N,F3dB1,F3dB2',n,Wn(1),Wn(2)),'butter');
        outSignal = filtfilt(FD.sosMatrix, FD.ScaleValues, inSignal);
end