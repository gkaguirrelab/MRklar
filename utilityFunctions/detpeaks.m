function [trueMax, trueMin]=detpeaks(v,delta,showplot)
%   detpeaks finds the max and min "peaks" of a given vector.
%
%   usage:
%   [maxvals, minvals]=detpeaks(v,delta,showplot)
%
%   defaults:
%   v = no default, must specify a vector
%   delta = 120; % for heart rate, assumes 100 beats per minute at a 
%   sampling period of 5ms. 
%   showplot = 0; don't plot the max and min peaks on the vector
%
%   The delta values is based on the distance betwen peak indices. The
%   default value is based on physiological data, and ignores peaks that
%   occur in close temporal proximity that would result in a heart rate >
%   100 beats/min.
%
%   output:
%   trueMax(:,1) = max peak indices
%   trueMax(:,2) = max peak values
%   trueMin(:,1) = min peak indices
%   trueMin(:,2) = min peak values
%
%   Based on code by Eli Billauer, 3.4.05 (Explicitly not copyrighted).
%
%   Written by Andrew S Bock Sept 2014

maxvals = [];
minvals = [];
v = v(:);
if ~exist('delta','var') || isnan(delta)
    delta = 120; % 100 beats / minute 
end
if ~exist('showplot','var')
    showplot = 0; % don't plot
end
mn = Inf; mx = -Inf;
mnpos = NaN; mxpos = NaN;
lookformax = 1;
for i=1:length(v)
    this = v(i);
    if this > mx, mx = this; mxpos = i; end
    if this < mn, mn = this; mnpos = i; end
    % Loop until values are no longer increasing
    if lookformax
        if this < mx % max peak found
            maxvals = [maxvals ; mxpos mx];
            mn = this; mnpos = i;
            lookformax = 0;
        end
        % Loop until values are no longer decreasing
    else
        if this > mn % min peak found
            minvals = [minvals ; mnpos mn];
            mx = this; mxpos = i;
            lookformax = 1;
        end
    end
end
%% Create window about maxium, only take 1 peak within window
trueMax = [];
prvMax = 0; % previous maximum, for cases when max values are the same within the window
for i = 1:size(maxvals,1)
    pulsewindow = v(max(1,maxvals(i,1)-round(delta/2)):min(length(v),maxvals(i,1)+round(delta/2)));
    if max(pulsewindow) == v(maxvals(i,1)) && (maxvals(i,1) - prvMax) > round(delta/2);
        prvMax = maxvals(i,1);
        trueMax = [trueMax; maxvals(i,:)];
    end
end
%% Create window around minimum, only take 1 peak within window
trueMin = [];
prvMin = 0; % previous minimum, for cases when min values are the same within the window
for i = 1:size(minvals,1)
    pulsewindow = v(max(1,minvals(i,1)-round(delta/2)):min(length(v),minvals(i,1)+round(delta/2)));
    if min(pulsewindow) == v(minvals(i,1)) && (minvals(i,1) - prvMin) > round(delta/2);
        prvMin = minvals(i,1);
        trueMin = [trueMin; minvals(i,:)];
    end
end
%% Plot the max and min peaks on vector
if showplot
    tmpmax = nan(size(v));
    tmpmax(trueMax(:,1)) = trueMax(:,2);
    tmpmin = nan(size(v));
    tmpmin(trueMin(:,1)) = trueMin(:,2);
    figure;plot(v); hold on
    plot(tmpmax,'-ro');
    plot(tmpmin,'-go');
end