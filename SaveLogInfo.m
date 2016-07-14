function SaveLogInfo(theDir,functionName,varargin)
% function SaveLogInfo
%
% Saves out log information, with time stamp and function time, as well as
% git repository information, user name, and inputs.
%
% 12/12/14  ms, asb         Wrote it.

%% Get current time
timeStamp = datestr(now);

%% Get git repository information
% thePath = fileparts(mfilename('fullpath'));
% gitPath = fullfile(thePath,'.git');
% [~,gitInfo.Revision] = system(['git --git-dir=' gitPath ' rev-parse HEAD']);
gitInfo = GetGITInfo(thePath);

%% User name
[~, theUser] = system('whoami');

%% Set up file name
outputFile = fullfile(theDir, 'LOG');

%% Get input arguments
nInputs = size(varargin,2);

%% If file doesn't exist, create it and add a new header.
if ~exist(outputFile, 'file')
    fid = fopen(outputFile, 'a');
    fprintf(fid, 'Time\t\t\tFunction\tRevision\t\t\t\t\tUser\n');
    fclose(fid);
end
%% Add time, function name, git revision number, user, and inputs to function
fid = fopen(outputFile, 'a');
fprintf(fid, '%s\t%s\t%s\t%s', timeStamp, functionName, gitInfo.Revision, theUser);
fprintf(fid, '%s\n',['Number of inputs = ' num2str(nInputs)]);
if nInputs ~= 0
    for n = 1:nInputs
        tmp = varargin{n};
        if ~ischar(tmp)
            if isnumeric(tmp)
                tmp = num2str(tmp);
                if size(tmp,1)>1
                    tmp = reshape(tmp,1,size(tmp,1)*size(tmp,2));
                end
                if size(tmp,1)*size(tmp,2)>100
                    tmp = 'numerical matrix, too large to save';
                else
                    tmp = ['numerical matrix converted to: ' tmp];
                end
            elseif iscellstr(tmp)
                tmp = cell2str(tmp);
            else
                tmp = 'input not recognized (i.e. not a number or string)';
            end
        end
        fprintf(fid,'%s\n',['Input ' num2str(n) ' = ' tmp]);
    end
end
fclose(fid);

