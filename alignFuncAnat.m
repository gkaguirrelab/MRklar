function alignFuncAnat(params)

% Projects a functional volume to anatomical space (no resampling) for all
% bold runs in a session directory
%
%   Usage:
%   alignFuncAnat(params)
%
%   params fields:
%   params.sessionDir   = path of a session directory
%   params.subjectName  = freesurfer subject name
%   params.func         = functional volume (default = 'wdrf.tf.nii.gz')
%   params.bbregName    = registration file (default = 'func_bbreg.dat')
%   params.SUBJECTS_DIR = freesurfer subject directory (default = getenv('SUBJECTS_DIR'))
%
%   Written by Andrew S Bock Sep 2016

%% set defaults
if ~isfield(params,'func')
    params.func         = 'wdrf.tf.nii.gz';
end
if ~isfield(params,'bbregName')
    params.bbregName    = 'func_bbreg.dat';
end
if ~isfield(params,'SUBJECTS_DIR')
    params.SUBJECTS_DIR = getenv('SUBJECTS_DIR');
end
%% Pull out params
boldDirs                = find_bold(params.sessionDir);
%% Project the functional runs to native-anatomical space, but do not resample
for i = 1:length(boldDirs)
    inVol               = fullfile(params.sessionDir,boldDirs{i},params.func);
    targVol             = fullfile(params.SUBJECTS_DIR,params.subjectName,'mri/T1.mgz');
    bbregFile           = fullfile(params.sessionDir,boldDirs{i},params.bbregName);
    outVol              = fullfile(params.sessionDir,boldDirs{i},['a' params.func]);
    system(['mri_vol2vol --mov ' inVol ' --targ ' targVol ...
        ' --reg ' bbregFile ' --o ' outVol ' --no-resample']);
end