function feat_mc(session_dir,run_feat,despike,SliceTiming,B0,warp_dir,design_dir,design_file)

%   Removes large spikes (>7*RMSE), runs FEAT for motion correction, slice
%   time correction, B0 correction. Design_dir provides the path to the
%   file "feat_mc_template.fsf", a template FEAT design file for batch
%   processing.
%
%   Usage:
%   feat_mc(session_dir,run_feat,despike,SliceTiming,B0,warp_dir,design_dir,design_file))
%
%   Defaults:
%     run_feat = 0; % don't run FEAT immediately, just create design file
%     despike = 1; % default will despike data
%     SliceTiming = 1; do slice timing correction (custom script)
%     B0 = 0; % don't do b0 unwarping
%     warp_dir = 'y';
%     design_dir = same directory as 'feat_spikes.m'
%     design_file = 'feat_mc_template.fsf';
%     SUBJECTS_DIR = '/Applications/freesurfer/subjects';
%
%   Written by Andrew S Bock June 2014
%
% 12/15/14      spitschan       Output to be run in the shell also saved in
%                               file.

%% Set default parameters
if ~exist('run_feat','var')
    run_feat = 0; % run FEAT from matlab.  Alternative is '0', in case you want to run from the terminal, e.g. if on a cluster
end
if ~exist('despike','var')
    despike = 1; % despike data
end
if ~exist('SliceTiming','var')
    SliceTiming = 1; % do slice timing correction
end
if ~exist('B0','var')
    B0 = 0; % don't do b0 unwarp
end
if ~exist('warp_dir','var')
    warp_dir = 'y';
end
if ~exist('design_dir','var')
    design_dir = which('feat_mc');
    design_dir = fileparts(design_dir);
end
if ~exist('design_file','var')
    design_file = fullfile(design_dir,'feat_mc_template.fsf');
end
%% Find bold run directories
d = find_bold(session_dir);
nruns = length(d);
%% Remove spikes
if despike
    progBar = ProgressBar(nruns,['Removing spikes from ' nruns ' runs...']);
    for rr = 1:nruns
        remove_spikes(fullfile(session_dir,d{rr},'raw_f.nii.gz'),...
            fullfile(session_dir,d{rr},'despike_f.nii.gz'),fullfile(session_dir,d{rr},'raw_f_spikes'));
        progBar(rr);
    end
end
%% Slice timing correction
if SliceTiming
    for rr = 1:nruns
        if despike
            inFile = fullfile(session_dir,d{rr},'despike_f.nii.gz');
        else
            inFile = fullfile(session_dir,d{rr},'raw_f.nii.gz');
        end
        outFile = fullfile(session_dir,d{rr},'f.nii.gz');
        timingFile = fullfile(session_dir,d{rr},'slicetiming');
        slice_timing_correction(inFile,outFile,timingFile);
    end
end
%% Skullstrip structural file using Freesurfer
if exist(fullfile(session_dir,'MP2RAGE'),'dir')
    out_file = fullfile(session_dir,'MP2RAGE','004','MP2RAGE_brain.nii.gz'); % brain extracted output file
    %skull_strip(session_dir,subject_name);
    DESIGN.STRUCT = out_file;
elseif exist(fullfile(session_dir,'MPRAGE'),'dir')
    out_file = fullfile(session_dir,'MPRAGE','001','MPRAGE_brain.nii.gz'); % brain extracted output file
    %skull_strip(session_dir, subject_name);
    DESIGN.STRUCT = out_file;
end
%% Run FEAT
for rr = 1:nruns
    if SliceTiming
        tmp = load_nifti(fullfile(session_dir,d{rr},'f.nii.gz'));
    elseif despike
        tmp = load_nifti(fullfile(session_dir,d{rr},'despike_f.nii.gz'));
    else
        tmp = load_nifti(fullfile(session_dir,d{rr},'raw_f.nii.gz'));
    end
    DESIGN.OUTPUT = fullfile(session_dir,d{rr},'rf.feat');
    DESIGN.TR = num2str(tmp.pixdim(5)/1000); % TR is in msec, convert to sec
    if tmp.pixdim(5) < 100 % use 100, in case very short TR is used (i.e. multi-band)
        error('TR is not in msec');
    end
    DESIGN.VOLS = num2str(tmp.dim(5));
    DESIGN.B0 = num2str(B0); 
    DESIGN.ECHO_SPACING = num2str(textread(fullfile(session_dir,d{rr},'EchoSpacing')));
    DESIGN.EPI_TE = num2str(textread(fullfile(session_dir,d{rr},'EPI_TE')));
    DESIGN.WARP_DIRECTION = warp_dir;
    DESIGN.SLICE_CORRECTION = '0'; % HARD CODE FSL'S SLICE CORRECTION TO BE 'OFF'
    DESIGN.SLICE_TIMING = fullfile(session_dir,d{rr},'slicetiming');
    DESIGN.STANDARD = DESIGN.STRUCT;
    DESIGN.TOTAL_VOXELS = num2str(tmp.dim(2)*tmp.dim(3)*tmp.dim(4)*tmp.dim(5));
    if despike
        DESIGN.FEAT_DIR = fullfile(session_dir,d{rr},'f');
    else
        DESIGN.FEAT_DIR = fullfile(session_dir,d{rr},'raw_f');
    end
    DESIGN.FIELD_MAP = fullfile(session_dir,'B0','rpsmap');
    DESIGN.MAG = fullfile(session_dir,'B0','mag1_brain');
    fin = fopen(design_file,'rt');
    fout = fopen(fullfile(session_dir,d{rr},'feat_mc.fsf'),'wt');
    fields = fieldnames(DESIGN);
    while(~feof(fin))
        s = fgetl(fin);
        for f = 1:length(fields)
            s = strrep(s,['DESIGN_' fields{f}],DESIGN.(fields{f}));
        end
        fprintf(fout,'%s\n',s);
        %disp(s)
    end
    fclose(fin);
    commandc = ['feat ' fullfile(session_dir,d{rr},'feat_mc.fsf')];
    disp(commandc);
    % Run feat
    if run_feat
        disp('Running:')
        [~,~] = system([commandc ' &']);
    end
    % Also save this out in a file.
    fid = fopen(fullfile(session_dir, 'feat_mc_scripts.sh'), 'a');
    fprintf(fid, '%s\n',commandc);
    fclose(fid);
end