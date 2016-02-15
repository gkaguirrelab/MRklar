function project_template(session_dir,subject_name,template_files,hemis,SUBJECTS_DIR)

% Projects anatomical template files in fsaverage_sym space to subject
%   native space
%
%   Usage: project_template(session_dir,subject_name,template_files,hemi)
%
%   Written by Andrew S Bock Feb 2015

%% Set defaults
if ~exist('session_dir','var')
    error('No ''session_dir'' defined')
end
if ~exist('subject_name','var')
    error('No ''subject_name'' defined')
end
if ~exist('template_files','var')
    template_files = {...
        '~/data/2014-10-29.eccen-template.nii.gz' ...
        '~/data/2014-10-29.angle-template.nii.gz' ...
        '~/data/2014-10-29.areas-template.nii.gz'};
end
if ~exist('hemis','var');
    hemis = {'lh' 'rh'};
end
if ~exist('SUBJECTS_DIR','var')
    SUBJECTS_DIR = getenv('SUBJECTS_DIR');
end
maps = {'ecc' 'pol' 'areas'};
%% Add to log
SaveLogInfo(session_dir,mfilename,session_dir,subject_name,template_files,hemis)

%% Project retinotopic templates to subject surface space
disp(['session_dir = ' session_dir]);
disp(['subject_name = ' subject_name]);
disp('Projecting retinotopic templates to subject space...');
for hh = 1:length(hemis)
    hemi = hemis{hh};
    for t = 1:length(template_files)
        switch hemi
            case 'lh'
                [~,~] = system(['mri_surf2surf --hemi lh --srcsubject fsaverage_sym --srcsurfval ' ...
                    template_files{t} ' --trgsubject ' subject_name ' --trgsurfval ' ...
                    fullfile(session_dir,['lh.' maps{t} '.nii.gz'])]);
            case 'rh'
                [~,~] = system(['mri_surf2surf --hemi lh --srcsubject fsaverage_sym --srcsurfval ' ...
                    template_files{t} ' --trgsubject ' subject_name '/xhemi --trgsurfval ' ...
                    fullfile(session_dir,['rh.' maps{t} '.nii.gz'])]);
        end
    end
    tmp = load_nifti(fullfile(session_dir,[hemi '.pol.nii.gz']));
    tmp.vol = deg2rad(tmp.vol) - pi/2; % convert to radians
    if strcmp(hemi,'rh')
        upper = tmp.vol>=0;
        lower = tmp.vol<0;
        tmp.vol(upper) = (-tmp.vol(upper) + pi);
        tmp.vol(lower) = (-tmp.vol(lower) - pi);
    end
    save_nifti(tmp,fullfile(session_dir,[hemi '.pol.nii.gz']));
end
%% Project from subject surface space to volume
templatevol = fullfile(SUBJECTS_DIR,subject_name,'mri','T1.mgz');
for hh = 1:length(hemis)
    hemi = hemis{hh};
    for m = 1:length(maps)
        invol = fullfile(session_dir,[hemi '.' maps{m} '.nii.gz']);
        outvol = fullfile(session_dir,[hemi '.' maps{m} '.vol.nii.gz']);
        system(['mri_surf2vol --surfval ' invol ' --hemi ' hemi ' --fillribbon --identity ' ...
            subject_name ' --template ' templatevol ' --o ' outvol]);
    end
end
%% Merge lh and rh into one volume (mh)
for m = 1:length(maps)
    lh = load_nifti(fullfile(session_dir,['lh.' maps{m} '.vol.nii.gz']));
    rh = load_nifti(fullfile(session_dir,['rh.' maps{m} '.vol.nii.gz']));
    mhname = fullfile(session_dir,['mh.' maps{m} '.vol.nii.gz']);
    mh = lh;
    mh.vol = zeros(size(mh.vol));
    mh.vol(lh.vol~=0) = lh.vol(lh.vol~=0);
    mh.vol(rh.vol~=0) = rh.vol(rh.vol~=0);
    sharedind = lh.vol~=0 & rh.vol~=0;
    mh.vol(sharedind) = 0; % set voxels shared by both hemis to zero
    save_nifti(mh,mhname);
end
disp('done.');