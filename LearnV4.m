function category = LearnV4(category)
  %{
  [rf,out] = MakeSimpleRF(9, 0:5:175, [6,6]);
  sample = [];
  for i = 1:length(category.files)
    fprintf('%s: %d: %s\n', category.category, i, category.files(i).name);
    img = imread(['D:\Downloads\ethz_shape_classes_v12\',category.category,'\',category.files(i).name,'.jpg']);
    [out,ori,ridge,lmap,lines,graph,v4] = SimpleCell(img, rf);
    for j = 1:size(category.files(i).groundtruth,1)
      aSample = GetInRect(v4, category.files(i).groundtruth(j,:));
      sample = cat(1, sample, aSample(:,[3,5,6,9,12]));
    end
  end
  category.sample = sample;
  %}
  category.model = LearnV4SOM(category.model, category.sample, 0.01, 0.02);
end

function sample = GetInRect(v4, rect)
  sample = v4(:,5)>=rect(1) & v4(:,5)<= rect(3) & v4(:,6)>= rect(2) & v4(:,6)<=rect(4);
  sample = v4(sample,:);
  sample(:,5) = (sample(:,5) - rect(1)) / (rect(3)-rect(1));
  sample(:,6) = (sample(:,6) - rect(2)) / (rect(4)-rect(2));
  sample(:,3) = sample(:,3) / max(sample(:,3));
end