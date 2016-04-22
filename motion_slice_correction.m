function motion_slice_correction(session_dir,despike,SliceTiming,refvol)

%   Removes large spikes (>7*RMSE), runs motion and slice timing 
%   correction. 
%
%   Usage:
%   motion_slice_correction(session_dir,despike,SliceTiming,refvol)
%
%   Defaults:
%     despike = 1; % default will despike data
%     SliceTiming = 1; do slice timing correction (custom script)
%
%   Written by Andrew S Bock June 2014
%
% 12/15/14      spitschan       Output to be run in the shell also saved in
%                               file.

%% Set default parameters
if ~exist('despike','var')
    despike = 1; % despike data
end
if ~exist('SliceTiming','var')
    SliceTiming = 1; % do slice timing correction
end
if ~exist('refvol','var')
    refvol = 1; % do slice timing correction
end
%% Find bold run directories
d = find_bold(session_dir);
nruns = length(d);
%% Remove spikes
if despike
    progBar = ProgressBar(nruns,['Removing spikes from ' nruns ' runs...']);
    for rr = 1:nruns
        remove_spikes(fullfile(session_dir,d{rr},'raw_f.nii.gz'),...
            fullfile(session_dir,d{rr},'despike_f.nii.gz'),fullfile(session_dir,d{rr},'raw_f_spikes'));
        progBar(rr);
    end
end
%% Slice timing correction
if SliceTiming
    for rr = 1:nruns
        if despike
            inFile = fullfile(session_dir,d{rr},'despike_f.nii.gz');
        else
            inFile = fullfile(session_dir,d{rr},'raw_f.nii.gz');
        end
        outFile = fullfile(session_dir,d{rr},'f.nii.gz');
        timingFile = fullfile(session_dir,d{rr},'slicetiming');
        slice_timing_correction(inFile,outFile,timingFile);
    end
end
%% Run motion correction
for rr = 1:nruns
    if SliceTiming
        inFile = fullfile(session_dir,d{rr},'f.nii.gz');
    elseif despike
        inFile = fullfile(session_dir,d{rr},'despike_f.nii.gz');
    else
        inFile = fullfile(session_dir,d{rr},'raw_f.nii.gz');
    end
    outFile = fullfile(session_dir,d{rr},'rf.nii.gz');
    mcflirt(inFile,outFile,refvol);
end