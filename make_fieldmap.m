function make_fieldmap(session_dir,subject_name,dicom_dir)

%   Creates a B0 fieldmap. Brain extraction is accomplished by registering
%   the magnitude image to the corresponding Freesurfer brain extracted
%   anatomical image, so the subject must have a T1 image already run
%   through the Freesurfer pipeline. This function typically follows
%   "sort_nifti". Assumes dicoms are found in a "DICOMS" directory, in the
%   session directory.
%
%   %   Usage: make_fieldmap(session_dir,subject)
%
%   Written by Andrew S Bock Feb 2014

%% Set default parameters
if ~exist('session_dir','var')
    error('"session_dir" not defined');% must define a session_dir
end
if ~exist('subject_name','var')
    error('"subject_name" not defined');% must define a session_dir
end
if ~exist('dicom_dir','var')
    dicom_dir = fullfile(session_dir,'DICOMS');
end
%% Add to log
SaveLogInfo(session_dir, mfilename,session_dir,subject_name)

%% find dicom directories
series = listdir(dicom_dir,'dirs');
% process series types
if ~isempty(series)
    B0ct = 0;
    for s = 1:length(series)
        if ~isempty(strfind(series{s},'B0'));
            B0ct = B0ct + 1;
            if B0ct == 1; % magDicomDir is first, and not processed
                magDicomDir = fullfile(dicom_dir,series{s});
                fprintf(['\nSeries ' series{s} ' contains B0 magnitude data\n\n']);
                outputDir = fullfile(session_dir,'B0');
                mkdir(outputDir);
                dicom_nii(magDicomDir,outputDir,'mag_all.nii.gz');
            elseif B0ct == 2; % magDicomDir is first, but it has been processed
                phaseDicomDir = fullfile(dicom_dir,series{s});
                fprintf(['\nSeries ' series{s} ' contains B0 phase data\n\n']);
                outputDir = fullfile(session_dir,'B0');
                dicom_nii(phaseDicomDir,outputDir,'phase_all.nii.gz');
                B0calc(outputDir,phaseDicomDir,subject_name)
            end
        end
    end
end