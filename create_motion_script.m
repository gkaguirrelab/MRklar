function create_motion_script(session_dir,outDir,job_name,numRuns,slicetiming,refvol)

% Writes shell script to motion correct fMRI data
%
%   Usage:
%   create_motion_script(session_dir,outDir,job_name,numRuns,refvol)
%
%   Written by Andrew S Bock Jul 2016

%% Create job script
for rr = 1:numRuns
    if rr < 10
        runtext = ['0' num2str(rr)];
    else
        runtext = num2str(rr);
    end
    fname = fullfile(outDir,[job_name '_motion_' runtext '.sh']);
    fid = fopen(fname,'w');
    fprintf(fid,'#!/bin/bash\n');
    fprintf(fid,['SESS=' session_dir '\n']);
    fprintf(fid,['runNum=' num2str(rr) '\n\n']);
    matlab_string = ([...
        '"motion_slice_correction(''$SESS'',1,' num2str(slicetiming) ...
        ',$runNum,' num2str(refvol) ');"']);
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
end
