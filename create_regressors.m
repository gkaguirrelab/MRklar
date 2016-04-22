function create_regressors(session_dir,runNum,func,filtType,lowHz,highHz,physio,motion,anat,parfile,dtmotion,maskNames,PCAmaxNcomp)

% creates a nuisance regressor text files, based on physiological noise,
%   motion, and anatomical regressors
%
%   Usage:
%   create_regressors(session_dir,runNum,func,filtType,lowHz,highHz,physio,motion,anat,parfile,dtmotion,maskNames,PCAmaxNcomp)
%
%   defaults:
%   func = 'rf'; % input functional file
%   filtType = 'detrend';
%   lowHz = 0.01; % only used if 'filtType' = 'high' or 'band'
%   highHz = 0.1; % only used if 'filtType' = 'low' or 'band'
%   physio = 1; % create physiological noise regressors
%   motion = 1; % create motion regressors
%   anat = 1; % create anatomical regressors (5 principal components)
%   parfile = [func '_all_motion_params.par']; % copied output from feat
%   dtmotion = 1; % detrend motion parameters
%   tfanat = 1; % use the temporally filtered functional input (e.g.
%       'brf.tf.nii.gz') for anatomical regressors.  Note this takes 'brf' as
%       the actual input, to avoid issues with anatomical ROI naming
%       conventions.
%   maskNames = {...
%         'wm' ...
%         'lh_ventricle' ...
%         'rh_ventricle' ...
%         'third_ventricle' ...
%         'fourth_ventricle' ...
%         'brainstem' ...
%         'unknown' ...
%         }; % for use with anatomical ROIs
%
%   NOTE:
%   output motion regressors are scaled by 100 (for motion) and
%   1000 (for motion^2), to avoid possible issues with any
%   subsequent regression.
%
%   Written by Andrew S Bock Oct 2014

%% Setup initial variables
if ~exist('func','var')
    func = 'rf'; % functional data file used for registration
end
if ~exist('filtType','var')
    filtType = 'detrend';
end
if ~exist('lowHz','var')
    lowHz = 0.01;
end
if ~exist('highHz','var')
    highHz = 0.1;
end
if ~exist('physio','var')
    physio = 1;
end
if ~exist('motion','var')
    motion = 1;
end
if ~exist('anat','var')
    anat = 1;
end
if ~exist('parfile','var')
    parfile = [func '_all_motion_params.par'];
end
if ~exist('dtmotion','var')
    dtmotion = 1; % detrend motion params
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
feat_dir = [func '.feat']; % feat directory
%% Find bold run directories
d = find_bold(session_dir);

%% Create regressors
for rr = runNum;
    %% copy over the motion correction parameters
    copyfile(fullfile(session_dir,d{rr},feat_dir,'mc','prefiltered_func_data_mcf.par'),...
        fullfile(session_dir,d{rr},[func '_all_motion_params.par']));
    copyfile(fullfile(session_dir,d{rr},feat_dir,'mc','prefiltered_func_data_mcf_abs.rms'),...
        fullfile(session_dir,d{rr},[func '_absolute_motion_params.par']));
    %% Create Noise Regressors
    disp(['Creating Nuisance Regressors: Run ' num2str(rr)]);
    %% Create physiological noise regressors
    if physio
        % Create physiological regressors
        outDir = fullfile(session_dir,d{rr});
        dicomDir = fullfile(session_dir,'DICOMS',d{rr});
        pulsDir = fullfile(session_dir,'PulseOx');
        [pulsMatch] = matchPulsFile(dicomDir,pulsDir);
        if ~isempty(pulsMatch)
            pulse = PulseResp(dicomDir,pulsMatch,outDir);
        else
            pulse.all = [];
        end
        switch filtType
            case 'high'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [pulse.all] = filter_signal(pulse.all,filtType,TR,lowHz,highHz);
            case 'low'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [pulse.all] = filter_signal(pulse.all,filtType,TR,lowHz,highHz);
            case 'band'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [pulse.all] = filter_signal(pulse.all,filtType,TR,lowHz,highHz);
        end
        pulse.all = detrend(pulse.all);
        dlmwrite(fullfile(outDir,'pulse_params.txt'),pulse.all,'delimiter',' ','precision','%10.5f')
        % The above 'PulseResp' step created a file called 'puls.mat' in the
        % run directory
    end
    %% Create motion regressors
    if motion
        outDir = fullfile(session_dir,d{rr});
        % Following Friston et al. (1996) (Friston 24-parameter model);
        % Load 6 motion parameters from feat
        tmpm = load(fullfile(session_dir,d{rr},parfile));
        % Convert radians to mm (assume 50mm radius) (see Power et al.
        % (2012) NeuroImage, 59, 2142 - 2154)
        tmpm(:,1:3) = 50*tmpm(:,1:3);
        % Create the 6 motion parameters one time point before
        tmpm_1 = [zeros(size(tmpm(1,:)));tmpm(1:end-1,:)];
        % Combine motion parameters, and the corresponding squared values
        %   scale params to avoid issues with precision
        motion_params = [100*tmpm,100*tmpm_1,1000*tmpm.^2,1000*tmpm_1.^2];
        % Remove mean and linear trend
        switch filtType
            case 'high'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [motion_params] = filter_signal(motion_params,filtType,TR,lowHz,highHz);
            case 'low'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [motion_params] = filter_signal(motion_params,filtType,TR,lowHz,highHz);
            case 'band'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [motion_params] = filter_signal(motion_params,filtType,TR,lowHz,highHz);
        end
        if dtmotion
            motion_params = detrend(motion_params);
        end
        dlmwrite(fullfile(outDir,'motion_params.txt'),motion_params,'delimiter',' ','precision','%10.5f')
    end
    %% Create anatomical Principal Components regressors
    if anat
        outDir = fullfile(session_dir,d{rr});
        [PCAout] = create_anatomical_regressors(session_dir,rr,func,maskNames,...
            PCAmaxNcomp);
        switch filtType
            case 'high'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [PCAout] = filter_signal(PCAout,filtType,TR,lowHz,highHz);
            case 'low'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [PCAout] = filter_signal(PCAout,filtType,TR,lowHz,highHz);
            case 'band'
                tmp = load_nifti(fullfile(outDir,[func '.nii.gz']));
                TR = tmp.pixdim(5)/1000;
                if TR < .1
                    error('TR is <.1, most likely header is not in msec');
                end
                [PCAout] = filter_signal(PCAout,filtType,TR,lowHz,highHz);
        end
        PCAout = detrend(PCAout);
        dlmwrite(fullfile(outDir,'anat_params.txt'),PCAout,'delimiter',' ','precision','%10.5f')
    end
end