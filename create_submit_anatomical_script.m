function create_submit_anatomical_script(params)

% Writes shell script to submit preprocess anatomical MRI data on the UPenn
% cluster.
%
%   Usage:
%   create_submit_anatomical_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% Make scripts
fname = fullfile(params.outDir,['submit_' params.jobName '_anatomical.sh']);
fid = fopen(fname,'w');
fprintf(fid,['qsub -l h_vmem=' num2str(params.amem) ...
    '.2G,s_vmem=' num2str(params.amem) 'G -e ' params.logDir ' -o ' params.logDir ' ' ...
    fullfile(params.outDir,[params.jobName '_anatomical.sh'])]);
fclose(fid);