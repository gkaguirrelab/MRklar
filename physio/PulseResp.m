function [output] = PulseResp(dicomDir,pulsFile,outDir)
%
%   Usage:
%   [output] = PulseResp(dicomDir,pulsFile,outDir,OLD)
%
%   Reads the AcquisitionTime (AT) field from the dicom header, which is
%   when the acquisition of data for each image started, and the
%   'LogStartMDHTime', 'LogStopMDHTime' from the .puls file footer.
%   Extracts the puls data during the DICOM acquistion interval (i.e. first
%   AT to last AT+TR).%
%   (Code adapted from scripts written by Joe McGuire)
%
%   Also computes a collection of regressors, based on 'PulseComplete.m'
%   written by Omar H Butt Aug 2010, for each individual run.
%
%   Inputs:
%       dicomDir = full path to directory containing individual dicoms
%       pulsFile = full path to .puls file with pulse oximetry data for run
%           associated with the dicomDir
%       outputDir = path to output directory
%       OLD = 0 <default> or 1; set to 1 for when pulsOx data was not
%           logged automatically at the scanner, as this file format is
%           slightly different
%       HRrate = 'low' <default> or 'high'
%           'high'  = high average heartrate (>100) (e.g. canines)
%           'low'  = low average HR rate (<100) (e.g. humans)
%
%   Outputs:
%       output.all - structure containing 8 physiolocial noise covariates
%       -.mat file containing the dicom, pulse, and output structures.
%       Output structure contains cosine and sine 1st and 2nd order
%       physiological covariates
%       -.txt file containing the 8 physiolocial noise covariates found in
%       output.all
%
%   following Verstynen & Deshpande (2011)
%
%   Written by Andrew S Bock Feb 2014

%% Get the acquistion time from the dicom files
series.List = dir(fullfile(dicomDir,'*'));
series.Names = {series.List(:).name}';
isHidden = strncmp('.',series.Names,1); % remove hidden files from the list
series.List(isHidden) = [];
nTRs = length(series.List);
%fprintf('reading headers for %d dicom images...',nTRs);
dicom.TR_all = nan(nTRs,1); % TR from each image header (msec)
% Find the time of acquisition (info.AcquisitionTime) for all DICOMS
for t = 1:nTRs
    dicom.info = dicominfo(fullfile(dicomDir,series.List(t).name));
    dicom.TR_all(t,1) = dicom.info.RepetitionTime;
    dicom.timeStr = dicom.info.AcquisitionTime; % acquisition time
    % convert the timestamp from HHMMSS.SSSSSS to "msec since midnight"
    hrsInMsec = 60*60*1000*str2double(dicom.timeStr(1:2));
    minsInMsec = 60*1000*str2double(dicom.timeStr(3:4));
    secInMsec = 1000*str2double(dicom.timeStr(5:end));
    dicom.AT(t,1) = hrsInMsec + minsInMsec + secInMsec;
end
% verify that timestamps are non-decreasing across images
% (i.e., that dicoms were loaded in the correct order)
if ~all(diff(dicom.AT)>=0)
    dicom.AT_badorder = dicom.AT;
    [dicom.AT,dicom.AT_trueorder] = sort(dicom.AT);
end
% Bug with the first dicom AT
dicom.AT(1) = dicom.AT(2) - dicom.TR_all(2);
%fprintff('done.\n');
dicom.TR = unique(dicom.TR_all); % confirm TR is consistent for all DICOMS (msec)
assert(numel(dicom.TR)==1,'Inconsistent TRs!');
%fprintff('TR = %d (ms)\n',dicom.TR);
%% Pull out pulse information from Pulse File
[~,~,ext] = fileparts(pulsFile);
switch ext
    case '.log'
        pulse = read_PULS_log_file(pulsFile,dicom);
    case '.puls'
        pulse = read_PMU_file(pulsFile);
end
%% Apply smoothing/filtering to the signal
% Filter signal for high frequency peaks following Verstynen & Deshpande (2011)
pulse.Hsignal = filter_signal(pulse.data_dmean,'band',pulse.sampTsecs,0.6,2);% 0.6-2.0 Hz Butterworth filter;
% Filter signal for low frequency peaks
pulse.Lsignal = filter_signal(pulse.data_dmean,'low',pulse.sampTsecs,-inf,0.6);
FWHM = 0.4*pulse.sampR; % % 400 ms FWHM; following Verstynen & Deshpande (2011)
sig = FWHM/(2*(sqrt(2*log(2)))); % convert to sigma
pulse.Lsignal = smooth_kernel(pulse.Lsignal,sig);
%% Find the peaks
%IF WANT TO USE DELTA must be divided by sampling period (in msec)
delta.cardiac = 600./pulse.sampT; %sets max delta to reflect 100bpm
delta.resp = 3000./pulse.sampT; %sets max delta to reflect 20 breaths/min
%[pulse.highMax,pulse.highMin] = detpeaks(pulse.Hsignal,pulse.delta./pulse.sampT);
%[pulse.highMax,pulse.highMin] = detpeaks(pulse.Hsignal);
[pulse.highMax,pulse.highMin] = detpeaks(pulse.Hsignal,delta.cardiac);
output.Hevents = zeros(size(pulse.Hsignal));
if ~isempty(pulse.highMax)
    output.Hevents(pulse.highMax(:,1)) = 1;
end
%[pulse.lowMax,pulse.lowMin] = detpeaks(pulse.Lsignal,pulse.delta./pulse.sampT);
%[pulse.lowMax,pulse.lowMin] = detpeaks(pulse.Lsignal);
[pulse.lowMax,pulse.lowMin] = detpeaks(pulse.Lsignal,delta.resp);
output.Levents = zeros(size(pulse.Lsignal));
if ~isempty(pulse.lowMax)
    output.Levents(pulse.lowMax(:,1)) = 1;
end
% Display Cardiac and Respiration rates
Time = (1:length(pulse.data_dmean))./pulse.sampR;
output.Highrate = length(find(output.Hevents)) / Time(end) * 60;
fprintf('\n Cardiac Rate (per min): %f\n',output.Highrate);
output.Lowrate = length(find(output.Levents)) / Time(end) * 60;
fprintf('\n Resp Rate (per min): %f\n',output.Lowrate);
%% HIGH events - Calculate the cardiac phase cycle (0 - 2pi)
if ~isempty(pulse.highMax)
    HtrueMax = pulse.highMax(:,1); % get the max peak indices
    Hc_phs = zeros(size(pulse.data_dmean)); % cardiac phase
    Hc_phs(1:(HtrueMax(1)-1)) = nan;
    Hc_phs(HtrueMax(end):end) = nan;
    for imax = 1:(length(HtrueMax)-1)
        prev_peak = HtrueMax(imax); %t1
        next_peak = HtrueMax(imax+1); %t2
        for t = prev_peak:(next_peak-1)
            Hc_phs(t) = 2*pi*(t - prev_peak)/(next_peak - prev_peak);
        end
    end
else
    Hc_phs = zeros(size(pulse.data_dmean)); % cardiac phase
end
%% LOW events - Calculate the cardiac phase cycle (0 - 2pi)
if ~isempty(pulse.lowMax)
    LtrueMax = pulse.lowMax(:,1); % get the max peak indices
    Lc_phs = zeros(size(pulse.data_dmean)); % cardiac phase
    Lc_phs(1:(LtrueMax(1)-1)) = nan;
    Lc_phs(LtrueMax(end):end) = nan;
    for imax = 1:(length(LtrueMax)-1)
        prev_peak = LtrueMax(imax); %t1
        next_peak = LtrueMax(imax+1); %t2
        for t = prev_peak:(next_peak-1)
            Lc_phs(t) = 2*pi*(t - prev_peak)/(next_peak - prev_peak);
        end
    end
else
    Lc_phs = zeros(size(pulse.data_dmean)); % cardiac phase
end
%% Fit 2nd order fourier series to estimate phase
order = 2;
for i = 1:order
    Hf_c_phs(:,(i*2)-1)  = cos(i*Hc_phs);
    Hf_c_phs(:,i*2)      = sin(i*Hc_phs);
    Lf_c_phs(:,(i*2)-1)  = cos(i*Lc_phs);
    Lf_c_phs(:,i*2)      = sin(i*Lc_phs);
end
%% Set nans to zero
Hf_c_phs(isnan(Hf_c_phs)) = 0;
Lf_c_phs(isnan(Lf_c_phs)) = 0;
%% Get closest pulse value for each dicom
for i = 1:length(dicom.AT)
    [~,pulseIdx(i)] = min(abs(dicom.AT(i) - pulse.AT_ms));
end
%% HIGH events - Save out the regressors
output.HCos1 = Hf_c_phs(pulseIdx,1);
output.HSin1 = Hf_c_phs(pulseIdx,2);
output.HCos2 = Hf_c_phs(pulseIdx,3);
output.HSin2 = Hf_c_phs(pulseIdx,4);
%% LOW events - Save out the regressors
output.LCos1 = Lf_c_phs(pulseIdx,1);
output.LSin1 = Lf_c_phs(pulseIdx,2);
output.LCos2 = Lf_c_phs(pulseIdx,3);
output.LSin2 = Lf_c_phs(pulseIdx,4);
%% ALL events
output.all = [...
    output.HCos1,output.HSin1,output.HCos2,output.HSin2 ...
    output.LCos1,output.LSin1,output.LCos2,output.LSin2 ...
    ];
%% Output pulse structure
output.pulse = pulse;
%% Save the data
save(fullfile(outDir,'puls.mat'),'dicom','pulse','output');
dlmwrite(fullfile(outDir,'puls.txt'),output.all,'delimiter','\t','precision','%10.5f')
%disp(['Pulse data saved in ' fullfile(outputDir,'puls.mat')])