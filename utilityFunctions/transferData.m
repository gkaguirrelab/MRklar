function transferData(params)

% Transfers data following an fMRI scan to the CfN cluster and Dropbox
%
%   Usage:
%       transferData(params);
%
%   Defaults:
%       params.srcDicom        = '/mnt/rtexport/RTexport_Current';
%       params.srcPulse        = '/mnt/disk_c/MedCom/log/Physio';
%       params.srcProtocols    = '/mnt/disk_c/MedCom/User/Aguirre';
%       params.gradCoeff       = '/mnt/disk_c/MedCom/MriSiteData/GradientCoil/coeff.grad';
%
%   Required inputs (with examples):
%       params.sessionDir      = '/data/jag/TOME/TOME_3003/091616';
%       params.srcSess         = '20160916.819931_TOME_3003_6574.16.09.16_09_18_47_DST_1.3.12.2.1107.5.2.43.66044';
%       params.pulseDate       = 'Physio_20160916';
%       params.protocolName    = 'TOME_3003_Session_2';
%       params.dbDir           = '/Users/abock/Dropbox-Aguirre-Brainard-Lab';
%       params.dbSess          = 'session2_spatialStimuli';
%       params.dbSubject       = 'TOME_3003';
%       params.dbDate          = '091616';
%
%   Written by Andrew S Bock Sep 2016

%% Set defaults
if ~isfield(params,'srcDicom')
    params.srcDicom        = '/mnt/rtexport/RTexport_Current';
end
if ~isfield(params,'srcPulse')
    params.srcPulse        = '/mnt/disk_c/MedCom/log/Physio';
end
if ~isfield(params,'srcProtocols')
    params.srcProtocols    = '/mnt/disk_c/MedCom/User/Aguirre';
end
if ~isfield(params,'gradCoeff')
    params.gradCoeff        = '/mnt/disk_c/MedCom/MriSiteData/GradientCoil/coeff.grad';
end
params.outDicom             = fullfile(params.sessionDir,'DICOMS');
params.outPulse             = fullfile(params.sessionDir,'PulseOx');
params.outProtocols         = fullfile(params.sessionDir,'Protocols');
params.outStimuli           = fullfile(params.sessionDir,'Stimuli');
params.dbScannerFiles       = fullfile(params.dbDir,'TOME_data',params.dbSess,params.dbSubject,params.dbDate,'ScannerFiles');
params.dbPulseOx            = fullfile(params.dbScannerFiles,'PulseOx');
params.dbProtocols          = fullfile(params.dbScannerFiles,'Protocols');
params.dbStimuli            = fullfile(params.dbDir,'TOME_data',params.dbSess,params.dbSubject,params.dbDate,'Stimuli');
%% Make directories
mkdir(params.outDicom);
mkdir(params.outPulse);
mkdir(params.outProtocols);
mkdir(params.dbScannerFiles);
mkdir(params.dbPulseOx);
mkdir(params.dbProtocols);
mkdir(params.outStimuli);
%% Copy files to cluster
% Dicoms
system(['scp aguirrelab@rico:' fullfile(params.srcDicom,params.srcSess) '/* ' ...
    params.outDicom '/']);
% Pulse Ox
system(['scp aguirrelab@rico:' fullfile(params.srcPulse,[params.pulseDate '*PULS.log']) ' ' ...
    params.outPulse '/']);
% Protocols
system(['scp -r aguirrelab@rico:' fullfile(params.srcProtocols,params.protocolName) '* ' ...
    params.outProtocols '/']);
% Gradient coefficients file
system(['scp aguirrelab@rico:' params.gradCoeff ' ' params.outProtocols '/']);
% Stimulus files
system(['cp ' params.dbStimuli '/* ' params.outStimuli '/']);
%% Copy files to Dropbox
% Pulse Ox
system(['scp aguirrelab@rico:' fullfile(params.srcPulse,[params.pulseDate '*PULS.log']) ' ' ...
    params.dbPulseOx '/']);
% Protocols
system(['scp -r aguirrelab@rico:' fullfile(params.srcProtocols,params.protocolName) '* ' ...
    params.dbProtocols '/']);
% Gradient coefficients file
system(['scp aguirrelab@rico:' params.gradCoeff ' ' params.dbProtocols '/']);