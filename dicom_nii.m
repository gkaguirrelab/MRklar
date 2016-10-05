function dicom_nii(dicomDir,outDir,outFile,useMRIcron)
%%
%
%   Usage:
%   dicom_nii(dicomDir,outDir,outFile,useMRIcron)
%
% Inputs:
%   dicomDir    - path to dicom directory (assumes single series)
%               - if directory has multiple serires, use dicom_sort.m first.
%   outDir      - path to output directory for nifti file
%   outFile     - name of output file, e.g. f.nii.gz
%   useMRIcron  - 0 = mri_convert (Freesurfer); 1 = dcm2nii (MRIcron)
%
% Written by Andrew S Bock Feb 2014
% Updated by Andrew S Bock Aug 2016 to add the 'useMRIcron' option

%% Set defaults
if ~exist('useMRIcron','var')
    useMRIcron = 0;
end
fprintf('\nConverting dicoms to nifti\n');
fprintf(['Input ' dicomDir '\n']);
fprintf(['Output ' fullfile(outDir,outFile) '\n']);
dicomList = listdir(dicomDir,'files');
%% Choose function to convert dicoms to nifti
if useMRIcron
    system(['dcm2nii -d n -p n -o ' outDir ' ' dicomDir]);
    created_file = listdir(fullfile(dicomDir,'s0*.nii.gz'),'files');
    if ~isempty(created_file)
        movefile(fullfile(outDir,created_file{1}),fullfile(outDir,outFile));
    else
        disp('dcm2nii failed to convert');
    end
else
    system(['mri_convert -odt float ' fullfile(dicomDir,dicomList{end}) ...
        ' ' fullfile(outDir,outFile)]);
end