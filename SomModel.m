function [som,v4pos] = SomModel(action, som, arg1, arg2)
  if (strcmp(action,'init')) 
    som = InitModel(8, arg1, arg2);
  elseif (strcmp(action,'learn'))
    ncells = size(som,1);
    neighbor = som(:,5:ncells+4);
    [som,v4pos] = SomLearn(som, arg1, arg2, 0.8, 1, 0.03);
    som = [som(:,1:4),neighbor,som(:,5:ncells+4)];
  elseif (strcmp(action,'draw'))
    subplot(1,2,1);
    DrawComplexCell(som, arg1, arg2);
    subplot(1,2,2);
    DrawSom(som, arg1, arg2);
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

function DrawSom(cells, width, height)
  r1 = 4;
  hold on
  for i = 1:size(cells,1)
    rectangle('Position', [cells(i,1)-r1,cells(i,2)-r1,2*r1,2*r1], ...
      'Curvature', [1,1], ...
      'LineWidth', 1);
    for j = 1:i-1
      if cells(i,j+4) > 0 
        line([cells(i,1),cells(j,1)], [cells(i,2),cells(j,2)]);
      end
    end
  end
  hold off
  %axis equal
  set(gca, 'YDir', 'reverse', 'XLim', [0,width], 'YLim', [0,height]);
end

function DrawComplexCell(cells, width, height)
  r1 = 8;
  r2 = 6;
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