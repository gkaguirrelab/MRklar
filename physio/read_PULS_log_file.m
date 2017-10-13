function pulse = read_PULS_log_file(pulsFile,dicom)

% Reads in pulse file, outputs a structure with the following information:
%
%   pulse.data              - voltage values
%   pulse.AT_ms             - Acquisition time (msec) of each data value
%   pulse.peaks             - Peak values (estimated by Siemens) in msec
%   pulse.data_demean       - voltage values (de-meaned)
%   pulse.dur               - duration of pulse data (msec)
%   pulse.sampT             - Sampling period in time (msec)
%   pulse.sampTsecs         - Sampling period in time (seconds)
%   pulse.sampR             - Sampling rate (Hz)
%   pulse.delta             - heart beat period (msec)
%   pulse.bpm               - heart rate (beats per minute)
%
%   Usage:
%   pulse = read_PULS_log_file(pulsFile,dicom)
%
%   Written by Andrew S Bock and Marta Vidorreta Díaz de Cerio Dec 2015

%% Load the file, read the character information
fid = fopen(pulsFile);
InputText=textscan(fid,'%s',Inf,'delimiter','\n','HeaderLines',8);
Nvalues         = length(InputText{1});
pulse.data      = zeros(Nvalues,1);
pulse.AT_ms     = zeros(Nvalues,1);
isTrigger       = zeros(Nvalues,1);
for i = 1:Nvalues
    % a = converted data
    % b = number of elements
    [a,b]=sscanf(InputText{1}{i},'%d%s%d%s'); % assume number, string, number, string
    if (b==3)
        pulse.data(i) = a(end);
        pulse.AT_ms(i) = 2.5*a(1); % multiply by 2.5ms 'tics'
        if pulse.AT_ms(i) > 86400000 % 24 hours = 24*60*60*1000
            pulse.AT_ms(i) = pulse.AT_ms(i) - 86400000;
        end
        isTrigger(i) = 0;
    elseif (b==4)
        pulse.data(i) = a(end - length('PULS_TRIGGER'));
        pulse.AT_ms(i) = 2.5*a(1); % multiply by 2.5ms 'tics'
        if pulse.AT_ms(i) > 86400000 % 24 hours = 24*60*60*1000
            pulse.AT_ms(i) = pulse.AT_ms(i) - 86400000;
        end
        isTrigger(i) = 1;
    end
end
%% Pull out the values during the dicom acquistion
if ~isempty(pulse.data)
    [~,ind(1)]      = min(abs(dicom.AT(1) - pulse.AT_ms));
    [~,ind(2)]      = min(abs((dicom.AT(end) + dicom.TR_all(end)) - pulse.AT_ms));
    pulse.data      = pulse.data(ind(1):ind(2));
    pulse.AT_ms     = pulse.AT_ms(ind(1):ind(2));
    isTrigger       = isTrigger(ind(1):ind(2));
    pulse.peaks     = pulse.AT_ms(isTrigger==1);
end
%% Save final structure values
if isempty(pulse.data)
    pulse.data_dmean = [];
    pulse.dur = [];
    pulse.sampT = [];
    pulse.sampTsecs = [];
    pulse.sampR = [];
    pulse.delta = [];
    pulse.bpm = [];
else
    pulse.data_dmean = pulse.data - mean(pulse.data); % de-mean pulse.data
    nSamps = length(pulse.data);
    pulse.dur = pulse.AT_ms(end) - pulse.AT_ms(1); % Duration of pulse data (msec)
    pulse.sampT = pulse.dur/(nSamps-1); % Sampling period (msec)
    pulse.sampTsecs = pulse.sampT/1000; % Sampling period (seconds)
    pulse.sampR = round(1000/pulse.sampT); % Sampling rate (Hz)
    pulse.delta = round(mean(diff(pulse.peaks))); % heart beat period (msec)
    pulse.bpm = length(pulse.peaks)/(pulse.dur/60e3); % heart rate in beats per min
end