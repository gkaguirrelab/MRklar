function [outVol,inVol] = slice_timing_correction(inFile,outFile,timingFile)

% Performs slice timing correction on a functional volume, using sinc
% interpolation.
%
%   Usage:
%       slice_timing_correction(inFile,outFile,timingFile)
%
%   Note: assumes values in timingFile range from 0 to 1, in terms of the
%   acquistion time of each slice (0 = start, 1 = end);
%
%   Written by Andrew S Bock Jan 2016

%% Correct slice timing
disp(['Correcting slice timings for: ' inFile]);
tmp = load(timingFile);
slice_timings = tmp - 0.5; % convert values from 0 - 1 to -0.5 - 0.5
fmri = load_nifti(inFile);
inVol = fmri.vol;
outVol = nan(size(fmri.vol));
dims = size(fmri.vol);
for zz = 1:dims(3);
    slice_tc = squeeze(fmri.vol(:,:,zz,:));
    tmpx = reshape(slice_tc,dims(1)*dims(2),dims(4));
    tmpxmean = mean(tmpx,2);
    xmean = repmat(tmpxmean,1,size(tmpx,2));
    x = tmpx - xmean;
    s = 1:1:dims(4);
    u = s - slice_timings(zz);
    tmpy = sinc_interp(x,s,u);
    y = tmpy + xmean;
    outVol(:,:,zz,:) = reshape(y,dims(1),dims(2),1,dims(4));
end
%% Save file
fmri.vol = outVol;
save_nifti(fmri,outFile);
disp('done');