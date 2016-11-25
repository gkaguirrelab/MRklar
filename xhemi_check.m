function xhemi_check(session_dir,subject_name,SUBJECTS_DIR)

% Checks that xhemireg and surfreg have been run for the specified
% freesurfer subject.  If not, this function runs those commands.
%
%   Usage: xhemi_check(session_dir,subject_name,SUBJECTS_DIR)
%
%   Written by Andrew S Bock Feb 2015

%% Set defaults
if ~exist('session_dir','var')
    error('No ''session_dir'' defined')
end
if ~exist('subject_name','var')
    error('No ''subject_name'' defined')
end
if ~exist('SUBJECTS_DIR','var')
    SUBJECTS_DIR = getenv('SUBJECTS_DIR');
end
anatdatadir = fullfile(SUBJECTS_DIR,subject_name);
%% Check for xhemireg and fsaverage_sym registration
disp('Checking for xhemi and fsaverage_sym registration');
if ~exist(fullfile(anatdatadir,'xhemi'),'dir')
    disp('No xhemi directory, running xhemireg')
    system(['xhemireg --s ' subject_name ' --reg']);
end
if ~exist(fullfile(anatdatadir,'surf','lh.fsaverage_sym.sphere.reg'),'file')
    disp('No fsaverage_sym.sphere.reg, running registration')
    system(['surfreg --s ' subject_name ' --t fsaverage_sym --lh']);
    system(['surfreg --s ' subject_name ' --t fsaverage_sym --xhemi --lh']);
end
disp('done.');