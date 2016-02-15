function skull_strip(session_dir,subject_name)

% Creates skull stripped file MPRAGE_brain.nii.gz using FreeSurfer tools

%% Set default parameters
if ~exist('session_dir','var')
    error('"session_dir" not defined');% must define a session_dir
end
if ~exist('subject_name','var')
    error('"subject_name" not defined');% must define a session_dir
end

SUBJECTS_DIR = getenv('SUBJECTS_DIR');

%% Add to log
SaveLogInfo(session_dir, mfilename,session_dir,subject_name);

%% Skullstrip structual file using Freesurfer
if exist(fullfile(session_dir,'MP2RAGE'),'dir')
    disp('Skull stripping anatomical using bbregister');
    % Register using bbregister
    filefor_reg = fullfile(session_dir,'MP2RAGE','004','MP2RAGE.nii.gz'); % Anatomical file for bbregister
    bbreg_out_file = fullfile(session_dir,'MP2RAGE','004','bbreg.dat'); % name of registration file
    mask_file = fullfile(session_dir,'MP2RAGE','004','MP2RAGE_mask'); % mask file
    bbreg_cmd = ['bbregister --s ' subject_name ' --mov ' filefor_reg ' --reg ' bbreg_out_file ' --init-fsl --t1'];
    disp(['Executing: "' bbreg_cmd '"']);
    [~,~] = system(bbreg_cmd);
    bbreg_dat = load(fullfile(session_dir,'MP2RAGE','004','bbreg.dat.mincost'));
    mincost = bbreg_dat(1);
    disp('The min cost value of MP2RAGE registration was:')
    disp(num2str(mincost));
    if mincost > 0.6
        % adjust poor registration
        [~,~] = system(['tkregister2 --mov ' filefor_reg ' --reg ' bbreg_out_file ' --surf']);
        [~,~] = system(['bbregister --s ' subject_name ' --mov ' filefor_reg ' --reg ' bbreg_out_file ' --init-reg ' ...
            bbreg_out_file ' --t1']);
        bbreg_dat = load(fullfile(session_dir,'MP2RAGE','004','bbreg.dat.mincost'));
        mincost = bbreg_dat(1);
        disp('The min cost value of MP2RAGE registration was:')
        disp(num2str(mincost));
        if mincost > 0.6
            input('Registration is still poor, proceed anyway?');
        end
    end
    % Project 'brain.mgz' to subject's anatomical space
    [~,~] = system(['mri_vol2vol --mov ' filefor_reg ' --targ ' ...
        fullfile(SUBJECTS_DIR,subject_name,'mri','brain.mgz') ' --o ' ...
        mask_file ' --reg ' bbreg_out_file ' --inv --nearest']);
    % Fill any holes in brainmask file
    mask = load_nifti(mask_file);
    newmask = fill_in_holes_inside_brain(mask.vol,10);
    mask.vol = newmask;
    save_nifti(mask,mask_file);
    % Mask original anatomical file using 'brain.mgz' to skull strip
    out_file = fullfile(session_dir,'MP2RAGE','004','MP2RAGE_brain.nii.gz'); % brain extracted output file
    [~,~] = system(['fslmaths ' filefor_reg ' -mas ' mask_file ' ' out_file]);    
elseif exist(fullfile(session_dir,'MPRAGE'),'dir')
    disp('Skull stripping anatomical using bbregister');
    % Register using bbregister
    filefor_reg = fullfile(session_dir,'MPRAGE','001','MPRAGE.nii.gz'); % Anatomical file for bbregister
    bbreg_out_file = fullfile(session_dir,'MPRAGE','001','bbreg.dat'); % name of registration file
    mask_file = fullfile(session_dir,'MPRAGE','001','MPRAGE_mask.nii.gz'); % mask file
    [~,~] = system(['bbregister --s ' subject_name ' --mov ' filefor_reg ' --reg ' bbreg_out_file ' --init-fsl --t1']);
    bbreg_dat = load(fullfile(session_dir,'MPRAGE','001','bbreg.dat.mincost'));
    mincost = bbreg_dat(1);
    disp('The min cost value of MPRAGE registration was:')
    disp(num2str(mincost));
    if mincost > 0.6
        % adjust poor registration
        [~,~] = system(['tkregister2 --mov ' filefor_reg ' --reg ' bbreg_out_file ' --surf']);
        [~,~] = system(['bbregister --s ' subject_name ' --mov ' filefor_reg ' --reg ' bbreg_out_file ' --init-reg ' ...
            bbreg_out_file ' --t1']);
        bbreg_dat = load(fullfile(session_dir,'MPRAGE','001','bbreg.dat.mincost'));
        mincost = bbreg_dat(1);
        disp('The min cost value of MPRAGE registration was:')
        disp(num2str(mincost));
        if mincost > 0.6
            input('Registration is still poor, proceed anyway?');
        end
    end
    % Project 'brain.mgz' to subject's anatomical space
    [~,~] = system(['mri_vol2vol --mov ' filefor_reg ' --targ ' ...
        fullfile(SUBJECTS_DIR,subject_name,'mri','brain.mgz') ' --o ' ...
        mask_file ' --reg ' bbreg_out_file ' --inv --nearest']);
    % Fill any holes in brainmask file
    mask = load_nifti(mask_file);
    newmask = fill_in_holes_inside_brain(mask.vol,10);
    mask.vol = newmask;
    save_nifti(mask,mask_file);
    % Mask original anatomical file using 'brain.mgz' to skull strip
    out_file = fullfile(session_dir,'MPRAGE','001','MPRAGE_brain.nii.gz'); % brain extracted output file
    [~,~] = system(['fslmaths ' filefor_reg ' -mas ' mask_file ' ' out_file]);    
end
disp('done.');