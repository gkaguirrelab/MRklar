function mcflirt(inFile,outFile,refvol)

% Motion correction using FSL's 'mcflirt' command
%
%   Usage:
%   mcflirt(inFile,outFile,refvol)
%
%   Written by Andrew S Bock Apr 2016

%% Set defaults
if ~exist('refvol','var')
    refvol = 0; % 1st TR
end
system(['mcflirt -in ' inFile ' -out ' outFile ' -refvol ' num2str(refvol) ...
    ' -stats -mats -plots -report']);