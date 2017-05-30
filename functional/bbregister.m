function bbregister(subject_name,filefor_reg,bbreg_out_file,acq_type,mincost_thresh,interactive)

% Performs within-subject, cross-modal registration to a subject's
%   corresponding Freesurfer anatomical file
%   ($SUBJECTS_DIR/<subject_name>/mri/orig.mgz) using Freesurfer's
%   bbregister, which uses a boundary-based cost function.
%
% Usage:
%   bbregister(subject_name,filefor_reg,bbreg_out_file,acq_type,mincost_thresh,interactive)
%
% Defaults:
%   bbreg_out_file = 'bbreg.dat'; % in the same directory as filefor_reg
%   acq_type = 't2'; % options are 't1' or 't2' ('bold' and 'dti' are also valid, but are the same as 't2')
%   mincost_thresh = 0.6; % Manually inspects the registration if the
%       mincost is above this value
%
% Written by Andrew S Bock Dec 2014

%% Set default parameters
% get file path
[file_path] = fileparts(filefor_reg);
% set defaults
if ~exist('subject_name','var')
    error('"subject_name" not defined');% must define a freesurfer subject name
end
if ~exist('filefor_reg','var')
    error('"filefor_reg" not defined');% must define a file for registration
end
if ~exist('bbreg_out_file','var')
    bbreg_out_file = fullfile(file_path,'bbreg.dat');
end
if ~exist('acq_type','var')
    acq_type = 't2'; % options are 't1','t2' ('bold' and 'dti' are also valid, but are the same as 't2')
end
if ~exist('mincost_thresh','var')
    mincost_thresh = 0.65;
end
if ~exist('interactive','var')
    interactive = 1; % relevant if mincost > mincost_thresh, asks for user input to proceed
end

%% Run bbregister
disp(['Performing registration of ' filefor_reg ' using bbregister...']);
system(['bbregister --s ' subject_name ' --mov ' filefor_reg ...
    ' --reg ' bbreg_out_file ' --init-fsl --' acq_type]);
%% Check the registration
mincost = load([bbreg_out_file '.mincost']);
mincost = mincost(1);
disp(['The min cost value of registration for ' filefor_reg ':'])
disp(num2str(mincost));
%% If registration is poor (mincost > 0.6), manually inspect and update the registration
if mincost > mincost_thresh || isnan(mincost)
    system(['tkregister2 --mov ' filefor_reg ' --reg ' bbreg_out_file ' --surf']);
    system(['bbregister --s ' subject_name ' --mov ' filefor_reg ...
        ' --reg ' bbreg_out_file ' --init-reg ' ...
        bbreg_out_file ' --' acq_type]);
    mincost = load([bbreg_out_file '.mincost']);
    mincost = mincost(1);
    disp(['The min cost value of registration for ' filefor_reg ':'])
    disp(num2str(mincost));
    if mincost > mincost_thresh
        if interactive
            input('Registration is still poor, proceed anyway?');
        end
    end
end
