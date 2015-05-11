function [som,v4pos] = SomModel(action, som, arg1, arg2)
  if (strcmp(action,'init')) 
    som = InitModel(8, arg1, arg2);
  elseif (strcmp(action,'learn'))
    [som,v4pos] = SomLearn(som, arg1, arg2, 0.8, 1, 0.1);
  elseif (strcmp(action,'draw'))
    DrawComplexCell(som);
  end
end

function som = InitModel(nw, width, height)
  [x,y] = meshgrid(1:nw);
  som = [x(:)/nw*width,y(:)/nw*height,rand(nw*nw,1)*180,ones(nw*nw,1)];
  x = repmat(x(:), 1, nw*nw);
  y = repmat(y(:), 1, nw*nw);
  d = (x-x').^2 + (y-y').^2;
  som = [som,d<=2&d>0];
end

function DrawComplexCell(cells)
  r1 = 5;
  r2 = 3;
  cells(:,4) = cells(:,4) / max(cells(:,4));
  x1 = cells(:,1) - r2 * cos(cells(:,3)/180*pi);
  x2 = cells(:,1) + r2 * cos(cells(:,3)/180*pi);
  y1 = cells(:,2) + r2 * sin(cells(:,3)/180*pi);
  y2 = cells(:,2) - r2 * sin(cells(:,3)/180*pi);
  hold on
  for i = 1:size(cells,1)
    rectangle('Position', [cells(i,1)-r1,cells(i,2)-r1,2*r1,2*r1], ...
      'Curvature', [1,1], ...
      'EdgeColor', 1-[1,1,1]*cells(i,4), ...
      'LineWidth', 1);
    line([x1(i),x2(i)],[y1(i),y2(i)], ...
      'Color', 1-[1,1,0]*cells(i,4), ...
      'LineWidth', 2);
  end
  hold off
  axis equal
  set(gca, 'YDir', 'reverse', 'XLim', [0,178], 'YLim', [0,215]);
end