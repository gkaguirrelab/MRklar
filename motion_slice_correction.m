function motion_slice_correction(session_dir,despike,sliceTiming,runNums,refvol)

%   Removes large spikes (>7*RMSE), runs motion and slice timing
%   correction.
%
%   Usage:
%   motion_slice_correction(session_dir,despike,sliceTiming,refvol)
%
%   Defaults:
%     despike = 1; % default will despike data
%     SliceTiming = 1; do slice timing correction (custom script)
%
%   Written by Andrew S Bock June 2016

%% Set default parameters
if ~exist('despike','var')
    despike = 1; % despike data
end
if ~exist('SliceTiming','var')
    sliceTiming = 1; % do slice timing correction
end
% Find bold run directories
d = find_bold(session_dir);
if ~exist('runNums','var')
    runNums = 1:length(d);
end
if ~exist('refvol','var')
    refvol = 1; % reference volume = 1st TR
end
%% Remove spikes
if despike
    for rr = runNums
        remove_spikes(fullfile(session_dir,d{rr},'raw_f.nii.gz'),...
            fullfile(session_dir,d{rr},'despike_f.nii.gz'),fullfile(session_dir,d{rr},'raw_f_spikes'));
    end
end
%% Slice timing correction
if sliceTiming
    for rr = runNums
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
for rr = runNums
    if sliceTiming
        inFile = fullfile(session_dir,d{rr},'f.nii.gz');
    elseif despike
        inFile = fullfile(session_dir,d{rr},'despike_f.nii.gz');
    else
        inFile = fullfile(session_dir,d{rr},'raw_f.nii.gz');
    end
    outFile = fullfile(session_dir,d{rr},'rf.nii.gz');
    %mcflirt(inFile,outFile,refvol);
    outDir = fullfile(session_dir,d{rr});
    mri_robust_register(inFile,outFile,outDir,refvol)
end