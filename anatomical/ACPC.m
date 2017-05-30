function ACPC(inputDir,inputFile,outputFile,atlas,brain_size,ACPCpath)

%   ACPC align anatomical image, using the Van Essen ACPC Alignment module.
%   If anatomical images is <1mm resolution, also creates a downsampled
%   1mm anatomical image for Freesurfer.
%
%   Usage:
%   ACPC(inputDir,inputFile,outputFile,atlas,brain_size,ACPCpath)
%
%   E.g.
%   ACPC('~/data/ASB/anatomical/','MPRAGE','MPRAGE.ACPC')
%
%   Written by Andrew S Bock Feb 2014


% Set default parameters for humans
if ~exist('inputDir','var')
    error('no inputDir defined!');
end
outputDir = fullfile(inputDir,'ACPC');
mkdir(outputDir);
if ~exist('inputFile','var')
    inputFile = 'MPRAGE';
end
if ~exist('outputFile','var')
    outputFile = fullfile(outputDir,[inputFile '.ACPC']);
end
if ~exist('atlas','var')
    FSLDIR = getenv('FSLDIR');
    atlas = fullfile(FSLDIR,'/data/standard/MNI152_T1_1mm.nii.gz');
end
if ~exist('brain_size','var')
    brain_size = '150';
end
if ~exist('ACPCpath','var')
    ACPCpath = fullfile(fileparts(mfilename('fullpath')), 'ACPCAlignmentModule');
end

intermed_file = fullfile(outputDir,'intermed_file.nii.gz');
regmatrix = fullfile(outputDir,'ACPCregmat');
ACPCscript = fullfile(ACPCpath,'ACPCAlignment.sh');

% ACPC realign
fprintf('\nCreating 1mm3 ACPC aligned image\n');
system(['mri_convert ' fullfile(inputDir,[inputFile '.nii.gz']) ' ' intermed_file ...
    ' --out_orientation LAS' ]);
system([ACPCscript ' ' outputDir ' ' intermed_file ...
    ' ' atlas ' ' [outputFile '.nii.gz'] ' ' regmatrix ...
    ' ' ACPCpath ' ' brain_size]);
% Check if anatomical image is <1mm resolution
anat = load_nifti(fullfile(inputDir,[inputFile '.nii.gz']));
if (anat.pixdim(2)*anat.pixdim(3)*anat.pixdim(4)) < .7290 % less than 0.9mm^3
    fprintf('\nAnatomical Image is <1mm3 resolution, creating highres ACPC aligned image\n\n');
    tmp = fullfile(outputDir,'tmp.nii.gz');
    highres = [anat.pixdim(2) anat.pixdim(3) anat.pixdim(4)];
    system(['mri_convert -voxsize ' num2str(highres) ' ' [outputFile '.nii.gz'] ' ' tmp]);
    system(['flirt -in ' intermed_file ' -ref ' tmp ...
        ' -out ' fullfile([outputFile '.highres.nii.gz']) ' -interp spline']);
    delete(tmp);
end
delete(intermed_file);