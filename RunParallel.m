function RunParallel(ethzv4)
  pool = parpool(4);
  for runCat = [4,5]
    r = {};
    parfor j = 1:5
      r{j} = RunCategory(ethzv4, runCat, j);
    end
    result = vertcat(r{:});
    ethzv4(runCat).result = result;
    allpos = [44,55,91,66,33];
    [~,idx] = sort(result(:,8)/max(result(:,8))-result(:,7));
    r = result(idx,:);
    for i = 1:size(r,1)
      r(i,1) = sum(r(1:i,9)<=0.4)/255;
      r(i,2) = sum(r(1:i,9)>0.4)/allpos(runCat);
    end
    [~,idx] = unique(r(:,1));
    idx2 = 1;
    for i = 2:length(idx)
      idx2 = [idx2, idx(i)-1, idx(i)];
    end
    idx2 = [idx2, size(r,1)];
    r = r(idx2,1:2);
    ethzv4(runCat).fppi = r;
    save('saved-result/ethzv4.mat', 'ethzv4');
  end
  delete(pool);
end

function f = RunCategory(ethzv4, runCat, testCat)
  result = [];
  i = testCat;
  for j=1:length(ethzv4(i).files)
    [r,jj,maxr]=FindV4ModelInImage(ethzv4(runCat).cluster,ethzv4(runCat).model,ethzv4(i).files(j));
    if i~=runCat && ~isempty(jj)
      jj(:,7) = 0;
    end
    if ~isempty(jj)
      jj = [repmat(i,size(jj,1),1),repmat(j,size(jj,1),1),jj];
    end
    result=[result;jj];
    fprintf('Runcat=%d, ok: %d, %d, max=%d\n', runCat, i, j, maxr);
  end
end