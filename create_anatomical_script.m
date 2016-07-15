function create_anatomical_script(session_dir,subject_name,outDir,job_name,reconall)

% Writes shell script to preprocess anatomical MRI data
%
%   Usage:
%   create_anatomical_script(session_dir,subject_name,outDir,job_name,reconall,slicetiming,refvol)
%
%   Written by Andrew S Bock Nov 2015

%% Create job script
fname = fullfile(outDir,[job_name '_anatomical.sh']);
fid = fopen(fname,'w');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,['SESS=' session_dir '\n']);
fprintf(fid,['SUBJ=' subject_name '\n\n']);
if reconall % If a new subject, for which recon-all has not been run
    fprintf(fid,'matlab -nodisplay -nosplash -r "sort_nifti(''$SESS'');"\n');
    fprintf(fid,'recon-all -i $SESS/MPRAGE/001/ACPC/MPRAGE.ACPC.nii.gz -s $SUBJ -all\n');
    matlab_string = ([...
        '"skull_strip(''$SESS'',''$SUBJ'');' ...
        'segment_anat(''$SESS'',''$SUBJ'');' ...
        'xhemi_check(''$SESS'',''$SUBJ'');"']);
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
else
    matlab_string = ([...
        '"sort_nifti(''$SESS'');' ...
        'skull_strip(''$SESS'',''$SUBJ'');' ...
        'segment_anat(''$SESS'',''$SUBJ'');' ...
        'xhemi_check(''$SESS'',''$SUBJ'');"']);
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
end
fclose(fid);
