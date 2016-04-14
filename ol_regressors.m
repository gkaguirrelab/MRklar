function ol_regressors(matFile,outDir,protocolName,wrapAround)

% Creates .txt files in the FSL 3-column format of relevant regressors
%   from .mat file generated from our experimental scripts
%   (OLFlickerSensitivity).
%
%   Usage:
%   ol_regressors(matFile,outDir,protocolName,wrapAround)
%
%   Input:
%   matFile = full path and filename of .mat file
%   outDir = path to output directory (e.g. fullfile(session_dir,'Stimuli'));
%   wrapAround = 1 to remove the wrap around block, 0 otherwise
%
%   2/22/16   ms, gf      Written.
%   Updates by Andrew S Bock Feb 2016
%   3/1/16 wrap-around update gf
%   Wrap Around fix by Andrew S Bock Mar 2016
%   3/10/16   ms          Added the option to include a protocol name
%   3/14/16   ms          Implemented regressors for 'MelanopsinMRMaxMel' protocol

%% Load the data, create output directory
load(matFile);
% Output prefix
[~, fileName] = fileparts(matFile);
NSegments = length(params.responseStruct.events);
% Make a 'covariates' folder
covDir = fullfile(outDir,fileName);
if ~exist(covDir,'dir');
    mkdir(covDir);
end

switch protocolName
    case 'MelanopsinMRMaxMel'
        %% Create delta regressors
        % Iterate over each segment, extract the onset and add to the
        % regressor matrix
        MODEL_HRF = false; % We keep this in here for now and will return to it for later analyses.
        
        if ~MODEL_HRF
            NSegments = params.nTrials;
            uniqueDirections = unique(params.theDirections);
            uniqueContrasts = unique(params.theContrastRelMaxIndices);
            phaseOffsetSec = params.thePhaseOffsetSec(params.thePhaseIndices);
            
            % Extract information about each trial
            contrastScalars = params.theContrastsPct(params.theContrastRelMaxIndices);
            for ii = 1:NSegments
                allDurSecs(ii) = params.responseStruct.events(ii).describe.params.stepTimeSec + 2*params.responseStruct.events(ii).describe.params.cosineWindowDurationSecs;
                allDirectionLabels{ii} = params.responseStruct.events(ii).describe.direction;
                maxContrast(ii) = params.responseStruct.events(ii).describe.params.maxContrast;
                allContrasts(ii) = params.responseStruct.events(ii).describe.params.maxContrast * contrastScalars(ii);
            end
            
            % Iterate over directions and contrasts
            for ii = 1:length(uniqueDirections)
                for jj = 1:length(uniqueContrasts)
                    thisIdx = ((params.theDirections == uniqueDirections(ii)) & (params.theContrastRelMaxIndices == uniqueContrasts(jj)));
                    startTrials = [params.responseStruct.events(thisIdx).tTrialStart]' - params.responseStruct.tBlockStart + phaseOffsetSec(thisIdx)';
                    durationSecs = allDurSecs(thisIdx)'; % Get the duration
                    theContrast = max(allContrasts(thisIdx)); % Get the contrast
                    directionLabel = unique({allDirectionLabels{thisIdx}}); % Get the direction label
                    theCov = [startTrials durationSecs ones(sum(thisIdx), 1)];
                    
                    % Write out
                    regressorFileName = [fileName '-cov_' directionLabel{1} '_' num2str(100*theContrast, '%03g') 'Pct_valid.txt'];
                    fprintf('>>> Saving out to %s ...', fullfile(covDir, regressorFileName));
                    dlmwrite(fullfile(covDir, regressorFileName), theCov, '\t');
                    fprintf('done.\n');
                end
            end

        else
            % Create regressors to model the HRF
            NSegments = params.nTrials;
            deltaDurSec = 1;
            regressorDurations = deltaDurSec*ones(NSegments, 1);
            regressorValues = ones(NSegments, 1);
            
            phaseOffsetSec = params.thePhaseOffsetSec(params.thePhaseIndices);
            
            NIntervals = 14; % 14 intervals after stimulus onset
            theIntervals = 0:13;
            for ii = 1:NIntervals
                % Define the regressor name
                regressorFileName = [fileName '-cov_delta_' num2str(theIntervals(ii), '%02.f') 'Sec_valid.txt'];
                for jj = 1:NSegments
                    % Extract the time of stimulus onset.
                    t0(jj) = params.responseStruct.events(jj).tTrialStart+phaseOffsetSec(jj)-params.responseStruct.tBlockStart;
                end
                % Define onset of the regressor
                regressorOnsets = t0 + theIntervals(ii);
                % Assemble into one matrix
                deltaCov = [regressorOnsets' regressorDurations regressorValues];
                dlmwrite(fullfile(covDir, regressorFileName), deltaCov, '\t');
            end
        end
        
    case 'HCLV_Photo'
        %% Iterate over the segments and count analyze accuracy
        attentionTaskFlag   = zeros(1,NSegments);
        responseDetection   = zeros(1,NSegments);
        hit                 = zeros(1,NSegments);
        miss                = zeros(1,NSegments);
        falseAlarm          = zeros(1,NSegments);
        for i = 1:NSegments
            % Attentional 'blinks'
            if params.responseStruct.events(i).attentionTask.segmentFlag
                attentionTaskFlag(i) = 1;
            end
            % Subject key press responses
            if ~isempty(params.responseStruct.events(i).buffer) & any(~strcmp({params.responseStruct.events(i).buffer.charCode}, '='))
                responseDetection(i) = 1;
            end
            % Hits
            if (attentionTaskFlag(i) == 1) && (responseDetection(i) == 1)
                hit(i) = 1;
            end
            % Misses
            if (attentionTaskFlag(i) == 1) && (responseDetection(i) == 0)
                miss(i) = 1;
            end
            % False Alarms
            if (attentionTaskFlag(i) == 0) && (responseDetection(i) == 1)
                falseAlarm(i) = 1;
            end
        end
        % Display performance
        fprintf('*** Subject %s - hit rate: %.3f (%g/%g) / false alarm: %.3f (%g/%g)\n', ...
            exp.subject, sum(hit)/sum(attentionTaskFlag), sum(hit), sum(attentionTaskFlag), ...
            sum(falseAlarm)/(NSegments-sum(attentionTaskFlag)), sum(falseAlarm), ...
            (NSegments-sum(attentionTaskFlag)));
       
    otherwise
        % Throw an error if the protocol does not exist.
        error(['\tUnknown protocol: ' protocolName]);
end