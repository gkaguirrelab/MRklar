function create_preprocessing_scripts(params)

% Writes shell scripts to preprocess MRI data on the UPenn cluster.
%
%   Usage:
%   create_preprocessing_scripts(params)
%
%   params field names:
%   params.sessionDir       = full path to session directory
%   params.subjectName      = freesurfer subject name
%   params.outDir           = full path to script output directory
%   params.logDir           = full path to log file directory
%   params.jobName          = job name (typically subjectName)
%   params.numRuns          = number of functional runs
%   params.reconall         = run FreeSurfer's reconall                         (default = 0)
%   params.despike          = remove large spikes from fMRI data                (default = 1)
%   params.slicetiming      = correct slice timings                             (default = 1)
%   params.topup            = perform 'topup' distortion correction             (default = 0)
%   params.refvol           = reference volume number for motion correction     (default = 1)
%   params.regFirst         = register all runs to first bold run               (default = 1)
%   params.filtType         = type of temporal filter                           (default = 'high')
%   params.lowHz            = only used in 'high' or 'band' temporal filters    (default = 0.01) 
%   params.highHz           = only used in 'low or 'band' temporal filters      (default = 0.1) 
%   params.physio           = physiological noise removal using pulse ox        (default = 0)
%   params.motion           = noise removal using head motion                   (default = 1)
%   params.task             = orthogonalization to task regressors              (default = 0)
%   params.localWM          = removal of noise derived from local white matter  (default = 1)
%   params.anat             = removal of noise derived from anatomical ROIs     (default = 1)
%   params.amem             = memory for anatomical scripts                     (default = 20)
%   params.fmem             = memory for functional scripts                     (default = 50)
%
%   Example:
%   params.sessionDir       = '/data/jet/abock/data/Network_Connectivity/ASB/11042015';
%   params.subjectName      = 'A101415B'; 
%   params.outDir           = fullfile(params.sessionDir,'preprocessing_scripts');
%   params.logDir           = '/data/jet/abock/LOGS';
%   params.jobName          = params.subjectName;
%   params.numRuns          = 10; % number of bold runs
%   params.reconall         = 0;
%   params.despike          = 1;
%   params.slicetiming      = 1; 
%   params.topup            = 1;
%   params.refvol           = 1; 
%   params.regFirst         = 1;
%   params.filtType         = 'high';
%   params.lowHz            = 0.01;
%   params.highHz           = 0.10;
%   params.physio           = 1;
%   params.motion           = 1;
%   params.task             = 0;
%   params.localWM          = 1;
%   params.anat             = 1;
%   params.amem             = 20;
%   params.fmem             = 50;
%   create_preprocessing_scripts(params);
%
%   Written by Andrew S Bock Aug 2015

%% Set defaults
if ~isfield(params,'reconall')
    params.reconall = 0;
end
if ~isfield(params,'despike')
    params.despike = 1;
end
if ~isfield(params,'slicetiming')
    params.slicetiming = 1;
end
if ~isfield(params,'topup')
    params.topup = 0;
end
if ~isfield(params,'refvol')
    params.refvol = 1;
end
if ~isfield(params,'regFirst')
    params.regFirst = 1;
end
if ~isfield(params,'filtType')
    params.filtType = 'high';
end
if ~isfield(params,'lowHz')
    params.lowHz = 0.01;
end
if ~isfield(params,'highHz')
    params.highHz = 0.10;
end
if ~isfield(params,'physio')
    params.physio = 0;
end
if ~isfield(params,'motion')
    params.motion = 1;
end
if ~isfield(params,'task')
    params.task = 0;
end
if ~isfield(params,'localWM')
    params.localWM = 1;
end
if ~isfield(params,'anat')
    params.anat = 1;
end
if ~isfield(params,'amem')
    params.amem = 20;
end
if ~isfield(params,'fmem')
    params.fmem = 50;
end
%% Add to log
diary ON;
logFile = fullfile(params.sessionDir,'LOG');
diary(logFile);
disp('create_preprocessing_scripts');
disp('params = ');
disp(params);
diary OFF;
%% Create submit scripts
if ~exist(params.outDir,'dir')
    mkdir(params.outDir);
end
% anatomical
create_submit_anatomical_script(params);
% motion correction
create_submit_motion_script(params);
% functional
create_submit_functional_script(params);
% anatomical, motion correction, and functional (i.e. 'all')
create_submit_all_script(params)
%% Create job scripts
% anatomical
create_anatomical_script(params);
% motion correction
create_motion_script(params);
% functional
create_functional_script(params);
% anatomical, motion correction, and functional (i.e. 'all')
create_all_script(params);