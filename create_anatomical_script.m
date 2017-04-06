function create_anatomical_script(params)

% Writes shell script to preprocess anatomical MRI data
%
%  MaxMelPaper update: call to ToolboxToolbox tbUse at the beginning of the
%  script. Needs params.tbConfig (GF) 
% 
%   Usage:
%   create_anatomical_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% Create job script
fname = fullfile(params.outDir,[params.jobName '_anatomical.sh']);
fid = fopen(fname,'w');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,['TBCONFIG=' params.tbConfig '\n\n']);
fprintf(fid,['SESS=' params.sessionDir '\n']);
fprintf(fid,['SUBJ=' params.subjectName '\n\n']);
matlab_string = '"';
if params.reconall % If a new subject, for which recon-all has not been run
    fprintf(fid,'matlab -nodisplay -nosplash -r "tbUse(''$TBCONFIG'');sort_nifti(''$SESS'');"\n');
    fprintf(fid,'recon-all -i $SESS/MPRAGE/001/ACPC/MPRAGE.ACPC.nii.gz -s $SUBJ -all\n');
else
    matlab_string = [matlab_string 'tbUse(''$TBCONFIG'');sort_nifti(''$SESS'');'];
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
