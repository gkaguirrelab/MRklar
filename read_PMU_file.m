function pulse = read_PMU_file(pulsFile)

% Reads in pulse file, outputs a structure with the following information:
%
%   pulse.data              - voltage values
%   pulse.data_demean       - voltage values (de-meaned)
%   pulse.delta             - heart rate estimate by Siemens
%   pulse.AT_ms             - Acquisition time (msec) of each voltage value
%   pulse.sampT             - Sampling period in time (msec)
%   pulse.sampTsecs         - Sampling period in time (seconds)
%   pulse.sampR             - Sampling rate (Hz)
%   pulse.LogStartMDHTime   - Start time of recording
%   pulse.LogStopMDHTime    - Stop time of recording
%   pulse.I5000             - Siemens peak values (usually late)
%   pulse.peak              - Peak values (one value before pulse.I5000)
%
%   Usage:
%   pulse = read_PMU_file(pulsFile);
%
%   Initally written by Marta Vidorreta Díaz de Cerio Dec 2015
%   Updated by Andrew S Bock Dec 2015

%% Load the file, read the character information
fid = fopen(pulsFile);
A = fread(fid);
Achar = transpose(char(A));
Iend = strfind(Achar,'5003'); % 5003 indicates the end of recording
Achartrim = Achar(1:Iend-1); % trimmed to end of recording
%% Delete recording comments
%   e.g. "Logging PULSE signal: reduction factor = 1,
%   PULS_SAMPLES_PER_SECOND = 50; PULS_SAMPLE_INTERVAL = 20000"
bDeleteComments = 1;
while (bDeleteComments)
    I5002=strfind(Achartrim,'5002'); % signals the start of a recording comments section
    I6002=strfind(Achartrim,'6002'); % signals the end of a recording comments section
    if length(I6002) > 1
        bDeleteComments = 1;
    else
        bDeleteComments = 0;
    end
    if ~isempty(I5002)
        I5002 = I5002(1);
        I6002 = I6002(1) + 3;
        Achartrim(I5002:I6002) = [];
    end
end
%% Read formatted data
data = textscan(Achartrim, '%d');
data{1}(1:4) = []; %ignore the first 4 values (not voltage samples)
Achartrim2 = Achar((Iend+4):end);
footer = textscan(Achartrim2,'%s'); % Read in remaining footer info
fclose(fid);
%% Get timing information
footStampLabels = {'LogStartMDHTime', 'LogStopMDHTime'};
for i = 1:length(footStampLabels)
    labelStr = footStampLabels{i};
    labelIdx = find(strcmp(footer{1},[labelStr,':']))+1; % position of this timestamp in 'footer'
    pulse.(labelStr) = str2double(footer{1}{labelIdx}); % store the timestamp in data structure
end
%% read in all values from data vector in .puls file
pulse.all = data{1}; 
%% Find peak values (pulse.all==5000) 
% assume immediate previous value to be the peak, remove 5000s from data
pulse.I5000 = find(pulse.all==5000); % Siemens peaks
pulse.peaks = zeros(size(pulse.all));
pulse.peaks(pulse.I5000-1)= 1; % Estimated true peak
%% Save final structure values
pulse.data = double(pulse.all); % Pulse data
pulse.data(pulse.I5000) = [];
pulse.data_dmean = pulse.data - mean(pulse.data); % de-mean pulse.data
pulse.peaks(pulse.I5000) = [];
pulse.nSamps = length(pulse.data);
pulse.dur = pulse.LogStopMDHTime - pulse.LogStartMDHTime; % Duration of pulse data (msec)
pulse.sampT = pulse.dur/(pulse.nSamps-1); % Sampling period in time (msec)
pulse.sampTsecs = pulse.sampT/1000; % Sampling period in time (seconds)
pulse.sampR = round(1000/pulse.sampT); % Sampling rate (Hz)
pulse.AT_ms = pulse.LogStartMDHTime + (0:pulse.nSamps-1)*pulse.sampT;
pulse.delta = round(mean(diff(pulse.I5000))); % heartrate in no. of samples
pulse.bpm   = 60e3/(pulse.delta*pulse.sampT); % heartrate in beats per min