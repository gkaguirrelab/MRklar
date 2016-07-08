function dicom_sort(dicomDir)
% Creates several directories within the <dicomDir>, based on the
%  protocol name and series found in the dicom headers.  Individual dicoms
%  are moved from the dicomDir into their respective protocol and series
%  directory.
%
%   Usage:
%   dicom_sort(dicomDir)
%
%   Default:
%   dicomDir = pwd;
%
% Input:
%   dicomDir = full path to dicom directory, with all dicoms from
%   different acquisition series in the same directory. 
%
%   note: in some cases, the '.dcm' extension has been removed.  This
%   function will add '.dcm' back to those files
%
% Output:
%  - creates several directories within the <dicomDir>, based on the
%  protocol name and series found in the dicom headers.  Individual dicoms
%  are moved from the dicomDir into their respective protocol and series
%  directory.
%
% Written by Andrew S Bock Feb 2014

%% set defaults
if ~exist('dicomDir','var')
    dicomDir = pwd;
end
%% Sort dicoms
% check if '.dcm' has been removed
files = listdir(dicomDir,'files');
disp(['Found ' num2str(length(files)) ' files in ' dicomDir])
if ~isempty(files)  % if there are any files in this directory
    dcms = nan(length(files),1);
    ct = 0;
    disp('Determining which files are dicom files');
    for f = 1:length(files)
        dcms(f) = isdicom(fullfile(dicomDir,files{f}));
    end
    for f = 1:length(files)
        if dcms(f) % If file is a dicom file
            % If extension is not '.dcm', add that extension
            if ~strcmp(files{f}(end-3:end),'.dcm')
                ct = ct+1;
                movefile(fullfile(dicomDir,files{f}),...
                    ([fullfile(dicomDir,files{f}) '.dcm']));
            end
        end
    end
end
% sort dicoms by protocol and series
dicoms = listdir(fullfile(dicomDir,'*.dcm'),'files');
disp(['Found ' num2str(length(dicoms)) ' dicom files in ' dicomDir])
if ~isempty(dicoms) % if there are dicoms in this directory
    for n = 1:length(dicoms)
        clear tmpdir
        info = dicominfo(fullfile(dicomDir,dicoms{n}));
        if isfield(info,'SeriesDescription')
            tmpdir = fullfile(dicomDir,sprintf('Series_%03d_%s',info.SeriesNumber,info.SeriesDescription)); %MV
            if ~exist(tmpdir,'dir');
                mkdir(tmpdir);
                disp(['Sorting dicoms into ' sprintf('Series_%03d_%s',info.SeriesNumber,info.SeriesDescription)]);
            end
            % Sort dicom files according to ProtocolName
            movefile(fullfile(dicomDir,dicoms{n}),...
                fullfile(tmpdir,dicoms{n}));
        end
    end
else
    disp('No .dcm files in dicomDir')
end