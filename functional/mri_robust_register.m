function mri_robust_register(params,mcParams)

% Motion corrects a 4D volume using Freesurfer's 'mri_robust_register'
%
%   Usage:
%   mri_robust_register(params)
%
%   Based on:
%   Highly Accurate Inverse Consistent Registration: A Robust Approach
%   M. Reuter, H.D. Rosas, B. Fischl.
%   NeuroImage 53(4), pp. 1181-1196, 2010.
%
%   Note:
%   params.refvol = 1 is the first volume
%
%   Written by Andrew S Bock May 2016
%% Set defaults
outMC = fullfile(mcParams.outDir,'mc');
if ~exist(outMC,'dir')
    mkdir(outMC);
end
%% Split input 4D volume into 3D volumes
%system(['mri_convert ' params.mcFile ' ' fullfile(outMC,'split_f.nii.gz') ' --split']);
system(['fslsplit ' mcParams.mcFile ' ' fullfile(outMC,'split_f')]);
%system(['fslroi ' params.mcFile ' ' fullfile(outMC,'split_f.nii.gz') ' --split']);
%% Register volumes
inVols = listdir(fullfile(outMC,'split_f0*'),'files');
if ~isfield(params,'regFirst') || ~params.regFirst
    mcParams.dstFile = fullfile(outMC,inVols{params.refvol}); % register to first volume of run
end
progBar = ProgressBar(length(inVols),'mri_robust_registering...');
% Motion correct
if ~isfield(params,'topup') || ~params.topup
    for i = 1:length(inVols)
        inFile = fullfile(outMC,inVols{i});
        outFile = fullfile(outMC,sprintf('tmp_%04d.nii.gz',i));
        [~,~] = system(['mri_robust_register --mov ' inFile ...
            ' --dst ' mcParams.dstFile ' --lta ' fullfile(outMC,sprintf('%04d.lta',i)) ...
            ' --vox2vox --satit --mapmov ' outFile]);
        progBar(i);
    end
else
    % Motion correct and apply distortion correction
    system(['flirt -dof 6 -interp spline -in ' mcParams.dstFile ' -ref ' ...
        mcParams.phaseFile ' -omat ' fullfile(outMC,'dst2dc.mat')]);
    for i = 1:length(inVols)
        inFile = fullfile(outMC,inVols{i});
        outFile = fullfile(outMC,sprintf('tmp_%04d.nii.gz',i));
        % Calculate motion
        [~,~] = system(['mri_robust_register --mov ' inFile ...
            ' --dst ' mcParams.dstFile ' --lta ' fullfile(outMC,sprintf('%04d.lta',i)) ...
            ' --vox2vox --satit']);
        % Convert to FSL style matrix
        system(['tkregister2 --mov ' inFile ' --targ ' mcParams.dstFile ' --check-reg ' ...
            '--lta ' fullfile(outMC,sprintf('%04d.lta',i)) ' --fslregout ' ...
            fullfile(outMC,sprintf('%04d.mat',i)) ' --noedit']);
        % Combine motion correction and registration to fieldmap
        system(['convert_xfm -omat ' fullfile(outMC,sprintf('mcdc%04d.mat',i)) ...
            ' -concat ' fullfile(outMC,sprintf('%04d.mat',i)) ...
            ' ' fullfile(outMC,'dst2dc.mat')]);
        % Combine affine registrations and warp
        system(['convertwarp --relout --rel -r ' mcParams.phaseFile ' --premat=' ...
            fullfile(outMC,sprintf('mcdc%04d.mat',i)) ' --warp1=' mcParams.warpFile ...
            ' --out=' fullfile(outMC,sprintf('warpField%04d.nii.gz',i))]);
        % Apply warp
        system(['applywarp --rel --interp=spline -i ' inFile ' -r ' inFile ...
            ' -w ' fullfile(outMC,sprintf('warpField%04d.nii.gz',i)) ' -o ' ...
            outFile]);
        progBar(i);
    end
end
%% Merge into output 4D volume
commandc = ['fslmerge -t ' mcParams.outFile];
for i = 1:length(inVols)
    outFile = fullfile(outMC,sprintf('tmp_%04d.nii.gz',i));
    commandc = [commandc ' ' outFile];
end
system(commandc);
%% Convert .lta files to translations and rotations
clear x y z pitch yaw roll
ltaFiles = listdir(fullfile(outMC,'*.lta'),'files');
x       = nan(1,length(ltaFiles));
y       = nan(1,length(ltaFiles));
z       = nan(1,length(ltaFiles));
pitch   = nan(1,length(ltaFiles));
yaw     = nan(1,length(ltaFiles));
roll    = nan(1,length(ltaFiles));
for i = 1:length(ltaFiles);
    inFile = fullfile(outMC,ltaFiles{i});
    [x(i),y(i),z(i),pitch(i),yaw(i),roll(i)] = convertlta2tranrot(inFile);
end
motion_params = [pitch',yaw',roll',x',y',z'];
dlmwrite(fullfile(outMC,'motion_params.txt'),motion_params,'delimiter',' ','precision','%10.5f');
%% Clean up
system(['rm ' fullfile(outMC,'*.mat')]); % remove .mat volumes
system(['rm ' fullfile(outMC,'*.nii.gz')]); % remove nifti volumes