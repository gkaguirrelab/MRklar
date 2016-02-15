function y = sinc_interp(x,s,u,N)

% Interpolates data using a sinc function. Expects row vectors.
%
%   Usage:
%   y = sinc_interp(x,s,u)
%
%   Example 1 - upsample
%   x = randn(1,100);
%   s = 1:1:100;    % sampled points
%   u = 1:0.1:100;  % upsampled points
%   y = sinc_interp(x,s,u);
%
%   Example 2 - shift
%   x = randn(1,100);
%   s = 1:1:100;    % sampled points
%   u = s - 0.5;    % shifted points (e.g. 0.5 units earlier in time)
%   y = sinc_interp(x,s,u);
%
%   Modeled after: http://phaseportrait.blogspot.com/2008/06/sinc-interpolation-in-matlab.html
%
%       Interpolates x sampled sampled at "s" instants
%       Output y is sampled at "u" instants ("u" for "upsampled")
%       Optionally, uses the Nth sampling window where N=0 is DC
%       (so non-baseband signals have N = 1,2,3,...)
%
%   Written by Andrew S Bock Jan 2016

%% Set defaults
if ~exist('N','var')
    N = 0;
end
%% Run the interpolation
sampP = s(2)-s(1);
sincM = repmat( u, length(s), 1 ) - repmat( s', 1, length(u) );
y = x*( (N+1)*sinc( sincM*(N+1)/sampP ) - N*sinc( sincM*N/sampP ) );