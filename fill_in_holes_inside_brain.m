function imgtofill = fill_in_holes_inside_brain(imgtofill, n_passes)
if ~exist('n_passes','var')
    n_passes=3;
end
fprintf('\n> Calling function "fill in holes inside brain"\n');
for ipass = 1:n_passes    
    %a. get the main cluster only
    CC = bwconncomp(imgtofill,18);
    size_clusters = zeros(CC.NumObjects,1);
    for i = 1:CC.NumObjects
        size_clusters(i,1) = length(CC.PixelIdxList{i});
    end
    [~,cluster_mask] = max(size_clusters);
    imgtofill = zeros(size(imgtofill));
    imgtofill(CC.PixelIdxList{cluster_mask}) = 1;    
    %b. if there are holes inside main cluster, fill them in
    CC = bwconncomp(1-imgtofill,18);
    size_clusters = zeros(CC.NumObjects,1);
    if CC.NumObjects > 1
        fprintf('\tPASS %d\tFound 3D holes in this image n = %d\n', ipass, CC.NumObjects);
        for i = 1:CC.NumObjects
            size_clusters(i,1) = length(CC.PixelIdxList{i});
        end
        [size_clusters,IX] = sort(size_clusters,'descend'); % in descending order
        %The first (biggest one) will be the main background cluster
        IX(1) = [];
        for iix = 1:length(IX)
            imgtofill(CC.PixelIdxList{IX(iix)}) = 1;
        end
    end    
    for z = 1:size(imgtofill,3)
        curr_slice = imgtofill(:,:,z);
        CC = bwconncomp(1-imgtofill(:,:,z),4);
        size_clusters = zeros(CC.NumObjects,1);
        if CC.NumObjects > 1
            %         fprintf('\tPASS %d\tFound z holes in this image n = %d z = %d\n', ipass, CC.NumObjects,z);
            for i = 1:CC.NumObjects
                size_clusters(i,1) = length(CC.PixelIdxList{i});
            end
            [size_clusters,IX] = sort(size_clusters,'descend'); % in descending order
            %The first (biggest one) will be the main background cluster
            IX(1) = [];
            for iix = 1:length(IX)
                if (size_clusters(iix+1) < size_clusters(1)/2) %If the cluster that I'm about to delete is very big, compared to the first cluster, then keep it
                    curr_slice(CC.PixelIdxList{IX(iix)}) = 1;
                end
            end
            imgtofill(:,:,z) = curr_slice;
        end
    end    
    for y = 1:size(imgtofill,2)
        curr_slice = squeeze(imgtofill(:,y,:));
        CC = bwconncomp(1-squeeze(imgtofill(:,y,:)),4);
        size_clusters = zeros(CC.NumObjects,1);
        if CC.NumObjects > 1
            %         fprintf('\tPASS %d\tFound y holes in this image n = %d y = %d\n', ipass, CC.NumObjects,y);
            for i = 1:CC.NumObjects
                size_clusters(i,1) = length(CC.PixelIdxList{i});
            end
            [size_clusters,IX] = sort(size_clusters,'descend'); % in descending order
            %The first (biggest one) will be the main background cluster
            IX(1) = [];
            for iix = 1:length(IX)
                if (size_clusters(iix+1) < size_clusters(1)/2) %If the cluster that I'm about to delete is very big, compared to the first cluster, then keep it
                    curr_slice(CC.PixelIdxList{IX(iix)}) = 1;
                end
            end
            imgtofill(:,y,:) = curr_slice;
        end
    end    
    for x = 1:size(imgtofill,1)
        curr_slice = squeeze(imgtofill(x,:,:));
        CC = bwconncomp(1-squeeze(imgtofill(x,:,:)),4);
        size_clusters = zeros(CC.NumObjects,1);
        if CC.NumObjects > 1
            %         fprintf('\tPASS %d\tFound x holes in this image n = %d x = %d\n', ipass, CC.NumObjects,x);
            for i = 1:CC.NumObjects
                size_clusters(i,1) = length(CC.PixelIdxList{i});
            end
            [size_clusters,IX] = sort(size_clusters,'descend'); % in descending order
            %The first (biggest one) will be the main background cluster
            IX(1) = [];
            for iix = 1:length(IX)
                if (size_clusters(iix+1) < size_clusters(1)/2) %If the cluster that I'm about to delete is very big, compared to the first cluster, then keep it
                    curr_slice(CC.PixelIdxList{IX(iix)}) = 1;
                end
            end
            imgtofill(x,:,:) = curr_slice;
        end
    end    
end
fprintf('\n> DONE.\n');
end