%% Template script for preprocessing MRI data using MRklar
%
%   Required software:
%       Freesurfer, FSL
%       IMPORTANT:
%           start matlab from terminal, so environmental variables, 
%               libraries are set correctly
%           add $FREESURFER_HOME/matlab to your matlab path
%
%   Directory structure:
%       data_directory -> project directory -> subject directory ->
%           session directory -> dicom directory
%
%           e.g. ~/data/Retinotopy/ASB/10012014/DICOMS
%
%       If physiological measures are collected, using the following 
%           directory structure:
%
%       data_directory -> project directory -> subject directory ->
%           session directory -> physio directory
%
%           e.g. ~/data/Retinotopy/ASB/10012014/PulseOx
%
%   I recommend creating a project specific master file in a separate 
%   directory. For example, copy this MASTER.m file to a project 
%   specific folder:
%
%   /User/Shared/Matlab/<project_name>/<project_name>_MASTER.m
%
%   Written by Andrew S Bock Dec 2014

%% Create shell scripts
%    The entire MRklar pipeline can be run using shell scripts, which are
%    created using the 'create_preprocessing_scripts' function
%
%   Example:
% session_dir = '/some/session/dir';
% outDir = fullfile(session_dir,'preprocessing_scripts');
% if ~exist(outDir,'dir')
%     mkdir(outDir);
% end
% numRuns = 6; % number of bold runs
% reconall = 1;
% slicetiming = 1; % correct slice timings
% refvol = 1; % motion correct to 1st TR
% filtType = 'detrend';
% lowHz = 0.01;
% highHz = 0.10;
% physio = 1;
% motion = 1;
% task = 0;
% localWM = 1;
% anat = 1;
% amem = 20;
% fmem = 50;
% create_preprocessing_scripts(session_dir,subject_name,outDir,logDir,...
%     job_name,numRuns,reconall,slicetiming,refvol,filtType,lowHz,highHz,...
%     physio,motion,task,localWM,anat,amem,fmem);
%% Define session and subject
session_dir = '~/data/Retinotopy/ASB/10012014/'; % session directory
subject_name = 'A102714B'; % Freesurfer subject name
%% Sort dicoms, convert to nifti
% Sort dicoms into series specific directories, converts dicoms to nifti
sort_nifti(session_dir);
%% Freesurfer Reconstruction
% If the subject has not been run through the Freesurfer recon-all
%   pipeline, run this step.  If the subject aleady exists, you can skip.
%   Note: this will take 9-24 hours, depending on the CPU.
system(['recon-all -i ' fullfile(session_dir,'MPRAGE','001','ACPC',...
    'MPRAGE.ACPC.nii.gz') ' -s ' subject_name ' -all']);
%% B0 fieldmap
% Creates a B0 field map, and brain extracts the magnitude image by
%   registering that image to the freesurfer "brain.mgz" image. If a B0
%   image was not acquired, you can skip.
make_fieldmap(session_dir,subject_name);
%% Brain extract T1 image
% Creates skull stripped file 'MPRAGE_brain.nii.gz' using FreeSurfer tools
skull_strip(session_dir,subject_name);
%% Segment freesurfer aseg.mgz volume
% Segments the freesurfer anatomical aseg.mgz volume into several ROIs in
%   the session_dir, to be used later for noise removal.
segment_anat(session_dir,subject_name);
%% Cross-hemisphere and fsaverage_sym registration
% Checks that 'xhemireg' and 'surfreg' have been run for the specified
%   freesurfer subject.  If not, this function runs those commands.
xhemi_check(session_dir,subject_name);
%% Motion correction
% Motion correct functional runs. This script has several options, such as 
%   despikeing and slice timing correction.  
motion_slice_correction(session_dir);
%% Register functional runs to anatomical image
% Registers the motion corrected and B0 unwarped functional volumes from
%   feat_mc to the corresponding Freesurfer anatomical image for the bold 
%   directory specified by 'runNum'. 
register_feat(session_dir,subject_name,runNum);
%% Project anatomical ROIs to functional space
% Projects anatomical ROIs into functional space for the bold directory
%   specified by 'runNum'.
project_anat2func(session_dir,runNum);
%% Create regressors for noise removal
% Creates a nuisance regressor text file for the bold directory
%   specified by 'runNum', based on physiological noise and motion. If a 
%   task-design, an option exists to make the motion parameters orthogonal 
%   to the task.
create_regressors(session_dir,runNum);
%% Remove noise
% Removes physiological and other non-neuronal noise regressors for the 
%   bold directory specified by 'runNum'
remove_noise(session_dir,runNum);
%% Local White Matter
% Removes the average local white matter signal in the functional volume 
%   for the bold directory specified by 'runNum'
remove_localWM(session_dir,runNum);
%% Temporal filter
% Temporally filters the bold data, based on a specified filter (see help), 
%   for the bold directory specified by 'runNum'
temporal_filter(session_dir,runNum);
%% Spatially smooth functional data
% Spatially smooths the functional data in the volume and on the surface,
%   using a Gaussian kernel (default = 5mm).
smooth_vol_surf(session_dir,runNum);