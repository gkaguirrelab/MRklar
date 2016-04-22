function mcflirt(inFile,outFile,refvol)

% Motion correction using FSL's 'mcflirt' command
%
%   Usage:
%   mcflirt(inFile,outFile,refvol)
%
%   Note:
%   refvol = reference TR (1 = 1st TR)
%
%   Written by Andrew S Bock Apr 2016

%% Set defaults
if ~exist('refvol','var')
    refvol = 1; % 1st TR
end
system(['mcflirt -in ' inFile ' -out ' outFile ' -refvol ' num2str(refvol-1) ...
    ' -stats -mats -plots -report']);