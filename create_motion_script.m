function create_motion_script(params)

% Writes shell script to motion correct fMRI data
%
%   Usage:
%   create_motion_script(params)
%
%   Written by Andrew S Bock Jul 2016

%% Create job script
for rr = 1:params.numRuns
    if rr < 10
        runtext = ['0' num2str(rr)];
    else
        runtext = num2str(rr);
    end
    fname = fullfile(params.outDir,[params.jobName '_motion_' runtext '.sh']);
    fid = fopen(fname,'w');
    fprintf(fid,'#!/bin/bash\n');
    fprintf(fid,['SESS=' params.sessionDir '\n']);
    fprintf(fid,['runNum=' num2str(rr) '\n\n']);
    matlab_string = ([...
        '"motion_slice_correction(''$SESS'',1,' num2str(params.slicetiming) ...
        ',$runNum,' num2str(params.refvol) ',' num2str(params.regFirst) ');"']);
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
end
