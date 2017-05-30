function [d] = find_bold(session_dir)

% Finds bold directories for a given session directory
%
%   Written by Andrew S Bock Jul 2015

%% Find the bold directories
d = listdir(fullfile(session_dir),'dirs');
for i = 1:length(d)
    if strfind(d{i},'BOLD')        
    elseif strfind(d{i},'BOLD')
    elseif strfind(d{i},'bold')
    elseif strfind(d{i},'ep2d')
    elseif strfind(d{i},'EPI')
    elseif strfind(d{i},'fMRI')
    elseif strfind(d{i},'fmri')
    else
        d{i} = [];      
    end
end
if isempty(d)
    d = listdir(fullfile(session_dir,'RUN*'),'dirs');
end
d = d(~cellfun(@isempty,d));
%% Remove the SBRef directories
SBRef = strfind(d,'SBRef');
if ~isempty(SBRef)
    badd = zeros(length(d),1);
    for i = 1:length(SBRef)
        if ~isempty(SBRef{i})
            badd(i) = 1;
        end
    end
    d = d(~badd);
end