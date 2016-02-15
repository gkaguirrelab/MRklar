function create_anatomical_script(session_dir,subject_name,outDir,job_name,reconall,slicetiming,B0)

% Writes shell script to submit preprocess anatomical MRI data on the UPenn
% cluster.
%
%   Usage:
%   create_submit_anatomical_script(outDir,job_name)
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
    if B0
        matlab_string = ([...
            '"make_fieldmap(''$SESS'',''$SUBJ'');skull_strip(''$SESS'',''$SUBJ'');' ...
            'segment_anat(''$SESS'',''$SUBJ'');xhemi_check(''$SESS'',''$SUBJ'');' ...
            'feat_mc(''$SESS'',0,1,' num2str(slicetiming) ',' num2str(B0) ');"']);
    else
        matlab_string = ([...
            '"skull_strip(''$SESS'',''$SUBJ'');' ...
            'segment_anat(''$SESS'',''$SUBJ'');xhemi_check(''$SESS'',''$SUBJ'');' ...
            'feat_mc(''$SESS'',0,1,' num2str(slicetiming) ',' num2str(B0) ');"']);
    end
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
else
    if B0
        matlab_string = ([...
            '"sort_nifti(''$SESS'');make_fieldmap(''$SESS'',''$SUBJ'');skull_strip(''$SESS'',''$SUBJ'');' ...
            'segment_anat(''$SESS'',''$SUBJ'');xhemi_check(''$SESS'',''$SUBJ'');' ...
            'feat_mc(''$SESS'',0,1,' num2str(slicetiming) ',' num2str(B0) ');"']);
    else
        matlab_string = ([...
            '"sort_nifti(''$SESS'');skull_strip(''$SESS'',''$SUBJ'');' ...
            'segment_anat(''$SESS'',''$SUBJ'');xhemi_check(''$SESS'',''$SUBJ'');' ...
            'feat_mc(''$SESS'',0,1,' num2str(slicetiming) ',' num2str(B0) ');"']);
    end
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
end
fclose(fid);
