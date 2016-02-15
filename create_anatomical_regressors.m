function [PCAout] = create_anatomical_regressors(session_dir,runNum,func,maskNames,PCAmaxNcomp)

% Calculates the Principal Components associated with anatomical ROIs
%
%   Usage:
%   [PCAout] = create_anatomical_regressors(session_dir,runNum,func,maskNames)
%
%   defaults:
%   func = 'rf;
%   maskNames = {...
%         'wm' ...
%         'lh_ventricle' ...
%         'rh_ventricle' ...
%         'third_ventricle' ...
%         'fourth_ventricle' ...
%         'brainstem' ...
%         'unknown' ...
%         };
%   tf = 1; % use temporally filtered version of func (e.g. rf.tf.nii.gz)
%   PCAmaxNcomp = 5; % number of components to retain
%
%   Code based on scripts written by Marta Vidorreta Díaz de Cerio
%   Written by Andrew S Bock Nov 2015

%% Set defaults
if ~exist('func','var')
    func = 'rf';
end
if ~exist('maskNames','var')
    maskNames = {...
        'wm' ...
        'lh_ventricle' ...
        'rh_ventricle' ...
        'third_ventricle' ...
        'fourth_ventricle' ...
        'brainstem' ...
        'unknown' ...
        };
end
if ~exist('PCAmaxNcomp','var')
    PCAmaxNcomp = 5;
end
%% Find bold run directories
d = find_bold(session_dir);

%%
disp(['Load functional timecoures and ROIs from ' fullfile(session_dir,d{runNum}) '...']);
% Load the timecourse for this run, then detrend
fmri = load_nifti(fullfile(session_dir,d{runNum},[func '.nii.gz']));
dims=size(fmri.vol);
tc = reshape(fmri.vol,dims(1)*dims(2)*dims(3),dims(4));
tc = tc';
mtc = mean(tc); % save means (will be removed using 'detrend')
dtc = detrend(tc); % remove linear trend from timecourses
newtc = zeros(size(dtc));
for m = 1:size(dtc,2)
    newtc(:,m) = dtc(:,m) + mtc(m); % add mean
end
tc = newtc;
%% Loop through masks
masktcs = [];
for i = 1:length(maskNames)
    tmp = load_nifti(fullfile(session_dir,d{runNum},['func.aseg.' maskNames{i} '.nii.gz']));
    masktcs = [masktcs,tc(:,logical(tmp.vol(:)))];
end
% Demean and zscore for pca
PCAnormat = zscore(masktcs);
% Find the first 5 Principal Components
[COEFF,SCORE,latent] = princomp(PCAnormat);%,'econ'); %already gives the PCA components in descending order according to their eigenvalues (latent)
varexp    = latent./sum(latent);
%     varexpcum = cumsum(latent)./sum(latent);
%     Ncomp = find((cumsum(latent)./sum(latent)) >= 0.95,1); %Retain the components that together explain at least 95% of variance
Ncomp = numel(find(varexp >= 0.01)); %Retain the components that explain at least 5% of the variance
fprintf('\n- PCA computed on PCA mask voxels. %d components found that explain >1%% of var (fixed to = %d).\n',Ncomp, PCAmaxNcomp);
disp(['Varianced explained by first ' num2str(PCAmaxNcomp) ' components:' num2str(sum(varexp(1:PCAmaxNcomp)))]);
%     Outcomp = min(PCAmaxNcomp, Ncomp);
Outcomp = PCAmaxNcomp;
PCAout = SCORE(:,1:Outcomp)*COEFF(1:Outcomp,1:Outcomp)'; %Equivalent to [~,PCArec] = pcares(PCAnormat,Ncomp);