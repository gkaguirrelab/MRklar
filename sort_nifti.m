function sort_nifti(session_dir,dicom_dir,useMRIcron)

%   Sorts dicoms into series directories, converts to nifti files based on
%   series type (e.g. MPRAGE, BOLD, DTI). Also ACPC aligns anatomical
%   images. Assumes dicoms are found in a "DICOMS" directory, in the
%   session directory.
%
%   Usage: sort_nifti(session_dir,dicom_dir)
%
%   note: for the ACPC step to work, you need to have python installed.
%   Also, by default 'ACPC.m' uses an FSL anatomical atlas, so it is
%   recommended that FSL also be installed.
%
%   Written by Andrew S Bock Feb 2014
%
% 12/15/14      spitschan       Output to be run in the shell also saved in
%                               file.

%% Set default parameters
if ~exist('dicom_dir','var')
    dicom_dir = fullfile(session_dir,'DICOMS');
end
if ~exist('useMRIcron','var')
    useMRIcron = 1; % use 'MRIcron'
end
%% sort dicoms within this directory
dicom_sort(dicom_dir);
series = listdir(dicom_dir,'dirs');
% process series types
if ~isempty(series)
    mpragect    = 0;
    T2ct        = 0;
    mp2ragect   = 0;
    PDct        = 0;
    boldct      = 0;
    APct        = 0;
    PAct        = 0;
    DTIct       = 0;
    progBar = ProgressBar(length(series),'Converting dicoms');
    for s = 1:length(series)
        fprintf(['\nProcessing ' series{s} ' series ' num2str(s) ' of ' ...
            num2str(length(series)) '\n\n']);
        % Anatomical image
        if (~isempty(strfind(series{s},'MPRAGE')) || ~isempty(strfind(series{s},'T1w'))) ...
                && isempty(strfind(series{s},'MPRAGE_NAV'));
            mpragect = mpragect + 1;
            fprintf(['\nPROCESSING ANATOMICAL IMAGE ' sprintf('%03d', mpragect) '\n']);
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,'MPRAGE',sprintf('%03d', mpragect));
            mkdir(outputDir);
            outputFile = 'MPRAGE.nii.gz';
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron);
            inputFile = 'MPRAGE';
            ACPC(outputDir,inputFile);
            system(['echo ' series{s} ' > ' fullfile(outputDir,'series_name')]);
            disp('done.')
        elseif (~isempty(strfind(series{s},'T2')) || ~isempty(strfind(series{s},'T2w')));
            T2ct = T2ct + 1;
            fprintf(['\nPROCESSING T2 IMAGE ' sprintf('%03d', T2ct) '\n']);
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,'T2w',sprintf('%03d', T2ct));
            mkdir(outputDir);
            outputFile = 'T2w.nii.gz';
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron);
            system(['echo ' series{s} ' > ' fullfile(outputDir,'series_name')]);
            disp('done.')
        elseif ~isempty(strfind(series{s},'mp2rage'));
            mp2ragect = mp2ragect + 1;
            fprintf(['\nPROCESSING ANATOMICAL IMAGE ' sprintf('%03d',mp2ragect) '\n']);
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,'MP2RAGE',sprintf('%03d',mp2ragect));
            mkdir(outputDir);
            outputFile = 'MP2RAGE.nii.gz';
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron)
            inputFile = 'MP2RAGE';
            ACPC(outputDir,inputFile);
            system(['echo ' series{s} ' > ' fullfile(outputDir,'series_name')]);
            disp('done.')
        elseif ~isempty(strfind(series{s},'PD'));
            PDct = PDct + 1;
            fprintf(['\nPROCESSING PROTON DENSITY IMAGE ' sprintf('%03d',PDct) '\n']);
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,'PD',sprintf('%03d',PDct));
            mkdir(outputDir);
            outputFile = 'PD.nii.gz';
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron)
            system(['echo ' series{s} ' > ' fullfile(outputDir,'series_name')]);
            disp('done.')
        elseif (~isempty(strfind(series{s},'ep2d')) || ~isempty(strfind(series{s},'BOLD')) ...
                || ~isempty(strfind(series{s},'bold')) || ~isempty(strfind(series{s},'EPI')) ...
                || ~isempty(strfind(series{s},'RUN')) || ~isempty(strfind(series{s},'fmri')) ...
                || ~isempty(strfind(series{s},'fMRI'))) ...
                && isempty(strfind(series{s},'SBRef'));
            boldct = boldct + 1;
            fprintf(['\nPROCESSING BOLD IMAGE ' sprintf('%03d',boldct) '\n']);
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,series{s});
            mkdir(outputDir);
            outputFile = 'raw_f.nii.gz';
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron)
            system(['echo ' series{s} ' > ' fullfile(outputDir,'series_name')]);
            echo_spacing(fullfile(dicom_dir,series{s}),outputDir);
            slice_timing(fullfile(dicom_dir,series{s}),outputDir);
            disp('done.')
        elseif ~isempty(strfind(series{s},'SpinEchoFieldMap'))
            fprintf('\nPROCESSING FIELDMAP IMAGE\n');
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,'SpinEchoFieldMap');
            mkdir(outputDir);
            if ~isempty(strfind(series{s},'SpinEchoFieldMap_AP'))
                APct = APct + 1;
                outputFile = (['SpinEchoFieldMap_AP_' sprintf('%02d', APct) '.nii.gz']);
                system(['echo ' series{s} ' > ' fullfile(outputDir,['series_name_AP' sprintf('%02d', APct)])]);
            elseif ~isempty(strfind(series{s},'SpinEchoFieldMap_PA'))
                PAct = PAct + 1;
                outputFile = (['SpinEchoFieldMap_PA_' sprintf('%02d', PAct) '.nii.gz']);
                system(['echo ' series{s} ' > ' fullfile(outputDir,['series_name_PA' sprintf('%02d', PAct)])]);
            else
                error('SpinEchoFieldMap type not AP or PA');
            end
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron);
            disp('done.')
        elseif ~isempty(strfind(series{s},'DTI'));
            DTIct = DTIct + 1;
            fprintf(['\nPROCESSING DTI IMAGE ' sprintf('%03d',DTIct) '\n']);
            % Convert dicoms to nifti
            outputDir = fullfile(session_dir,series{s});
            mkdir(outputDir);
            outputFile = 'raw_d.nii.gz';
            dicom_nii(fullfile(dicom_dir,series{s}),outputDir,outputFile,useMRIcron)
            disp('done.')
        end
        progBar(s);
    end
end
fprintf('\n');
disp('Preprocess finished');
fprintf('\n');
disp('to run recon-all, run the following in a terminal (assuming using 3T and MPRAGE):')
fprintf('\n');
commandc = ['recon-all -i ' fullfile(session_dir,'MPRAGE','001','ACPC','MPRAGE.ACPC.nii.gz') ' -s <subject_name> -all'];
disp(commandc);

% Also save this out in a file.
fid = fopen(fullfile(session_dir, 'recon_all_scripts'), 'a');
fprintf(fid, commandc);
fclose(fid);