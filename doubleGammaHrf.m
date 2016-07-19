function [hrf] = doubleGammaHrf(TR,tp,beta,rt,len)

% Computes a double gamma Hemodynamic Response Function (HRF).
%
%   Usage: [hrf] = doubleGammaHrf(TR,tp,fwhm,alp,len)
%
%   Defaults:
%       TR = 1; % Repetition time
%       tp = [6 16]; % time to peak/undershoot (in seconds)
%       beta = [1 1]; % scale of peak/undershoot
%       rt = 1/6; % ratio of response to undershoot
%       len = 33; % length of HRF (in seconds)
%
%   Equations modeled after:
%       Glover (1999) NeuroImage
%       spm_hrf.m
%       DeSimone, Viviano, Schneider (2015) J Neuro.
%
%   Written by Andrew S Bock May 2015

%% Set defaults
if ~exist('TR','var')
    % Repetition time
    TR = 1;
end
if ~exist('tp','var')
    % time to peak response
    tp(1) = 6;
    % time to minimum undershoot
    tp(2) = 16;
end
if ~exist('beta','var');
    % peak
    beta(1) = 1;
    % undershoot
    beta(2) = 1;
end
if ~exist('rt','var')
    % ratio of response to undershoot
    rt = 1/6;
end
if ~exist('len','var')
    % length of HRF
    len = 33;
end
%% Create HRF
dx = TR:TR:len;
A = [0 gampdf(dx,tp(1)+1,beta(1))]; % add one to tp(1) (seconds -> index)
B = [0 gampdf(dx,tp(2)+1,beta(2))]; % add one to tp(2) (seconds -> index)
hrf = A - rt*B;
hrf = hrf'/sum(hrf);
hrf = hrf(1:end-1); % remove the extra value, since we added zero above
%%
%hrf = hrf(1:floor(len/TR))/sum(hrf(1:floor(len/TR)));