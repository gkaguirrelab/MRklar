function temporal_filter(session_dir,runNum,func,filtType,cutoffHzlow,cutoffHzhigh)
%% Temporal Filtering
% Removes temporal frequencies from 4D fMRI timeseries
%
%   Usage: temporal_filter(session_dir,runNum,func,type,cutoffHzlow,cutoffHzhigh)
%
%   Output: <func>.tf.nii.gz
%
% Will implement either remove linear trend, or conduct a band-pass
% temporal filter, depending on the 'type' input <default = 'detrend'>
%
% If type = 'bptf'
%   formula: Sigma = 1/(2 x <Hz> x TR) -> FWHM
%   High-pass filter stimulus data - recommended value is 0.01 Hz
%   ref: https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1104&L=FSL&D=0&P=283059
%   (Dead link as of 1/2015. In this link it was stated that FSL uses 2).
%   alternatively, the following link suggests to use 2.35 instead of 2
%   https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1108&L=FSL&D=0&P=253428
%   Working link:
%   https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1109&L=fsl&D=0&P=167923
%
%   From FSL version 5.0.7 onwards, fslmaths -bptf demeans the data for high
%   temporal filtering. This means that the mean is subtracted in the
%   resulting time series. To address this problem, we first save out the
%   mean of the time series, subtract it, filter the time series (ad by virtue of
%   fslmaths, demean it but it will already be zero-mean), and then add the mean back in.
%
% For details, see https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1412&L=FSL&P=R48332&1=FSL&9=A&I=-3&J=on&d=No+Match%3BMatch%3BMatches&z=4
%
%   Written by Andrew S Bock Apr 2015

%% Set default parameters
if ~exist('session_dir','var')
    error('"session_dir" not defined')
end
if ~exist('func','var')
    func = 'wdrf'; % functional data file
end
if ~exist('filtType','var')
    filtType = 'detrend'; %'bptf'
end
if ~exist('cutoffHzlow','var')
    cutoffHzlow = 0.009; % Low frequency cut-off [Hz]; Power (2014/15) - 0.009 Hz
end
if ~exist('cutoffHzhigh','var')
    cutoffHzhigh = inf; % High frequency cut-off [Hz]; Power (2014/15) - 0.08 Hz
end
%% Find bold run directories
b = find_bold(session_dir);

%% Temporally filter
for rr = runNum;
    in_file = fullfile(session_dir,b{rr},[func '.nii.gz']);
    out_file = fullfile(session_dir,b{rr},[func '.tf.nii.gz']);
    disp(['Temporally filtering ' in_file '...']);
    % Obtain parameters for filtering
    inFunc = load_nifti(in_file);
    outFunc = inFunc;
    TR = inFunc.pixdim(5)/1000;
    dims = size(inFunc.vol);
    if TR < 0.1
        error('TR is <0.1, TR in file header is most likely not in msec');
    end
    switch filtType
        case 'high'
            intc = (reshape(inFunc.vol,dims(1)*dims(2)*dims(3),dims(4)))';
            [tc_filt] = filter_signal(intc,filtType,TR,cutoffHzlow,cutoffHzhigh);
            % detrend, but same the mean
            mtc = mean(intc); % save means (will be removed using 'detrend')
            dtc = detrend(tc_filt); % remove linear trend from timecourses
            newtc = zeros(size(dtc));
            for m = 1:size(dtc,2)
                newtc(:,m) = dtc(:,m) + mtc(m); % add mean
            end
            newtc = newtc';
            newtc = reshape(newtc,size(inFunc.vol));
            outFunc.vol = newtc;
            save_nifti(outFunc,out_file); % save temporally filtered data
        case 'low'
            intc = (reshape(inFunc.vol,dims(1)*dims(2)*dims(3),dims(4)))';
            [tc_filt] = filter_signal(intc,filtType,TR,cutoffHzlow,cutoffHzhigh);
            % detrend, but same the mean
            mtc = mean(intc); % save means (will be removed using 'detrend')
            dtc = detrend(tc_filt); % remove linear trend from timecourses
            newtc = zeros(size(dtc));
            for m = 1:size(dtc,2)
                newtc(:,m) = dtc(:,m) + mtc(m); % add mean
            end
            newtc = newtc';
            newtc = reshape(newtc,size(inFunc.vol));
            outFunc.vol = newtc;
            save_nifti(outFunc,out_file); % save temporally filtered data
        case 'band'
            intc = (reshape(inFunc.vol,dims(1)*dims(2)*dims(3),dims(4)))';
            [tc_filt] = filter_signal(intc,filtType,TR,cutoffHzlow,cutoffHzhigh);
            % detrend, but same the mean
            mtc = mean(intc); % save means (will be removed using 'detrend')
            dtc = detrend(tc_filt); % remove linear trend from timecourses
            newtc = zeros(size(dtc));
            for m = 1:size(dtc,2)
                newtc(:,m) = dtc(:,m) + mtc(m); % add mean
            end
            newtc = newtc';
            newtc = reshape(newtc,size(inFunc.vol));
            outFunc.vol = newtc;
            save_nifti(outFunc,out_file); % save temporally filtered data
        case 'detrend'
            disp('FiltType = ''detrend''');
            tc = reshape(inFunc.vol,dims(1)*dims(2)*dims(3),dims(4));
            tc = tc';
            mtc = mean(tc); % save means (will be removed using 'detrend')
            dtc = detrend(tc); % remove linear trend from timecourses
            newtc = zeros(size(dtc));
            for m = 1:size(dtc,2)
                newtc(:,m) = dtc(:,m) + mtc(m); % add mean
            end
            newtc = newtc';
            newtc = reshape(newtc,size(inFunc.vol));
            outFunc.vol = newtc;
            save_nifti(outFunc,out_file); % save temporally filtered data
        case 'bptf'
            disp('FiltType = ''bptf''');
            % Check that tmp.pixdim(5) is in msec
            % use 100 as threshold, in case very short (e.g. 500 msec) TR is used (i.e. multi-band)
            if inFunc.pixdim(5) < 100
                error('TR is not in msec');
            end
            % Convert Hz to sigma
            low_period_sigma = 1 / (2 * cutoffHzlow * TR);
            high_period_sigma = 1 / (2 * cutoffHzhigh * TR);
            if high_period_sigma == 0
                % -1 means only do high-pass filter
                high_period_sigma = -1;
            end
            disp(['Low cutoff = ' num2str(cutoffHzlow) 'Hz']);
            disp(['High cutoff = ' num2str(cutoffHzhigh) 'Hz']);
            % Save the mean
            [~,~] = system(['fslmaths ./' func '.nii.gz -Tmean ./' func '.mean.nii.gz']);
            % Subtract the mean
            [~,~] = system(['fslmaths ./' func '.nii.gz -sub ./' func '.mean.nii.gz ./' func '.demean.nii.gz']);
            % Filter the data
            [~,~] = system(['fslmaths ./' func '.demean.nii.gz -bptf ' num2str(low_period_sigma) ' ' ...
                num2str(high_period_sigma) ' ./' func '.demean.tf.nii.gz']);
            % Add the mean back in
            [~,~] = system(['fslmaths ./' func '.demean.tf.nii.gz -add ./' func '.mean.nii.gz ./' func '.tf.nii.gz']);
            % Delete temporary files
            [~,~] = system(['rm ./' func '.mean.nii.gz ./' func '.demean.nii.gz ./' func '.demean.tf.nii.gz']);
    end
    disp('done.');
end
