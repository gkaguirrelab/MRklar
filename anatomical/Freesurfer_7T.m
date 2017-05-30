function Freesurfer_7T(T1_img,subject_name,res,run_full,lowres_subject)

%   Takes in a T1 image (e.g. MPRAGE.nii.gz) and runs custom
%   autorecon1 steps in the Freesurfer pipeline for data acquired at 7T.
%   Optionally, you can run the remaining autorecon2 and autorecon3 steps
%   here using the 'run_full' flag.
%
%   Usage:
%   Freesurfer_7T(T1_img,subject_name,res,run_full,lowres_subject)
%
%   Example:
%   T1_img = fullfile(session_dir,'MPRAGE/001/ACPC/MPRAGE.ACPC.nii.gz');
%   subject_name = 'ASB';
%   Freesurfer_7T(T1_img,subject_name);
%
%   It is recommended that the input T1 image be first ACPC aligned. If
%   using my respository, this is done using the "sort_nifti" function, 
%   which calls "ACPC".
%
%   If using an MP2RAGE input image, it is assumed that the noisy
%   background has already been removed. If using my respository, this is 
%   done using the 'MP2RAGE_bkgnd' function. The input image for 
%   "Freesurfer_7T" will be the image "MP2RAGE_nobg.nii.gz".   
%
%   Note: to run high resolution reconstruction, you need to first run a
%   low resolution image through the pipeline first
%
%   Note: if 'run_full' is not specified (or set to 0), you can run the
%   remaining recon-all steps from a terminal using:
%
%   recon-all -autorecon2 -autorecon3 -s <subject_name>
%
%   defaults:
%   res - 'low' <default>, or 'high' (<1mm)
%   run_full - 0 <default>, or 1 (which will also run autorecon2 and 3)
%   SUBJECTS_DIR = getenv('SUBJECTS_DIR');
%   FREESURFER_HOME = getenv('FREESURFER_HOME');
%
%   If ACPC alignment is not done, or if your luck is bad, you may have
%   issues with talairach registration. It may help to check, manually
%   adjust, and re-run the talairach registration, and then proceed to
%   later steps.  This can be done using:
%
%   tkregister2 --mgz --s <subject> --fstal % checks talairach registration
%   recon-all -talairach -s <subject> % re-runs talairach registration%
%
%   Written by Andrew S Bock Sept 2014

%% Set up defaults
if ~exist('res','var')
    res = 'low'; % alternative is "high" for <1mm resolution
end
if ~exist('run_full','var')
    run_full = 0;
end
SUBJECTS_DIR = getenv('SUBJECTS_DIR');
FREESURFER_HOME = getenv('FREESURFER_HOME');
%% Low Resolution (=1mm)
if strcmp('low',res)
    % Motion correct and align to talairach space
    % Note, ACPC alignment of the T1 image helps avoid issues with
    % talairach registration
    system(['recon-all -motioncor -talairach -tal-check -i ' T1_img ...
        ' -s ' subject_name]);
    % Correcting intensity non-uniformity
    mri_dir = fullfile(SUBJECTS_DIR,subject_name,'mri');
    system(['mri_nu_correct.mni --i ' fullfile(mri_dir,'orig.mgz') ' --o ' ...
        fullfile(mri_dir,'nu.mgz') ' --proto-iters 1000 --distance 15 ' ...
        ' --fwhm 0.15 --n 1 --uchar ' ...
        fullfile(mri_dir,'transforms','talairach.xfm')]);
    % Normalization
    system(['recon-all -normalization -s ' subject_name]);
    % Register to average brain for skull strip
    system(['mri_em_register -skull ' fullfile(mri_dir,'nu.mgz') ' ' ...
        fullfile(FREESURFER_HOME,'average','RB_all_withskull_2008-03-26.gca') ...
        ' ' fullfile(mri_dir,'transforms','talairach_with_skull.lta')]);
    % Skull strip
    system(['mri_watershed -T1 -atlas -h 35 -brain_atlas ' ...
        fullfile(FREESURFER_HOME,'average','RB_all_withskull_2008-03-26.gca') ...
        ' ' fullfile(mri_dir,'transforms','talairach_with_skull.lta') ' ' ...
        fullfile(mri_dir,'T1.mgz') ' ' fullfile(mri_dir,'brainmask.auto.mgz')]);
    % Copy brainmask.auto.mgz to brainmask.mgz (just to stay consistent
    % with typical Freesurfer pipeline
    system(['cp ' fullfile(mri_dir,'brainmask.auto.mgz') ' ' ...
        fullfile(mri_dir,'brainmask.mgz')]);
    %% High Resolution (<1mm)
elseif strcmp('high',res)
    system(['recon-all -cm -motioncor -talairach -tal-check -i ' ...
        T1_img ' -s ' subject_name]);
    % Correcting intensity non-uniformity
    mri_dir = fullfile(SUBJECTS_DIR,subject_name,'mri');
    system(['mri_nu_correct.mni --i ' fullfile(mri_dir,'orig.mgz') ' --o ' ...
        fullfile(mri_dir,'nu.mgz') ' --proto-iters 1000 --distance 15 ' ...
        ' --fwhm 0.15 --n 1 --uchar ' ...
        fullfile(mri_dir,'transforms','talairach.xfm')]);
    % Normalization
    system(['recon-all -cm -normalization -s ' subject_name]);
    % Use low-res skull stripped volume to make high-res volume
    if ~exist('lowres_subject','var')
        error('No low resolution subject specified')
    end
    lowres_dir = fullfile(SUBJECTS_DIR,lowres_subject);
    system(['mri_convert -rl ' fullfile(mri_dir,'orig.mgz') ' -rt nearest ' ...
        fullfile(lowres_dir,'mri','brain.mgz') ' ' ...
        fullfile(mri_dir,'brainmask.hires.mgz')]);
    system(['mri_mask ' fullfile(mri_dir,'T1.mgz') ' ' ...
        fullfile(mri_dir,'brainmask.hires.mgz') ' ' ...
        fullfile(mri_dir,'brainmask.mgz')]);
end
if run_full
    system(['recon-all -autorecon2 -autorecon3 -s ' subject_name]);
end