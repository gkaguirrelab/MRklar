function [EchoSpacing,EPI_TE] = echo_spacing(dcmDir,outDir)

%   Gets the echo spacing (msec) and EPI TE (msec) from an EPI dicom file.
%
%   Usage:
%   [EchoSpacing,EPI_TE] = echo_spacing(dcmDir,outDir)
%
%   Outputs the Echo Spacing and EPI TE as text files.
%
%   Written by Andrew S Bock Feb 2014

%% Get path of repository
repo_path = which('echo_spacing');
repo_path = fileparts(repo_path);
%% Get Dicoms
dicomlist = listdir(dcmDir,'files');
result = GetSiemensExtraInfo(fullfile(dcmDir,dicomlist{end}),fullfile(repo_path,'Mydicom-dict.txt'));
%% Find acceleration factor
AF = result.AF;
if ~isempty(AF)
    AF = str2double(AF);
else
    AF = [];
end
%% Find if Echo Spacing was stored in header (must have been manually set)
%tmpes = split_result(find(not(cellfun('isempty',strfind(split_result,'lEchoSpacing')))));
ESP = result.ESP;
if ~isempty(ESP)
    ESP = str2double(ESP);
else
    ESP = [];
end
%% Find the pixel bandwidth
PBW = dicominfo(fullfile(dcmDir,dicomlist{end}));
PBW = PBW.PixelBandwidth;
%% Calculate Echo Spacing (msec)
if ~isempty(ESP); % Echo spacing stored in header (rare)
    EchoSpacing = ESP/1000; % convert usec to msec
else
    ESP = (1/PBW + .000082)*1000; % convert to echo spacing in msec
    EchoSpacing= ESP/AF; % divide by acceleration factor
end
%% Find EPI TE
EPI_TE = dicominfo(fullfile(dcmDir,dicomlist{end}));
EPI_TE = EPI_TE.EchoTime;
%% Find Acquisution Type (acsending, descending, interleaved)
AT = result.AT;
if ~isempty(AT)
    if strcmp(AT,'0x1')
        AcquisitionType = 'Ascending';
    elseif strcmp(AT,'0x2')
        AcquisitionType = 'Descending';
    elseif strcmp(AT,'0x4')
        AcquisitionType = 'Interleaved';
    else
        AcquisitionType = 'Type_not_recognized';
    end
else
    AcquisitionType = 'sSliceArray.ucMode was empty';
end
%% Save echo spacing and EPI TE as text files
if exist('outDir','var') && ~isempty(outDir)
    system(['echo ' num2str(EchoSpacing) ' > ' fullfile(outDir,'EchoSpacing')]);
    system(['echo ' num2str(EPI_TE) ' > ' fullfile(outDir,'EPI_TE')]);
    system(['echo ' AcquisitionType ' > ' fullfile(outDir,'AcquisitionType')]);
end
