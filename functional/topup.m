function topup(sessionDir,tParams)

% Calls FSL's 'topup' command, creates the necessary inputs to apply
% distortion correction to a 4D fMRI volume
%
%   Usage:
%       topup(sessionDir,tParams);
%
%   Defaults:
%       tParams.PhaseOne        = fullfile(params.sessionDir,'SpinEchoFieldMap',...
%         'SpinEchoFieldMap_AP_01.nii.gz');
%       tParams.PhaseTwo        = fullfile(params.sessionDir,'SpinEchoFieldMap',...
%         'SpinEchoFieldMap_PA_01.nii.gz');
%       tParams.outDir          = fullfile(params.sessionDir,'SpinEchoFieldMap';
%       tParams.dwellTime       = 0.00058;
%       tParams.txtfname        = fullfile(params.outDir,'acqparams.txt');
%       tParams.config          = fullfile(params.outDir,'b02b0.cnf');
%       tParams.coeffName       = fullfile(params.outDir,'coefficents');
%       tParams.fieldName       = fullfile(params.outDir,'topupField');
%       tParams.magName         = fullfile(params.outDir,'magnitudes');
%       tParams.warpName        = fullfile(params.outDir,'warpField');
%       tParams.motName         = fullfile(params.outDir,'motionMatrix');
%       tParams.jacName         = fullfile(params.outDir,'jacobian');
%
%   Written by Andrew S Bock Sep 2016

%% set defaults
if ~exist('tParams','var')
    tParams                 = [];
end
if ~isfield(tParams,'PhaseOne')
    tParams.PhaseOne        = fullfile(sessionDir,'SpinEchoFieldMap',...
        'SpinEchoFieldMap_AP_01.nii.gz');
end
if ~isfield(tParams,'PhaseTwo')
    tParams.PhaseTwo        = fullfile(sessionDir,'SpinEchoFieldMap',...
        'SpinEchoFieldMap_PA_01.nii.gz');
end
if ~isfield(tParams,'outDir')
    tParams.outDir          = fullfile(sessionDir,'SpinEchoFieldMap');
end
if ~isfield(tParams,'dwellTime')
    tParams.dwellTime       = 0.00058;
end
if ~isfield(tParams,'txtfname')
    tParams.txtfname        = fullfile(tParams.outDir,'acqparams.txt');
end
if ~isfield(tParams,'config')
    tParams.config          = 'b02b0.cnf';
end
if ~isfield(tParams,'coeffName')
    tParams.coeffName       = fullfile(tParams.outDir,'coefficents');
end
if ~isfield(tParams,'fieldName')
    tParams.fieldName       = fullfile(tParams.outDir,'topupField');
end
if ~isfield(tParams,'magName')
    tParams.magName         = fullfile(tParams.outDir,'magnitudes');
end
if ~isfield(tParams,'warpName')
    tParams.warpName        = fullfile(tParams.outDir,'warpField');
end
if ~isfield(tParams,'motName')
    tParams.motName         = fullfile(tParams.outDir,'motionMatrix');
end
if ~isfield(tParams,'jacName')
    tParams.jacName         = fullfile(tParams.outDir,'jacobian');
end
tParams.BothPhases          = fullfile(tParams.outDir,'BothPhases.nii.gz');
tParams.PhaseOneWarp        = fullfile(tParams.outDir,'PhaseOneWarp.nii.gz');
tParams.PhaseTwoWarp        = fullfile(tParams.outDir,'PhaseTwoWarp.nii.gz');
%% Get params
[~,dimtOne]                 = system(['fslval ' tParams.PhaseOne ' dim4']);
[~,dimtTwo]                 = system(['fslval ' tParams.PhaseTwo ' dim4']);
[~,dimy]                    = system(['fslval ' tParams.PhaseOne ' dim2']);
ro_time                     = tParams.dwellTime * (str2double(dimy) - 1); % Total_readout = Echo_spacing*(%of_PE_steps-1)
%% Merge the phase images
system(['fslmerge -t ' tParams.BothPhases ' ' tParams.PhaseOne ' ' tParams.PhaseTwo]);

%% Create 'acqparams.txt' file
for i = 1:str2double(dimtOne)
    system(['echo "0 -1 0 ' num2str(ro_time) '" >> ' tParams.txtfname]);
end
for i = 1:str2double(dimtTwo)
    system(['echo "0 1 0 ' num2str(ro_time) '" >> ' tParams.txtfname]);
end
%% Topup
system(['topup --imain=' tParams.BothPhases ' --datain=' tParams.txtfname ...
    ' --config=' tParams.config ' --out=' tParams.coeffName ...
    ' --fout=' tParams.fieldName ' --iout=' tParams.magName ...
    ' --dfout=' tParams.warpName ' --rbmout=' tParams.motName ...
    ' --jacout=' tParams.jacName ' -v']);
%% Create files for distortion correction (done in 'mri_robust_register')
system(['cp ' tParams.warpName '_01.nii.gz ' tParams.PhaseOneWarp]);
system(['cp ' tParams.warpName '_0' num2str(1 + str2double(dimtOne)) '.nii.gz ' tParams.PhaseTwoWarp]);