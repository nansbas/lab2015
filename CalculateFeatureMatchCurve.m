%% Calculate feature matching curve for my paper.
function CalculateFeatureMatchCurve
  files = dir('saved-result/dataset/101_ObjectCategories/Faces_easy/*.jpg');
  sift = cell(1,50);
  neural = cell(1,50);
  for i = 1:50
    img1 = imread(['saved-result/dataset/101_ObjectCategories/Faces_easy/',files(i).name]);
    img1 = imresize(img1, [330,260]);
    img2 = imread(['saved-result/dataset/101_ObjectCategories/Faces_easy/',files(i+10).name]);
    img2 = imresize(img2, [330,260]);
    sift{i} = CalculatePR(img1, img2, 'sift', 40);
    neural{i} = CalculatePR(img1, img2, 'neural', 40);
    close all
  end
  siftP = vertcat(sift{:});
  neuralP = vertcat(neural{:});
  plot(0:0.1:1, sort(mean(siftP,1),'descend'), 0:0.1:1, sort(mean(neuralP,1),'descend'));
  legend({'sift','neural'});
end

function f = CalculatePR(img1, img2, feature, threshold)
  range = [1,1.2,1.4,1.6,2,2.4,3.2,6];
  precision = zeros(1,length(range));
  recall = zeros(1,length(range));
  match = zeros(1,length(range));
  for i = 1:length(range)
    [p1,p2] = MatchPlot(img1, img2, feature, range(i));
    p = abs(p1 - p2);
    p = (p(:,1) < threshold) & (p(:,2) < threshold);
    precision(i) = mean(p);
    recall(i) = sum(p);
    match(i) = length(p);
  end
  recall = recall / (max(match)+max(recall)) * 2;
  [precision,idx] = sort(precision);
  recall = recall(idx);
  precision = [0, precision, 1];
  recall = [1, recall, 0];
  f = zeros(1,11);
  for idx = 1:11
    i = (idx - 1) / 10;
    for j = 1:(length(precision)-1)
      if precision(j)<=i && precision(j+1)>=i
        if precision(j+1) ~= precision(j)
          f(idx) = recall(j)+(recall(j+1)-recall(j))/(precision(j+1)-precision(j))*(i-precision(j));
        else
          f(idx) = (recall(j) + recall(j+1)) / 2;
        end
        break
      end
    end
  end
end
