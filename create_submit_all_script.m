function create_submit_all_script(outDir,logDir,job_name,mem)

% Writes shell script to submit preprocess anatomical and fMRI data on the 
%   UPenn cluster.
%
%   Usage:
%   create_submit_all_script(outDir,logDir,job_name,mem)
%
%   Written by Andrew S Bock Nov 2015

%% set defaults
if ~exist('mem','var')
    mem = 42;
end
fname = fullfile(outDir,['submit_' job_name '_all.sh']);
fid = fopen(fname,'w');
%% Add all scripts
fprintf(fid,['qsub -l h_vmem=' num2str(mem) ...
    '.2G,s_vmem=' num2str(mem) 'G -e ' logDir ' -o ' logDir ' ' ...
    fullfile(outDir,[job_name '_all.sh'])]);