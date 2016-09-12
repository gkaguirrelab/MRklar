function create_submit_functional_script(params)

% Writes shell script to submit preprocess functional MRI data on the UPenn
% cluster.
%
%   Usage:
%   create_submit_functional_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% Make scripts
fname = fullfile(params.outDir,['submit_' params.jobName '_functional.sh']);
fid = fopen(fname,'w');
for rr = 1:params.numRuns
    if rr < 10
        runtext = ['0' num2str(rr)];
    else
        runtext = num2str(rr);
    end
    fprintf(fid,['qsub -l h_vmem=' num2str(params.fmem) ...
        '.2G,s_vmem=' num2str(params.fmem) 'G -e ' params.logDir ' -o ' params.logDir ' ' ...
        fullfile(params.outDir,[params.jobName '_functional_' runtext '.sh']) '\n']);
end
fclose(fid);