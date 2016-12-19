function tomeQA(params)

% Run quality assurance on TOME data
%
%   Usage:
%       tomeQA(params)
%
%   Required:
%       params.sessionDir       = '/full/path/to/sessionDir'
%       params.outDir           = '/full/path/to/outDir'
%
%   Defaults:
%       params.T1               = 1; % view T1 image, set to 0 to skip
%       params.spinEcho         = 1; % view SpinEchoFieldMaps, set to 0 to skip
%       params.rawBold          = 1; % view raw_f.nii.gz, set to 0 to skip
%       params.processedBold    = 1; % view wdrf.tf.nii.gz, set to 0 to skip
%       params.motion           = 1; % save motion plots, set to 0 to skip
%
%   Written by Andrew S Bock Nov 2016

%% set defaults
set(0, 'DefaulttextInterpreter', 'none');
if ~isfield(params,'T1')
    params.T1               = 1;
end
if ~isfield(params,'spinEcho')
    params.spinEcho         = 1;
end
if ~isfield(params,'rawBold')
    params.rawBold          = 1;
end
if ~isfield(params,'processedBold')
    params.processedBold    = 1;
end
if ~isfield(params,'motion')
    params.motion           = 1;
end
if ~exist(params.outDir,'dir')
    mkdir(params.outDir);
end
%% View T1
if params.T1
    t1Vol                   = fullfile(params.sessionDir,'MPRAGE/001/MPRAGE.nii.gz');
    imshow3D(t1Vol,[],1);
    title('T1','FontSize',20);
    savefigs('pdf',fullfile(params.outDir,'T1'));
    close all;
end
%% View SpinEcho
if params.spinEcho
    apVol                   = fullfile(params.sessionDir,...
        'SpinEchoFieldMap/SpinEchoFieldMap_AP_01.nii.gz');
    singleAP                = fullfile(params.sessionDir,...
        'SpinEchoFieldMap/singleAP.nii.gz');
    system(['fslroi ' apVol ' ' singleAP ' 0 1']);
    paVol                   = fullfile(params.sessionDir,...
        'SpinEchoFieldMap/SpinEchoFieldMap_PA_01.nii.gz');
    singlePA                = fullfile(params.sessionDir,...
        'SpinEchoFieldMap/singlePA.nii.gz');
    system(['fslroi ' paVol ' ' singlePA ' 0 1']);
    imshow3D(singleAP);
    title('SpinEcho AP','FontSize',20);
    savefigs('pdf',fullfile(params.outDir,'SpinEchoAP'));
    close all;
    imshow3D(singlePA);
    title('SpinEcho PA','FontSize',20);
    savefigs('pdf',fullfile(params.outDir,'SpinEchoPA'));
    close all;
    system(['rm ' singleAP]);
    system(['rm ' singlePA]);
end
%% View raw bold
if params.rawBold
    b                       = find_bold(params.sessionDir);
    for i = 1:length(b)
        rawF                = fullfile(params.sessionDir,b{i},'raw_f.nii.gz');
        singleF             = fullfile(params.sessionDir,b{i},'singleF.nii.gz');
        system(['fslroi ' rawF ' ' singleF ' 0 1']);
        imshow3D(singleF);
        title([b{i} ' - raw_f'],'FontSize',20);
        savefigs('pdf',fullfile(params.outDir,[b{i} '-raw_f']));
        close all;
        system(['rm ' singleF]);
    end
end
%% View processed bold
if params.processedBold
    b                       = find_bold(params.sessionDir);
    for i = 1:length(b)
        rawF                = fullfile(params.sessionDir,b{i},'wdrf.tf.nii.gz');
        singleF             = fullfile(params.sessionDir,b{i},'singleF.nii.gz');
        system(['fslroi ' rawF ' ' singleF ' 0 1']);
        imshow3D(singleF);
        title([b{i} ' - wdrf.tf'],'FontSize',20);
        savefigs('pdf',fullfile(params.outDir,[b{i} '-wdrf.tf.pdf']));
        close all;
        system(['rm ' singleF]);
    end
end
%% Save motion parameter plots
if params.motion
    b                       = find_bold(params.sessionDir);
    for i = 1:length(b)
        % Make figure
        figure('units','normalized','position',[0 0 1 1]);
        % plot data
        mp = load(fullfile(params.sessionDir,b{i},'mc/motion_params.txt'));
        mp(:,1:3) = mp(:,1:3)*50;
        x = 1:size(mp,1);
        plot(mp);
        hold on;
        plot(x,-2 * ones(size(x)),'--k',x,2 * ones(size(x)),'--k');
        ylim([-3 3]);
        xlim([1 size(mp,1)]);
        title(b{i},'FontSize',20);
        set(gca,'FontSize',15);
        xlabel('TR','FontSize',20);
        ylabel('Movement (mm)','FontSize',20);
        grid on;
        legend({'pitch' 'yaw' 'roll' 'x' 'y' 'z'},'FontSize',20,'Location','EastOutside');
        savefigs('pdf',fullfile(params.outDir,[b{i} '-motion.pdf']));
        close all;
    end
end