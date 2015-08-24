function [f,idx] = RectOverlap(rect, rects)
  if isempty(rect) || isempty(rects) 
    f = 0;
    idx = -1;
    return
  end
  area = (rect(3)-rect(1)) * (rect(4)-rect(2));
  a = (rects(:,3)-rects(:,1)) .* (rects(:,4)-rects(:,2));
  for i = 1:size(rects,1)
    f(i) = LineOverlap(rect(1),rect(3),rects(i,1),rects(i,3)) * ...
      LineOverlap(rect(2),rect(4),rects(i,2),rects(i,4)) / ...
      max(area, a(i));
  end
  [f,idx] = max(f);
end

function f = LineOverlap(l1, r1, l2, r2)
  l = max(l1, l2);
  r = min(r1, r2);
  if l >= r
    f = 0;
  else
    f = r - l;
  end
end