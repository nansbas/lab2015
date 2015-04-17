function category = LearnV4(category)
  %category = PrepareSample(category);
  %category = PrepareModel(category);
  category = TrainModel(category);
end

function category = TrainModel(category)
  model = category.model(:, 1:8);
  neighbor = category.model(:, (1:size(model,1))+8);
  model = LearnV4SOM(model, category.sample, neighbor * 0.1, 1/16200);
  category.model = [model, neighbor];
end

function category = PrepareModel(category)
  r = 10;
  c = 10;
  model = zeros(r*c, 8);
  neighbor = zeros(r*c, r*c);
  for i = 1:c
    for j = 1:r
      model(j+(i-1)*r,1) = 1 / c * (i-0.5);
      model(j+(i-1)*r,2) = 1 / r * (j-0.5);
      if j > 1 
        neighbor(j+(i-1)*r, j+(i-1)*r-1) = 1;
      end
      if j < r
        neighbor(j+(i-1)*r, j+(i-1)*r+1) = 1;
      end
      if i > 1
        neighbor(j+(i-1)*r, j+(i-2)*r) = 1;
      end
      if i < c
        neighbor(j+(i-1)*r, j+i*r) = 1;
      end
    end
  end
  model(:,3) = rand(r*c,1) * 360 - 180;
  model(:,4) = rand(r*c,1) * 360 - 180;
  category.model = [model, neighbor];
end

function category = PrepareSample(category)
  [rf,out] = MakeSimpleRF(9, 0:5:175, [6,6]);
  sample = [];
  for i = 1:length(category.files)
    fprintf('file: %s\n', category.files(i).name);
    %img = imread(['/Users/richard/Downloads/ETHZShapeClasses-V1.2/', ...
    img = imread(['d:/Downloads/Ethz_shape_classes_v12/', ...
      category.category, '/', category.files(i).name, '.jpg']);
    [out,idx,ridge,lmap,v4] = SimpleCell(img, rf);
    for j = 1:size(category.files(i).groundtruth,1)
      rect = category.files(i).groundtruth(j,:);
      v4(:,3) = (v4(:,3) - rect(1)) / (rect(3) - rect(1));
      v4(:,4) = (v4(:,4) - rect(2)) / (rect(4) - rect(2));
      idx = v4(:,3) >= 0 & v4(:,4) >= 0 & v4(:,3) <= 1 & v4(:,4) <= 1;
      sample = cat(1, sample, v4(idx,3:7));
    end
  end
  category.sample = sample;
end