function create_submit_functional_script(outDir,logDir,job_name,numRuns,mem)

% Writes shell script to submit preprocess functional MRI data on the UPenn
% cluster.
%
%   Usage:
%   create_submit_functional_script(outDir,logDir,job_name,numRuns,cores,mem)
%
%   Written by Andrew S Bock Nov 2015

%% set defaults
if ~exist('mem','var')
    mem = 42;
end
%% Make scripts
fname = fullfile(outDir,['submit_' job_name '_functional.sh']);
fid = fopen(fname,'w');
for rr = 1:numRuns
    if rr < 10
        runtext = ['0' num2str(rr)];
    else
        runtext = num2str(rr);
    end
    fprintf(fid,['qsub -l h_vmem=' num2str(mem) ...
        '.2G,s_vmem=' num2str(mem) 'G -e ' logDir ' -o ' logDir ' ' ...
        job_name '_functional_' runtext '.sh\n']);
end
fclose(fid);