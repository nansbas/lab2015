%% Detect Scalable Image Features.
% - img : input image.
% - scales : feature scales.
% - plotFeatures : boolean indicating whether to plot result.
% return values:
% - f : a list of points in the following format:
%       X Position, Y Position, Scale, Entropy (HD),
%       Inter-scale saliency (WD), Scale Saliency (YD)
% remarks:
% - this function needs 'kadir2001' functions.
% references:
% - Kadir,Brady. Scale, saliency and image description. IJCV,2001,45(2):83-105.
function f = FeatureDetect(img, scales, plotFeatures)
    %% prepare parameters
    startScale = scales(1);
    stopScale = scales(2);
    AA=0;			%Anti-aliased sampling (not available with Parzen windowing).
    nbins=16;		%number of bins (set to 0 for Parzen window PDF estimation)
    gsigma=1;		%sigma for Parzen window (if nbins=0. Only available on 1D)
    wt=0.7;                 %threshold on Saliency values
    yt=0;                   %threshold on inter-scale saliency
    div=(255/(nbins-1));	%quantisation of image.
    %% calculation
    Y=CalcScaleSaliency(uint8(double(Image2Gray(img))./div), startScale, stopScale, nbins, gsigma, AA);
    f = GreedyCluster(Y, wt, yt);
    if ~isempty(f)
        f(1:2,:) = f([2,1],:); % Swap because Kadir's implementation output in Y,X order.
    end
    %% plot features
    if exist('plotFeatures', 'var') && plotFeatures
        figure;
        imshow(img);
        for i = 1:size(f, 2)
            rectangle('Position', [f(1,i)-f(3,i), f(2,i)-f(3,i), f(3,i)*2+1, f(3,i)*2+1], ...
                'Curvature', [1,1], 'EdgeColor', 'green');
        end
    end
end