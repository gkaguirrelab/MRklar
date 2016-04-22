function create_preprocessing_scripts(session_dir,subject_name,outDir,logDir,job_name,numRuns,reconall,slicetiming,refvol,filtType,lowHz,highHz,physio,motion,task,localWM,anat,amem,fmem)

% Writes shell scripts to preprocess MRI data on the UPenn cluster.
%
%   Usage:
%   create_preprocessing_scripts(session_dir,subject_name,outDir,logDir,job_name,numRuns,reconall,slicetiming,refvol,filtType,lowHz,highHz,physio,motion,task,localWM,anat,amem,fmem)
%
%   Defaults:
%   reconall = 0; run recon-all (default - off)
%   slicetiming = 1; correct slice timings
%   B0 = 0; B0 unwarping (default - off)
%   filtType = 'high'; highpass filter
%   lowHz = 0.01; % note - only applies when filtType = 'high' or 'band'
%   highHz = 0.10; % note - only applies when filtType = 'low' or 'band'
%   physio = 0; physiological noise removal from pulseOx (default - off)
%   motion = 1; noise removal from motion
%   task = 0; orthogonalization to task regressors (default - off)
%   localWM = 1; removal of noise derived from local white matter (default - on)
%   anat = 1; removal of noise derived from anatomical ROIs
%   amem = 20; memory for anatomical scripts
%   fmem = 50; memory for functional scripts
%
%   Example:
%   session_dir = '/data/jet/abock/data/Network_Connectivity/ASB/11042015';
%   subject_name = 'A101415B'; % Freesurfer subject name (may not match job_name)
%   outDir = '/data/jet/abock/cluster_shell_scripts/preprocessing_scripts/ASB';
%   logDir = '/data/jet/abock/LOGS';
%   job_name = 'A110415B'; % Name for this job/session (may not match subject_name)
%   numRuns = 22; % number of bold runs
%   reconall = 0;
%   slicetiming = 1; % correct slice timings
%   refvol = 1; % motion correct to 1st TR
%   filtType = 'high';
%   lowHz = 0.01;
%   highHz = 0.10;
%   physio = 1;
%   motion = 1;
%   task = 0;
%   localWM = 1;
%   anat = 1;
%   amem = 20;
%   fmem = 50;
%   create_preprocessing_scripts(session_dir,subject_name,outDir,logDir,...
%       job_name,numRuns,reconall,slicetiming,refvol,filtType,lowHz,highHz,...
%       physio,motion,task,localWM,anat,amem,fmem);
%
%   Written by Andrew S Bock Aug 2015

%% Set defaults
if ~exist('reconall','var')
    reconall = 0;
end
if ~exist('slicetiming','var')
    slicetiming = 1;
end
if ~exist('refvol','var')
    refvol = 1;
end
if ~exist('filtType','var')
    filtType = 'high';
end
if ~exist('lowHz','var')
    lowHz = 0.01;
end
if ~exist('highHz','var')
    highHz = 0.10;
end
if ~exist('physio','var')
    physio = 0;
end
if ~exist('motion','var')
    motion = 1;
end
if ~exist('task','var')
    task = 0;
end
if ~exist('localWM','var')
    localWM = 1;
end
if ~exist('anat','var')
    anat = 1;
end
if ~exist('amem','var')
    amem = 20;
end
if ~exist('fmem','var')
    fmem = 50;
end
%% Add to log
SaveLogInfo(session_dir,mfilename,session_dir,subject_name,outDir,logDir,job_name,numRuns,reconall,slicetiming,refvol,filtType,lowHz,highHz,physio,motion,task,localWM,anat,amem,fmem);

%% Create submit scripts
if ~exist('outDir','dir')
    mkdir(outDir);
end
create_submit_anatomical_script(outDir,logDir,job_name,amem);
create_submit_functional_script(outDir,logDir,job_name,numRuns,fmem);
%% Create job scripts
% anatomical
create_anatomical_script(session_dir,subject_name,outDir,job_name,reconall,slicetiming,refvol);
% functional
create_functional_script(session_dir,subject_name,outDir,job_name,numRuns,filtType,lowHz,highHz,physio,motion,task,localWM,anat);
system(['chmod +x ' fullfile(outDir,'*')]);