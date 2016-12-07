function create_preprocessing_scripts(params)

% Writes shell scripts to preprocess MRI data on the UPenn cluster.
%
%   Usage:
%   create_preprocessing_scripts(params)
%
%   Required:
%       params.sessionDir       = '/full/path/to/sessionDirectory';
%       params.subjectName      = 'freesurferSubjectName';
%       params.outDir           = '/full/path/to/script/outDirectory';
%       params.logDir           = '/full/path/to/logDirectory';
%       params.jobName          = 'jobName'; % typically subjectName
%       params.numRuns          = number of bold runs;
%
%   Defaults:
%       params.dicomDir         = fullfile(params.sessionDir,'DICOMS');
%       params.useMRIcron       = 1;        % if 0, uses FreeSurfer's 'mri_convert'
%       params.isGE             = 0;        % if 1, does not read functions that assume a Siemens header (e.g. 'echo_spacing');
%       params.reconall         = 0;        % if 1, run FreeSurfer's reconall
%       params.despike          = 1;        % remove large spikes from fMRI data
%       params.slicetiming      = 1;        % correct slice timings
%       params.topup            = 0;        % if 1, perform 'topup' distortion correction
%       params.refvol           = 1;        % reference volume number for motion correction
%       params.regFirst         = 1;        % register all runs to first bold run
%       params.filtType         = 'high';   % type of temporal filter
%       params.lowHz            = 0.01;     % only used in 'high' or 'band' temporal filters 
%       params.highHz           = 0.10;     % only used in 'low or 'band' temporal filters
%       params.physio           = 0;        % if 1, physiological noise removal using pulse ox
%       params.motion           = 1;        % noise removal using head motion
%       params.task             = 0;        % orthogonalization to task regressors
%       params.localWM          = 1;        % removal of noise derived from local white matter 
%       params.anat             = 1;        % removal of noise derived from anatomical ROIs  
%       params.amem             = 20;       % memory for anatomical scripts
%       params.fmem             = 50;       % memory for functional scripts
%
%   Example:
%       params.sessionDir       = '/data/jet/abock/data/Network_Connectivity/ASB/11042015';
%       params.subjectName      = 'A101415B'; 
%       params.outDir           = fullfile(params.sessionDir,'preprocessing_scripts');
%       params.logDir           = '/data/jet/abock/LOGS';
%       params.jobName          = params.subjectName;
%       params.numRuns          = 10; % number of bold runs
%       params.dicomDir         = fullfile(params.sessionDir,'DICOMS');
%       params.useMRIcron       = 1;
%       params.isGE             = 0;
%       params.reconall         = 0;
%       params.despike          = 1;
%       params.slicetiming      = 1; 
%       params.topup            = 1;
%       params.refvol           = 1; 
%       params.regFirst         = 1;
%       params.filtType         = 'high';
%       params.lowHz            = 0.01;
%       params.highHz           = 0.10;
%       params.physio           = 1;
%       params.motion           = 1;
%       params.task             = 0;
%       params.localWM          = 1;
%       params.anat             = 1;
%       params.amem             = 20;
%       params.fmem             = 50;
%   create_preprocessing_scripts(params);
%
%   Written by Andrew S Bock Aug 2015

%% Set defaults
if ~isfield(params,'dicomDir')
    params.dicomDir = fullfile(params.sessionDir,'DICOMS');
end
if ~isfield(params,'useMRIcron')
    params.useMRIcron = 1;
end
if ~isfield(params,'isGE')
    params.isGE = 0;
end
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