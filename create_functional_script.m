function create_functional_script(params)

% Writes shell script to preprocess functional MRI data
%  MaxMelPaper update: call to ToolboxToolbox tbUse at the beginning of the
%  script. Requires params.tbConfig (GF) 
% 
%   Usage:
%   create_functional_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% Create job script
for rr = 1:params.numRuns
    if rr < 10
        runtext = ['0' num2str(rr)];
    else
        runtext = num2str(rr);
    end
    fname = fullfile(params.outDir,[params.jobName '_functional_' runtext '.sh']);
    fid = fopen(fname,'w');
    fprintf(fid,'#!/bin/bash\n');
    fprintf(fid,['TBCONFIG=' params.tbConfig '\n\n']);
    fprintf(fid,['SESS=' params.sessionDir '\n']);
    fprintf(fid,['SUBJ=' params.subjectName '\n\n']);
    fprintf(fid,['runNum=' num2str(rr) '\n\n']);
    func = 'rf';
    matlab_string = [...
        '"tbUseProject(''$TBCONFIG'');register_func(''$SESS'',''$SUBJ'',$runNum,1,''' func ''');' ...
        'project_anat2func(''$SESS'',$runNum,''' func ''');' ...
        'create_regressors(''$SESS'',$runNum,''' func ''',''detrend'',' ...
        num2str(params.lowHz) ',' num2str(params.highHz) ',' num2str(params.physio) ',' ...
        num2str(params.motion) ',' num2str(params.anat) ');' ...
        'remove_noise(''$SESS'',$runNum,''' func ''',' ...
        num2str(params.task) ',' num2str(params.anat) ',' num2str(params.motion) ',' ...
        num2str(params.physio) ');'];
    if params.localWM
        matlab_string = [matlab_string ...
            'remove_localWM(''$SESS'',$runNum,''d' func ''');' ...
            'temporal_filter(''$SESS'',$runNum,''wd' func ''',''' params.filtType ''',' ...
            num2str(params.lowHz) ',' num2str(params.highHz) ');' ...
            'smooth_vol_surf(''$SESS'',$runNum,5,''wd' func '.tf'');'];
    else
        matlab_string = [matlab_string ...
            'temporal_filter(''$SESS'',$runNum,''d' func ''',''' params.filtType ''',' ...
            num2str(params.lowHz) ',' num2str(params.highHz) ');' ...
            'smooth_vol_surf(''$SESS'',$runNum,5,''d' func '.tf'');'];
    end
    fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string '"']);
    fclose(fid);
end