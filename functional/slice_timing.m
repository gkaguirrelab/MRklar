function slice_timing(dcmDir,outDir)

%   Takes the raw slice time acquistion (msec) from the dicom files.
%
%   Outputs a slice timings file, with units in TRs, with values ranging
%   between 0 and 1, where 0.5 corresponds to no shift in slice timing.
%
%   Written by Andrew S Bock May 2014

%% Get repository directory
repo_path = which('GetSiemensExtraInfo');
repo_path = fileparts(repo_path);
%% Get Dicoms
dicomlist = listdir(dcmDir,'files');
dcmhdr = GetSiemensExtraInfo(fullfile(dcmDir,dicomlist{end}),...
    fullfile(repo_path,'Mydicom-dict.txt'));
%% Find the TR
TR = dcmhdr.RepetitionTime;
%% Find the slice times
ST = dcmhdr.SliceTimings;
%% Convert to TR units
if ~isempty(ST)
    ST = ST/TR;
    % Save slice timings file
    fileName = fullfile(outDir,'slicetiming');
    if exist(fileName,'file')
        system(['rm ' fileName]);
    end
    fid = fopen(fileName,'a');
    fprintf(fid,'%12.4f\n',ST);
    fclose(fid);
end