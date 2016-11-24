function mcflirt(params,mcParams)

% Motion correction using FSL's 'mcflirt' command
%
%   Usage:
%   mcflirt(params,mcParams)
%
%   Written by Andrew S Bock Apr 2016

%% Set defaults
outMC = fullfile(mcParams.outDir,'mc');
system(['rm -rf ' outMC]);
mkdir(outMC);
%% Correction motion
system(['mcflirt -in ' mcParams.mcFile ' -out ' mcParams.outFile ' -refvol ' ...
    num2str(params.refvol-1) ' -stats -mats -plots -report -rmsrel -rmsabs']);
system(['mv ' mcParams.outFile '.mat/* ' outMC]);
system(['rm -rf ' mcParams.outFile '.mat']);
%% Save motion params
matFiles = listdir(fullfile(outMC,'MAT_*'),'files');
for i = 1:length(matFiles)
    MATFile = fullfile(outMC,sprintf('MAT_%04d',i-1));
    % Get motion params
    [pitch(i),yaw(i),roll(i),x(i),y(i),z(i)] = convertMAT2tranrot(MATFile);
end
motion_params = [pitch',yaw',roll',x',y',z'];
dlmwrite(fullfile(outMC,'motion_params.txt'),motion_params,'delimiter',' ','precision','%10.5f');
%% Topup
if isfield(params,'topup')
    if params.topup
        % Command to merge file later
        commandc = ['fslmerge -t ' mcParams.outFile];
        % Split input 4D volume into 3D volumes
        system(['fslsplit ' mcParams.outFile ' ' fullfile(outMC,'split_f')]);
        inVols = listdir(fullfile(outMC,'split_f0*'),'files');
        % Register to the reference volume
        dstFile = fullfile(outMC,inVols{params.refvol});
        system(['flirt -dof 6 -interp spline -in ' dstFile ' -ref ' ...
            mcParams.phaseFile ' -omat ' mcParams.dstMat]);
        if isfield(params,'regFirst')
            if params.regFirst
                % first volume to reference volume
                system(['flirt -dof 6 -interp spline -in ' mcParams.phaseFile ' -ref ' ...
                    mcParams.dstFile ' -omat ' fullfile(outMC,'p2d.mat')]);
            end
        end
        progBar = ProgressBar(length(inVols),'correcting distortions...');
        for i = 1:length(inVols)
            inFile = fullfile(outMC,inVols{i});
            outFile = fullfile(outMC,sprintf('tmp_%04d.nii.gz',i));
            MATFile = fullfile(outMC,sprintf('MAT_%04d',i-1));
            % Combine motion correction and registration to fieldmap
            system(['convert_xfm -omat ' fullfile(outMC,sprintf('mcdc%04d.mat',i)) ...
                ' -concat ' mcParams.dstMat ' ' MATFile]);
            % Combine affine registrations and warp
            if ~isfield(params,'regFirst') || params.regFirst
                system(['convertwarp --relout --rel -r ' mcParams.phaseFile ' --premat=' ...
                    fullfile(outMC,sprintf('mcdc%04d.mat',i)) ' --warp1=' mcParams.warpFile ...
                    ' --out=' fullfile(outMC,sprintf('warpField%04d.nii.gz',i))]);
            else
                system(['convertwarp --relout --rel -r ' mcParams.phaseFile ' --premat=' ...
                    fullfile(outMC,sprintf('mcdc%04d.mat',i)) ' --warp1=' mcParams.warpFile ...
                    ' --out=' fullfile(outMC,sprintf('warpField%04d.nii.gz',i)) ...
                    ' --postmat=' fullfile(outMC,'p2d.mat')]);
            end
            % Apply warp
            system(['applywarp --rel --interp=spline -i ' inFile ' -r ' inFile ...
                ' -w ' fullfile(outMC,sprintf('warpField%04d.nii.gz',i)) ' -o ' ...
                outFile]);
            commandc = [commandc ' ' outFile];
            progBar(i);
        end
        % merge files to 4D volume
        system(commandc);
    end
end
%% Clean up
system(['rm ' fullfile(outMC,'*.mat')]); % remove .mat volumes
system(['rm ' fullfile(outMC,'*.nii.gz')]); % remove nifti volumes