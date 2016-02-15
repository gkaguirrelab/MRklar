function [pulsMatch] = matchPulsFile(dicomDir,pulsDir)

% Finds the associated .puls file to the input dicom directory
%
%   Usage:
%   [pulsMatch] = matchPulsFile(dicomDir,pulsDir)
%
%   Output:
%   pulsMatch = puls file associated with the input pulsDir.
%
%   Example:
%   session_dir = /path/to/some/session_dir/
%   runNum = 1;
%   d = find_bold(session_dir);
%   dicomDir = fullfile(session_dir,'DICOMS',d{runNum});
%   pulsDir = fullfile(session_dir,'PulseOx');
%   pulsFiles = listdir(fullfile(pulsDir,'*.puls'),'files');
%   [pulsMatch] = matchPulsFile(dicomDir,pulsDir);
%   PulseResp(dicomDir,pulsMatch,outDir);
%
%   Written by Andrew S Bock Nov 2015

%% Get the acquistion time from the dicom files
disp('Finding associated .puls file for input dicom directory');
dicoms = listdir(dicomDir,'files');
for t = 1:length(dicoms)
    dicom.info = dicominfo(fullfile(dicomDir,dicoms{t}));
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
if length(dicoms)>1
    dicom.AT(1) = dicom.AT(2) - dicom.TR_all(2);
end
%% Get the start and stop times from the .puls
pulsFiles = listdir(pulsDir,'files');
numPulsFiles = length(pulsFiles);
pulsTimes = cell(numPulsFiles,1);
for f=1:numPulsFiles
    % choose a puls file
    pulsFile = fullfile(pulsDir,pulsFiles{f});
    [~,~,ext] = fileparts(pulsFile);
    switch ext
        case '.log'
            pulse = read_PULS_log_file(pulsFile);
        case '.puls'
            pulse = read_PMU_file(pulsFile);
    end
    pulsTimes{f} = pulse.AT_ms; % Time when pulse signal was received (msec since midnight)
    clear pulse
end
%% Find the matching puls file
potentialPuls = zeros(length(pulsTimes),1);
for i = 1:length(pulsTimes)
    if ~isempty(pulsTimes{i})
        pLength = length(pulsTimes{i});
        %     if pulsTimes{i}(1) <= dicom.AT(1) && pulsTimes{i}(end) >=dicom.AT(end)
        if pulsTimes{i}(round(pLength/2)) > dicom.AT(1) && pulsTimes{i}(round(pLength/2)) <dicom.AT(end)
            potentialPuls(i) = 1;
        end
    end
end
pulsMatch = [];
switch sum(potentialPuls)
    case 0
        disp('NO .puls MATCH FOUND!');
    case 1
        pulsMatch = fullfile(pulsDir,pulsFiles{logical(potentialPuls)});
        disp(['Dicom Dir - ' dicomDir]);
        disp(['Pulse Match - ' pulsMatch]);
    case 2
        disp('MULTIPLE .puls MATCHES FOUND!');
end