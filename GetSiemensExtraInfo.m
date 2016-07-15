function dcmhdr = GetSiemensExtraInfo(dcmfilename,dictionary)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract Siemens CSA Header info from dicom header
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
% dcmfilename = fullfile('C:', '20141216', 'dicom', '001_000005_000001.dcm');
% matdocpath = userpath;
% dictionary  = fullfile(matdocpath(1:end-1), 'Mydicom-dict.txt');
%
% OUTPUT:
% dcmhdr (struct with multiple fields)
% Look for:
% dcmhdr.ucReadOutMode
% dcmhdr.tSequenceFileName
% dcmhdr.TProtocolName
% dcmhdr.TE_0
% dcmhdr.TE_1
% ...
% other product attributes are:
% dcmhdr.RepetitionTime
% dcmhdr.EchoTime
% dcmhdr.SeriesNumber
% ...

%% Read dicom header
dcmhdr = dicominfo(dcmfilename, 'dictionary', dictionary);

SiemensHeader = char(dcmhdr.SiemensCSAHeader');
dcmhdr.SiemensCSAHeader = SiemensHeader;

ascconv = strfind(SiemensHeader, 'ASCCONV BEGIN');

SiemensHeader = SiemensHeader(ascconv:end);

tags.attributes = {'ucReadOutMode', 'tSequenceFileName', 'tProtocolName',...
    'alTE[0]','alTE[1]','sPat.lAccelFactPE','lEchoSpacing',...
    'sSliceArray.ucMode','sSliceArray.lSize'};
tags.outnames   = {'ucReadOutMode', 'tSequenceFileName', 'tProtocolName',...
    'TE_0','TE_1','AF','ESP','AT','NSlices'};

n_tags = length(tags.attributes);

tags.values     = cell(1, n_tags);

for i = 1:n_tags
    idx = strfind(SiemensHeader, tags.attributes{i});
    if isempty(idx)
        fprintf('Tag %d = %s not found in dicom header.\n',i, tags.attributes{i});
    else
        remain = SiemensHeader( (idx + length(tags.attributes{i}):end));
        [token, ~] = strtok(remain, [' =["]', char(32),char(10),char(13),char(9)]);
        
        %Just to polish output xd
        if ~strcmp(tags.attributes{i},'tSequenceFileName')
            tags.values{i} = token;
        else
            token2   = token;
            remain2  = token;
            finished = 0;
            while (finished==0)
                [token2,remain2]=strtok(remain2,'%\/');
                if isempty(token2)
                    finished=1;
                elseif isempty(remain2)
                    finished=2;
                end
            end
            if finished==1
                tags.values{i} = remain2;
            else
                tags.values{i} = token2;
            end
        end
        
        if ~isempty(strfind(tags.values{i},'+AF8-'))
            tags.values{i} = strrep(tags.values{i}, '+AF8-','_');
        end
    end
    
    eval(sprintf('dcmhdr.%s = ''%s'';\n',tags.outnames{i},tags.values{i}));
end
%% Get slice timings from bold runs
if ~isempty(strfind(dcmhdr.tProtocolName,'bold')) || ~isempty(strfind(dcmhdr.tProtocolName,'BOLD')) ...
        || ~isempty(strfind(dcmhdr.tProtocolName,'fmri')) || ~isempty(strfind(dcmhdr.tProtocolName,'EPI')) ...
        || ~isempty(strfind(dcmhdr.tProtocolName,'ep2d')) || ~isempty(strfind(dcmhdr.tProtocolName,'fMRI'))
    fid   = fopen(dcmfilename);
    A     = fread(fid,'char');
    Achar = char(A');
    % Get the strings between 'MosaicRefAcqTimes' and 'AutoInlineImageFilterEnabled'
    startidx    = strfind(Achar, 'MosaicRefAcqTimes');
    endidx      = strfind(Achar, 'AutoInlineImageFilterEnabled');
    remain      = Achar( (startidx(1):(endidx-1)));
    % Find the slice timing values (based on the '.', e.g. '470.0000')
    I = strfind(remain,'.');
    tmpcell = cell(length(I),1);
    for i = 1:length(I)
        tmpcell{i} = remain(I(i)-5:I(i)+5);
    end
    SliceTiming = [];
    % Remove bad strings, convert to double
    for i = 1:length(tmpcell);
        tmp = str2double(tmpcell{i});
        if ~isnan(tmp)
            SliceTiming = [SliceTiming;tmp];
        end
    end
    fclose(fid);
    dcmhdr.SliceTimings = SliceTiming;
end