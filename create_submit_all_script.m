function create_submit_all_script(params)

% Writes shell script to submit preprocess anatomical and fMRI data on the 
%   UPenn cluster.
%
%   Usage:
%   create_submit_all_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% set defaults
fname = fullfile(params.outDir,['submit_' params.jobName '_all.sh']);
fid = fopen(fname,'w');
%% Add all scripts
fprintf(fid,['qsub -l h_vmem=' num2str(params.fmem) ...
    '.2G,s_vmem=' num2str(params.fmem) 'G -e ' params.logDir ' -o ' params.logDir ' ' ...
    fullfile(params.outDir,[params.jobName '_all.sh'])]);
fclose(fid);