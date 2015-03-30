function model = LearnV4(category)
  [rf,out] = MakeSimpleRF(9, 0:5:175, [6,6]);
  model = [];
  fp = fopen([category.category, '.txt'], 'w');
  for i = 1:length(category.files)
    img = imread(['D:\Downloads\ethz_shape_classes_v12\',category.category,'\',category.files(i).name,'.jpg']);
    [out,ori,ridge,lmap,lines,graph,v4] = SimpleCell(img, rf);
    for j = 1:size(category.files(i).groundtruth,1)
      sample = GetInRect(v4, category.files(i).groundtruth(j,:));
      model = [model; sample(:,[3,5,6,9,12])];
      fprintf(fp, '%d\n', size(sample,1));
      fprintf(fp, '%f \t%f \t%f \t%d \t%d\n', sample(:,[3,5,6,9,12])');
    end
  end
  fprintf(fp, '0\n');
  fclose(fp);
end

function sample = GetInRect(v4, rect)
  sample = v4(:,5)>=rect(1) & v4(:,5)<= rect(3) & v4(:,6)>= rect(2) & v4(:,6)<=rect(4);
  sample = v4(sample,:);
  sample(:,5) = (sample(:,5) - rect(1)) / (rect(3)-rect(1));
  sample(:,6) = (sample(:,6) - rect(2)) / (rect(4)-rect(2));
  sample(:,3) = sample(:,3) / max(sample(:,3));
  sample(:,9) = round(sample(:,9)/pi*180);
  sample(:,12) = round(sample(:,12)/pi*180);
end