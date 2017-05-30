function register_func(session_dir,subject_name,runNum,despike,func)

% Registers functional runs in to freesurfer anatomical, following
% 'motion_slice_correction'
%
% Usage:
%   register_func(session_dir,subject_name,runNum,despike,func)
%
% Defaults:
%   despike = 1; % despike data
%   func = 'rf'
%
% Outputs (in each bold directory):
%   func_bbreg.dat - registration text file
% if despike
%   <func>_spikes.mat - cell matrix, non-empty cells contain the location
%   of spikes in "filtered_func_data.nii.gz"
%   <func>_spikes.nii.gz - binary volume, where non-zero values indicate
%   the location of spikes in "filtered_func_data.nii.gz"
%
%   Written by Andrew S Bock Dec 2014

%% Set default parameters
if ~exist('despike','var')
    despike = 1; % despike data
end
if ~exist('func','var')
    func = 'rf'; % functional data file
end
%% Find bold run directories
d = find_bold(session_dir);
nruns = length(d);
disp(['Session_dir = ' session_dir]);
disp(['Number of runs = ' num2str(nruns)]);
%% Set runs
if ~exist('runNum','var')
    runNum = 1:length(d);
end
%% Copy over files from feat directory
for rr = runNum
    if despike
        disp('Despiking filtered functional data');
        remove_spikes(fullfile(session_dir,d{rr},[func '.nii.gz']),...
            fullfile(session_dir,d{rr},[func '.nii.gz']),fullfile(session_dir,d{rr},[func '_spikes']));
    end
end
%% Register functional to freesurfer anatomical
progBar = ProgressBar(nruns, 'Registering functional runs to freesurfer anatomical...');
for rr = runNum
    filefor_reg = fullfile(session_dir,d{rr},[func '.nii.gz']); % Functional file for bbregister
    bbreg_out_file = fullfile(session_dir,d{rr},'func_bbreg.dat'); % name registration file
    acq_type = 't2';
    bbregister(subject_name,filefor_reg,bbreg_out_file,acq_type);
    progBar(rr);
end