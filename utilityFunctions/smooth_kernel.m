function outSignal=smooth_kernel(inSignal,sig)

% Creates a smoothing kernel for use in smoothing physio data (PulseResp)
%
%   Usage:
%   outSignal=smooth_kernel(inSignal,sig)
%
%   Inputs:
%   inSignal - signal to be filtered
%   sig - sigma for Gaussian kernel
%
%   Example:
%   inSignal = pulse.Lsignal;
%   FWHM = 0.4*pulse.sampR; % 400 ms FWHM; following Verstynen & Deshpande (2011)
%   sig = FWHM/(2*(sqrt(2*log(2)))); % convert to sigma
%   outSignal=smooth_kernel(inSignal,sig);
%
%   Written by Andrew S Bock Nov 2015

%% Create the Gaussian
N = round(sig*5)*2;
x = 1:N;
tmpGauss = normpdf(x,(N+1)/2,sig);
%% Convolve
outSignal = conv(inSignal,tmpGauss,'same');