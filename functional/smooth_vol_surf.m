function smooth_vol_surf(session_dir,runNum,FWHMs,func,ROI,hemis)

% Smooths the volume and surface files for the specified run
%
%   Usage: smooth_vol_surf(session_dir,runNum,FWHMs,func,ROI,hemi)
%
%   session_dir - directory containing all run directories
%   runNum - individual run to smooth
%   FWHMs - smooth kernel (mm) <default> 5
%   func - functional volume name <default> 'dbrf.tf'
%   ROI - {'surface'}, {'volume'}, or <default> {'surface' 'volume'} ;
%   hemi - hemisphere <default> {'lh' 'rh'}
%
%   Smooths both the surface and volume using a 2mm and 5mm kernel
%
%   Written by Andrew S Bock Feb 2015

%% Set defaults
if ~exist('session_dir','var')
    error('No ''session_dir'' defined')
end
if ~exist('FWHMs','var')
    FWHMs = 5;
end
if ~exist('func','var')
    func = 'wdrf.tf';
end
if ~exist('ROI','var')
    ROI = {'surface' 'volume'};
end
if ~exist('hemi','var');
    hemis = {'lh' 'rh'};
end
%% Find the bold run directories
d = find_bold(session_dir);
%% Set runs
if ~exist('runNum','var')
    runNum = 1:length(d);
end
%% Smooth in volume and on surface
for rr = runNum
    cd(fullfile(session_dir,d{rr}));
    regfile = listdir(fullfile(session_dir,d{rr},'*_bbreg.dat'),'files');
    bbreg_out_file = fullfile(session_dir,d{rr},regfile{1}); % name registration file
    for ro = 1:length(ROI)
        if strcmp(ROI{ro},'surface')
            % Project the unsmoothed
            for hh = 1:length(hemis)
                disp(['Projecting ' hemis{hh} ' surface of ' ...
                    fullfile(session_dir,d{rr},[func '.nii.gz'])]);
                inname = fullfile(session_dir,d{rr},[func '.nii.gz']);
                outname = fullfile(session_dir,d{rr},[func '.surf.' hemis{hh} '.nii.gz']);
                system(['mri_vol2surf --src ' inname ...
                    ' --reg ' bbreg_out_file ' --hemi ' hemis{hh} ...
                    ' --out ' outname ' --projfrac-avg 0 1 0.1']);
            end
            % Smooth on surface
            if ~isempty(FWHMs)
                for i = 1:length(FWHMs)
                    FWHM = FWHMs(i);
                    for hh = 1:length(hemis)
                        disp(['Smoothing ' hemis{hh} ' surface of ' ...
                            fullfile(session_dir,d{rr},[func '.nii.gz'])]);
                        inname = fullfile(session_dir,d{rr},[func '.nii.gz']);
                        outname = fullfile(session_dir,d{rr},['s' num2str(FWHM) ...
                            '.' func '.surf.' hemis{hh} '.nii.gz']);
                        system(['mri_vol2surf --src ' inname ...
                            ' --reg ' bbreg_out_file ' --hemi ' hemis{hh} ...
                            ' --surf-fwhm ' num2str(FWHM) ' --out ' outname ...
                            ' --projfrac-avg 0 1 0.1']);
                    end
                end
            end
        elseif strcmp(ROI{ro},'volume')
            % Smooth in volume
            for i = 1:length(FWHMs)
                FWHM = FWHMs(i);
                FWHM2sigma = FWHM / (2*sqrt(2*log(2)));
                disp(['Smoothing volume of ' ...
                    fullfile(session_dir,d{rr},[func '.nii.gz'])]);
                inname = fullfile(session_dir,d{rr},[func '.nii.gz']);
                outname = fullfile(session_dir,d{rr},['s' num2str(FWHM) ...
                    '.' func '.nii.gz']);
                system(['fslmaths ' inname ' -s ' num2str(FWHM2sigma) ' ' outname]);
            end
        end
    end
end