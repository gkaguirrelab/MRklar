function remove_spikes(input_file,output_file,spike_file,err)

%   Remove large spikes from 4D data
%
%   Usage: remove_spikes(input_vol,output_vol,spike_file,<err>)
%
%   Fits a 1 degree polynomial to the timecourse for each voxel in the 4D
%   volume and computes the root mean square error (RMSE) for that voxel.
%   Any values greater than the err value <default 7> * RMSE are set to the
%   average of the neighboring TR values.
%
%   Written by Andrew S Bock Apr 2014
%
% 12/14/14      spitschan       Added case handling for 3D volumes.

if nargin <4
    err = 7 ;% default 7*RMSE
end

disp(['Spike threshold set to ' num2str(err) '*RMSE']);
disp(['Loading ' input_file ' volume...']);
fmri = load_nifti(input_file);
dims=size(fmri.vol);
% If we do not deal with a 4D volume, we also do not want to despike. When
% the volume is 3D, just return this function, and print a message. These
% files will likely not be processed anyway, and the reason why they are
% despiked is because the user has not removed them from the directory.
% But, we don't want to rely on user competence, so instead of code
% breaking, we'll just catch it here.
if numel(dims) < 4
    fprintf('*** Passed volumes as <4 dimensions, aborting remove_spikes, no output ***')
    return;
end
tc = reshape(fmri.vol,dims(1)*dims(2)*dims(3),dims(4));
tc = tc';
newtc = tc;
spikes = cell(length(tc),1);
%% Calculate RMSE for each timecourse
disp('Calculating RMSE...');
A=[linspace(1,dims(4),dims(4));ones(1,dims(4))].';
[Q,R]=qr(A,0);
Y = A*(R\(Q'*tc));
Err = sqrt((sum((Y-tc).^2))/(size(tc,1)));
tmperr = err*Err;
%% Remove values greater than err*RMSE (default 7*RMSE)
%progBar = ProgressBar(length(tc),'Removing Spikes...');
for i=1:length(tc)
    ind = find(abs(tc(:,i)-Y(:,i)) > tmperr(i));
    if ~isempty(ind)
        spikes{i} = ind;
        for n = 1:length(ind);
            if ind(n) == 1
                newtc(ind(n),i) = tc(ind(n)+1,i); % If first TR, set to second TR value
            elseif ind(n) == length(tc(:,i))
                newtc(ind(n),i) = tc(ind(n)-1,i); % If last TR, set to previous TR value
            else
                newtc(ind(n),i) = mean([tc(ind(n)-1,i) tc(ind(n)+1,i)]); % Take average of neighboring values
            end
        end
    end
%    if ~mod(i,10000);progBar(i);end
end
disp('done.');
disp(['Saving ' output_file ' Volume...'])
newtc = newtc';
newtc = reshape(newtc,dims);
spikes = reshape(spikes,dims(1:3));
fmri.vol = newtc;
save_nifti(fmri,output_file);
save(spike_file,'spikes');
disp('done.');
% Save 3D binary volume showing voxels with a spike removed
disp(['Saving ' spike_file ' Volume...']);
system(['fslroi ' input_file ' ' spike_file '.nii.gz 0 1']);
mri = load_nifti([spike_file '.nii.gz']);
ind = -1*(cellfun(@isempty,spikes))+1;
mri.vol = ind;
save_nifti(mri,[spike_file '.nii.gz']);
disp('done.');