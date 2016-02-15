function remove_noise(session_dir,runNum,func,remove_task,anat,motion,physio)
% Removes physiological and other non-neuronal noise.
%
%   Usage:
%   remove_noise(session_dir,runNum,func,remove_task,anat,motion,physio)
%
%   Written by Andrew S Bock Apr 2015

%% Set default parameters
if ~exist('func','var')
    func = 'rf'; % functional data file used for registration
end
if ~exist('remove_task','var')
    remove_task = 0; % if '1', regresses out task conditions from motion
end
if ~exist('anat','var')
    anat = 1;  % if '0', won't remove anatomical ROI signals
end
if ~exist('motion','var')
    motion = 1;  % if '0', won't remove motion (and pulse) signals
end
if ~exist('physio','var')
    physio = 1;  % if '0', won't remove motion (and pulse) signals
end
%% In case no noise removal to be done, just return
if ~remove_task && ~anat && ~motion && ~physio
    return
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

%% Load in timecourses
for rr = runNum
    disp(['Load functional timecoures and ROIs from ' fullfile(session_dir,d{rr}) '...']);
    % navigate to the run directory
    cd(fullfile(session_dir,d{rr}));
    % Load the timecourse for this run, already temporally filtered
    fmri = load_nifti(fullfile(session_dir,d{rr},[func '.nii.gz']));
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
    % Load Brain mask
    brain = load_nifti(fullfile(session_dir,d{rr},'func.brainmask.nii.gz'));
    %% Load anatomical regressors
    if ~anat
        anat_noise = [];
    else
        anat_noise = load(fullfile(session_dir,d{rr},'anat_params.txt'));
    end
    %% Load up other nuisance regressors
    if ~motion
        motion_noise = [];
    else
        motion_noise = load(fullfile(session_dir,d{rr},'motion_params.txt'));
        if remove_task
            % Remove task
            bold_dir = fullfile(session_dir,d{rr});
            TR = fmri.pixdim(5)/1000;
            if TR < 0.1
                error('TR is less than 0.1, most likely input nifti TR not in msec')
            end
            lengthTC = size(tc,1);
            % Convert task conditions into timecoures (convolve with HRF) that
            % are at the resolution of the TR.
            [outTC] = convert_task2tc(bold_dir,TR,lengthTC);
            % regress out task from motion
            motion_noise = regress_task(motion_noise,outTC);
        end
    end
    if ~physio
        physio_noise = [];
    else
        physio_noise = load(fullfile(session_dir,d{rr},'pulse_params.txt'));
    end
    noise = [anat_noise,motion_noise,physio_noise];
    % remove any means and linear trends
    noise = detrend(noise);
    %% Calculate global signal
    GB.ind = find(brain.vol);
    GB.tc = mean(tc(:,GB.ind),2);
    GB.tc = detrend(GB.tc); % remove mean and linear trend
    %% Regress out noise
    regressMat = noise;
    [orthmat] = orth(regressMat);
    [Gorthmat] = orth([regressMat,GB.tc]);
    % Remove noise, and noise+global signal
    [oB] = [ones(size(tc,1),1),orthmat]\tc;
    [GoB] = [ones(size(tc,1),1),Gorthmat]\tc;
    orthbeta = oB(2:end,:);
    Gorthbeta = GoB(2:end,:);
    newtc = tc-orthmat*(orthbeta);
    Gnewtc = tc-Gorthmat*(Gorthbeta);
    varr.tc = var(tc);
    varr.all = var(newtc);
    varr.Gall = var(Gnewtc);
    % Save timecourses
    disp('Saving filtered timecourses...');
    newtc = newtc';
    Gnewtc = Gnewtc';
    newtc = reshape(newtc,size(fmri.vol));
    Gnewtc = reshape(Gnewtc,size(fmri.vol));
    % load template file, for use in saving outputs
    dsavename = ['d' func '.nii.gz'];
    fmri.vol = newtc;
    save_nifti(fmri,fullfile(session_dir,d{rr},dsavename));
    gdsavename = ['gd' func '.nii.gz'];
    fmri.vol = Gnewtc;
    save_nifti(fmri,fullfile(session_dir,d{rr},gdsavename));
    % Save varience explained
    varexp.all = 1-(varr.all./varr.tc);
    varexp.Gall = 1-(varr.Gall./varr.tc);
    % create a 3D volume
    system(['fslroi ' fullfile(session_dir,d{rr},[func '.nii.gz']) ...
        ' ' fullfile(session_dir,d{rr},'single_TR.nii.gz') ' 0 1']);
    fmri = load_nifti(fullfile(session_dir,d{rr},'single_TR.nii.gz'));
    % save variance explained volumes
    fmri.vol = reshape(varexp.all,size(fmri.vol));
    save_nifti(fmri,fullfile(session_dir,d{rr},'varexp.all.nii.gz'));
    fmri.vol = reshape(varexp.Gall,size(fmri.vol));
    save_nifti(fmri,fullfile(session_dir,d{rr},'varexp.gall.nii.gz'));
    disp('done.');
end