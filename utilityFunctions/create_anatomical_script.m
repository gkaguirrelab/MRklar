function create_anatomical_script(params)

% Writes shell script to preprocess anatomical MRI data
%
%   Usage:
%   create_anatomical_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% set defaults
SUBJECTS_DIR = getenv('SUBJECTS_DIR');

%% Create job script
fname = fullfile(params.outDir,[params.jobName '_anatomical.sh']);
fid = fopen(fname,'w');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,['SESS=' params.sessionDir '\n']);
fprintf(fid,['SUBJ=' params.subjectName '\n']);
fprintf(fid,['dicomDir=' params.dicomDir '\n']);
fprintf(fid,['useMRIcron=' num2str(params.useMRIcron) '\n']);
fprintf(fid,['isGE=' num2str(params.isGE) '\n\n']);
matlab_string = '"';
if params.reconall % If a new subject, for which recon-all has not been run
    fprintf(fid,['matlab -nodisplay -nosplash -r ' ...
        '"sort_nifti(''$SESS'',''$dicomDir'',$useMRIcron,$isGE);"\n']);
    if params.isGE
        fprintf(fid,'recon-all -i $SESS/MPRAGE/001/MPRAGE.nii.gz -s $SUBJ -autorecon1\n');
        fprintf(fid,['mri_convert ' ...
            fullfile(SUBJECTS_DIR,params.subjectName,'mri','T1.mgz') ' ' ...
            fullfile(SUBJECTS_DIR,params.subjectName,'mri','T1.nii.gz') '\n']);
        fprintf(fid,['bet ' ...
            fullfile(SUBJECTS_DIR,params.subjectName,'mri','T1.nii.gz') ' ' ...
            fullfile(SUBJECTS_DIR,params.subjectName,'mri','brainmask.nii.gz') ' -f 0.35 -R\n']);
        fprintf(fid,['mri_convert ' ...
            fullfile(SUBJECTS_DIR,params.subjectName,'mri','brainmask.nii.gz') ' ' ...
            fullfile(SUBJECTS_DIR,params.subjectName,'mri','brainmask.mgz') '\n']);
        fprintf(fid,'recon-all -s $SUBJ -autorecon2 -autorecon3\n');
    else
        fprintf(fid,'recon-all -i $SESS/MPRAGE/001/ACPC/MPRAGE.ACPC.nii.gz -s $SUBJ -all\n');
    end
else
    matlab_string = [matlab_string ...
        'sort_nifti(''$SESS'',''$dicomDir'',$useMRIcron,$isGE);'];
end
matlab_string = [matlab_string ...
    'skull_strip(''$SESS'',''$SUBJ'');' ...
    'segment_anat(''$SESS'',''$SUBJ'');' ...
    'xhemi_check(''$SESS'',''$SUBJ'');'];
if params.topup
    matlab_string = [matlab_string 'topup(''$SESS'');'];
end
matlab_string = [matlab_string '"'];
fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
fclose(fid);
