function [newparams] = regress_task(params,contrasts)

%   Outputs noise parameters that are orthogonal to the task contrasts
%
%   Usage:
%   [newparams] = regress_task(params,contrasts)
%
%   Written by Andrew S Bock Oct 2014

%% remove mean from contrasts
for m = 1:size(contrasts,2)
    contrasts(:,m) = contrasts(:,m) - mean(contrasts(:,m));
    if var(contrasts(:,m)) == 0
        error('no variation to task conditions');
    end
end
%% Regress out the task contrasts from the motion parameters
newparams = nan(size(params));
for m = 1:size(newparams,2)
    newparams(:,m) = params(:,m)-contrasts*(contrasts\params(:,m));
    newparams(:,m) = newparams(:,m) - mean(newparams(:,m));
end