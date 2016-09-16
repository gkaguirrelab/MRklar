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
    matlab_string = ([...
        '"params.sessionDir=''' params.sessionDir ''';' ...
        'params.despike=' num2str(params.despike) ';' ...
        'params.slicetiming=' num2str(params.slicetiming) ';' ...
        'params.refvol=' num2str(params.refvol) ';' ...
        'params.regFirst=' num2str(params.regFirst) ';' ...
        'params.topup=' num2str(params.topup) ';' ...
        'motion_slice_correction(params,' num2str(rr) ');"']);
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string]);
end
