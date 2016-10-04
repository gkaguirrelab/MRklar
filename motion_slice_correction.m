function motion_slice_correction(params,runNum)

% Remove large spikes, corrects slice timings, and corrects head motion
%
%   Usage:
%       motion_slice_correction(params,runNum)
%
%   Required:
%       params.sessionDir       = '/path/to/session/directory'
%
%   Defaults:
%       params.despike          = 1; % params.despike data
%       params.slicetiming      = 1; % do slice timing correction
%       params.refvol           = 1; % reference volume = 1st TR
%
%   Optional:
%       params.regFirst         = 1; % register to the first run
%       params.topup            = 1; % use FSL's topup for distortion correction
%
%   Written by Andrew S Bock June 2016

%% Set default parameters
if ~isfield(params,'despike')
    params.despike              = 1; % params.despike data
end
if ~isfield(params,'slicetiming')
    params.slicetiming          = 1; % do slice timing correction
end
if ~isfield(params,'refvol')
    params.refvol               = 1; % reference volume = 1st TR
end
% Find bold run directories
d = find_bold(params.sessionDir);
%% Remove spikes
if params.despike
    remove_spikes(fullfile(params.sessionDir,d{runNum},'raw_f.nii.gz'),...
        fullfile(params.sessionDir,d{runNum},'despike_f.nii.gz'),fullfile(params.sessionDir,d{runNum},'raw_f_spikes'));
end
%% Slice timing correction
if params.slicetiming
    if params.despike
        inFile                  = fullfile(params.sessionDir,d{runNum},'despike_f.nii.gz');
    else
        inFile                  = fullfile(params.sessionDir,d{runNum},'raw_f.nii.gz');
    end
    outFile                     = fullfile(params.sessionDir,d{runNum},'f.nii.gz');
    timingFile                  = fullfile(params.sessionDir,d{runNum},'slicetiming');
    slice_timing_correction(inFile,outFile,timingFile);
end
%% Run motion correction
if params.slicetiming
    mcParams.mcFile             = fullfile(params.sessionDir,d{runNum},'f.nii.gz');
    mcParams.regFile            = fullfile(params.sessionDir,d{1},'f.nii.gz');
elseif params.despike
    mcParams.mcFile             = fullfile(params.sessionDir,d{runNum},'despike_f.nii.gz');
    mcParams.regFile            = fullfile(params.sessionDir,d{1},'despike_f.nii.gz');
else
    mcParams.mcFile             = fullfile(params.sessionDir,d{runNum},'raw_f.nii.gz');
    mcParams.regFile            = fullfile(params.sessionDir,d{1},'raw_f.nii.gz');
end
mcParams.outFile                = fullfile(params.sessionDir,d{runNum},'rf.nii.gz');
mcParams.outDir                 = fullfile(params.sessionDir,d{runNum});
if isfield(params,'regFirst') && params.regFirst
    mcParams.dstFile            = fullfile(params.sessionDir,d{runNum},'dstFile.nii.gz');
    system(['fslroi ' mcParams.regFile ' ' mcParams.dstFile ' ' num2str(params.refvol-1) ' 1']);
end
if isfield(params,'topup') && params.topup
    if ~isempty(strfind(d{runNum},'_AP'))
        mcParams.phaseFile      = fullfile(params.sessionDir,'SpinEchoFieldMap','SpinEchoFieldMap_AP_01.nii.gz');
        mcParams.warpFile       = fullfile(params.sessionDir,'SpinEchoFieldMap','PhaseOneWarp.nii.gz');
    elseif ~isempty(strfind(d{runNum},'_PA'))
        mcParams.phaseFile      = fullfile(params.sessionDir,'SpinEchoFieldMap','SpinEchoFieldMap_PA_01.nii.gz');
        mcParams.warpFile       = fullfile(params.sessionDir,'SpinEchoFieldMap','PhaseTwoWarp.nii.gz');
    else
        error('No warp direction found in bold directory name');
    end
end
mri_robust_register(params,mcParams);