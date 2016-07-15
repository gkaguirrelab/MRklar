function mcSliceTimings(outVol,refVol,slicetimings,mcDir)

% Creates a 4D volume of motion corrected slice timings
%
%   Usage:
%   mcSliceTimings(outVol,refVol,slicetimings,mcDir)
%
%   Inputs:
%   outVol          - output 4D volume of motion corrected slice timings
%   refVol          - 4D fMRI volume (in the space of interest)
%   slicetimings    - text (or .mat) file of slice timings
%   mcDir           - directory containing .lta transformation files
%
%   Written by Andrew S Bock Jul 2016

%% Create temporarly folder
tmpDir = fullfile(mcDir,'tmp');
mkdir(tmpDir);
%% Create single TR volume
tmpVol = fullfile(tmpDir,'singleTR.nii.gz');
system(['fslroi ' refVol ' ' tmpVol ' 0 1']);
%% read inputs
tmp         = load_nifti(tmpVol); % temporary volume to save 3D data
st          = load(slicetimings); % slice timings file
ltaFiles    = listdir(fullfile(mcDir,'*.lta'),'files'); % motion correction files
%% Save a 3D volume of slice timings
for i = 1:length(st)
    tmp.vol(:,:,i) = st(i);
end
save_nifti(tmp,fullfile(tmpDir,'singleST.nii.gz'));
%% Motion correct
mergeCommand = ['fslmerge -t ' outVol];
for i = 1:length(ltaFiles)
    % Apply the motion correction transformation, as is done using
    % 'mri_robust_register'
    system(['mri_convert -at ' fullfile(mcDir,ltaFiles{i}) ' ' ...
        fullfile(tmpDir,'singleST.nii.gz') ' ' fullfile(tmpDir,sprintf('%04d.nii.gz',i)) ...
        ' -rt cubic']);
    mergeCommand = [mergeCommand ' ' fullfile(tmpDir,sprintf('%04d.nii.gz',i))];
end
system(mergeCommand);