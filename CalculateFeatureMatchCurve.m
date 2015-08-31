%% Calculate feature matching curve for my paper.
function [siftP, neuralP] = CalculateFeatureMatchCurve
  files = dir('saved-result/dataset/101_ObjectCategories/Faces_easy/*.jpg');
  sift = cell(1,11);
  neural = cell(1,11);
  for i = 1:60
    img1 = imread(['saved-result/dataset/101_ObjectCategories/Faces_easy/',files(i).name]);
    img1 = imresize(img1, [330,260]);
    img2 = imread(['saved-result/dataset/101_ObjectCategories/Faces_easy/',files(i+20).name]);
    img2 = imresize(img2, [330,260]);
    [p,r] = CalculatePR(img1, img2, 'sift', 40);
    for j = 1:length(p)
      idx = round(p(j) * 10 + 1);
      if idx >= 1 && idx <= 11, sift{idx} = [sift{idx}, r(j)]; end
    end
    [p,r] = CalculatePR(img1, img2, 'neural', 40);
    for j = 1:length(p)
      idx = round(p(j) * 10 + 1);
      if idx >= 1 && idx <= 11, neural{idx} = [neural{idx}, r(j)]; end
    end
    close all
  end
  siftP = AverageOnCell(sift);
  neuralP = AverageOnCell(neural);
  plot(siftP(:,1), siftP(:,2), neuralP(:,1), neuralP(:,2));
  legend({'sift','neural'});
end

function [precision,recall] = CalculatePR(img1, img2, feature, threshold)
  range = [1,1.2,1.4,1.6,2,2.4,3.2,6];
  precision = zeros(1,length(range));
  recall = zeros(1,length(range));
  for i = 1:length(range)
    [p1,p2,~,f1,f2] = MatchPlot(img1, img2, feature, range(i));
    p = abs(p1 - p2);
    p = (p(:,1) < threshold) & (p(:,2) < threshold);
    precision(i) = mean(p);
    recall(i) = sum(p)/min(size(f1,2),size(f2,2));
  end
end

function f = AverageOnCell(cellf)
  f = [];
  for i = 1:11
    p = (i - 1) / 10;
    if ~isempty(cellf{i})
      f = cat(1, f, [p, mean(cellf{i})]);
    end
  end
end