function [] = dicom_nii(dicomDir,outputDir,outputFile)
%%
%
%   Usage: 
%   dicom_nii(dicomDir,outputDir,outputFile)
%
% Inputs:
%   -dicomDir = path to dicom directory (assumes single series)
%       -if directory has multiple serires, use dicom_sort.m first.
%   -outputDir = path to output directory for nifti file
%   -outputFile = name of output file, e.g. f.nii.gz
%
% Written by Andrew S Bock Feb 2014

fprintf('\nConverting dicoms to nifti\n');
fprintf(['Input ' dicomDir '\n']);
fprintf(['Output ' fullfile(outputDir,outputFile) '\n']);
dicomList = listdir(dicomDir,'files');
system(['mri_convert -odt float ' fullfile(dicomDir,dicomList{end}) ...
    ' ' fullfile(outputDir,outputFile)]);