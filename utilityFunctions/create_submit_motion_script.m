function create_submit_motion_script(params)

% Writes shell script to submit preprocess motion correction of fMRI data 
%   on the UPenn cluster.
%
%   Usage:
%   create_submit_motion_script(params)
%
%   Written by Andrew S Bock Jul 2016

%% Make scripts
fname = fullfile(params.outDir,['submit_' params.jobName '_motion.sh']);
fid = fopen(fname,'w');
for rr = 1:params.numRuns
    if rr < 10
        runtext = ['0' num2str(rr)];
    else
        runtext = num2str(rr);
    end
    fprintf(fid,['qsub -l h_vmem=' num2str(params.fmem) ...
        '.2G,s_vmem=' num2str(params.fmem) 'G -e ' params.logDir ' -o ' params.logDir ' ' ...
        fullfile(params.outDir,[params.jobName '_motion_' runtext '.sh']) '\n']);
end
fclose(fid);