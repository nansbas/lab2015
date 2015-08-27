function f = FitMpeg7Data(files)
  f = [];
  param = [1,10;2,10;2,20;3,20;3,40];
  for i = 1:size(param,1)
    f1 = FitMpeg7DataWithParam(files, param(i,1), param(i,2));
    f = cat(1, f, f1);
  end
end

function f = FitMpeg7DataWithParam(files, threshold, minlength)
  f = [];
  for i = 1:length(files)
    img = files(i).image;
    img = padarray(img, [10,10], img(1,1));
    img = double(edge(img));
    [~,lines] = FindLine(img, img, 0.1, 20);
    % imwrite(Map2Color(map),['temp/test-',num2str(i),'.png']);
    v4 = FindV4Feature(lines, threshold, minlength);
    close all
    bezier = FitCubicBezier(lines, v4);
    % save(['temp/bezier-',num2str(i),'.mat'], 'bezier');
    alline = vertcat(lines{:});
    xy = [];
    for k = 1:size(bezier,1)
      xy = cat(1, xy, PlotCubicBezier(reshape(bezier(k,:),2,4))');
      close all
    end
    d = DiffMatrix(alline, xy, 2);
    d = min(d,[],2);
    f = cat(1, f, [size(bezier,1), mean(d), max(d)]);
  end
  f = [threshold, minlength, mean(f)];
end

% Compute difference matrix of two set of row vectors of specified width.
function f = DiffMatrix(rows1, rows2, width)
  if width == 1
    f = abs(repmat(rows1(:,1),1,size(rows2,1)) - repmat(rows2(:,1)',size(rows1,1),1));
  else
    f = zeros(size(rows1,1),size(rows2,1));
    for i = 1:width
      d = repmat(rows1(:,i),1,size(rows2,1)) - repmat(rows2(:,i)',size(rows1,1),1);
      f = f + d.^2;
    end
    f = sqrt(f);
  end
end
