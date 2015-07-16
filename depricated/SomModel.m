function [out1,out2] = SomModel(action, arg0, arg1, arg2)
  if (strcmp(action,'init')) 
    out1 = InitModel(8, arg0(1), arg0(2), 1, 180);
    out2 = InitModel(8, arg0(1), arg0(2), 2, 360);
  elseif (strcmp(action,'learn-complex'))
    out1 = SomLearnComplexCell(arg0, arg1, arg2, 0.8, 1, 0.01);
  elseif (strcmp(action,'learn-v4'))
    out1 = SomLearnV4Cell(arg0, arg1, 1, 0.2);
  elseif (strcmp(action,'draw'))
    subplot(2,2,1);
    DrawComplexCell(arg0, arg2(1), arg2(2));
    subplot(2,2,2);
    DrawSom(arg0, arg2(1), arg2(2));
    subplot(2,2,3);
    DrawV4Cell(arg1, arg2(1), arg2(2));
    subplot(2,2,4);
    DrawSom(arg1, arg2(1), arg2(2));
  end
end

function som = InitModel(nw, width, height, nOri, rangeOri)
  [x,y] = meshgrid(1:nw);
  som = [x(:)/nw*width,y(:)/nw*height,rand(nw*nw,nOri)*rangeOri,ones(nw*nw,1)];
  x = repmat(x(:), 1, nw*nw);
  y = repmat(y(:), 1, nw*nw);
  d = (x-x').^2 + (y-y').^2;
  som = [som,d<=2&d>0];
end

function DrawSom(cells, width, height)
  r1 = 4;
  offset = size(cells,2)-size(cells,1);
  hold on
  for i = 1:size(cells,1)
    rectangle('Position', [cells(i,1)-r1,cells(i,2)-r1,2*r1,2*r1], ...
      'Curvature', [1,1], ...
      'LineWidth', 1);
    for j = 1:i-1
      if cells(i,j+offset) > 0 
        line([cells(i,1),cells(j,1)], [cells(i,2),cells(j,2)]);
      end
    end
  end
  hold off
  %axis equal
  set(gca, 'YDir', 'reverse', 'XLim', [0,width], 'YLim', [0,height]);
end

function DrawV4Cell(cells, width, height)
  r1 = 8;
  r2 = 6;
  cells(:,5) = cells(:,5) / max(cells(:,5));
  x1 = cells(:,1) + r2 * cos(cells(:,3)/180*pi);
  x2 = cells(:,1) + r2 * cos(cells(:,4)/180*pi);
  y1 = cells(:,2) + r2 * sin(cells(:,3)/180*pi);
  y2 = cells(:,2) + r2 * sin(cells(:,4)/180*pi);
  hold on
  [~,idx] = sort(cells(:,5));
  for i = idx'
    rectangle('Position', [cells(i,1)-r1,cells(i,2)-r1,2*r1,2*r1], ...
      'Curvature', [1,1], ...
      'EdgeColor', 1-[1,1,1]*cells(i,5), ...
      'LineWidth', 1);
    line([x1(i),cells(i,1)],[y1(i),cells(i,2)], ...
      'Color', 1-[1,1,0]*cells(i,5), ...
      'LineWidth', 2);
    line([cells(i,1),x2(i)],[cells(i,2),y2(i)], ...
      'Color', 1-[1,0.4,0.6]*cells(i,5), ...
      'LineWidth', 2);
  end
  hold off
  %axis equal
  set(gca, 'YDir', 'reverse', 'XLim', [0,width], 'YLim', [0,height]);
end

function DrawComplexCell(cells, width, height)
  r1 = 6;
  r2 = 4;
  cells(:,4) = cells(:,4) / max(cells(:,4));
  x1 = cells(:,1) - r2 * cos(cells(:,3)/180*pi);
  x2 = cells(:,1) + r2 * cos(cells(:,3)/180*pi);
  y1 = cells(:,2) + r2 * sin(cells(:,3)/180*pi);
  y2 = cells(:,2) - r2 * sin(cells(:,3)/180*pi);
  hold on
  [~,idx] = sort(cells(:,4));
  for i = idx'
    rectangle('Position', [cells(i,1)-r1,cells(i,2)-r1,2*r1,2*r1], ...
      'Curvature', [1,1], ...
      'EdgeColor', 1-[1,1,1]*cells(i,4), ...
      'LineWidth', 1);
    line([x1(i),x2(i)],[y1(i),y2(i)], ...
      'Color', 1-[1,1,0]*cells(i,4), ...
      'LineWidth', 2);
  end
  hold off
  %axis equal
  set(gca, 'YDir', 'reverse', 'XLim', [0,width], 'YLim', [0,height]);
end