% Plot rasterized cubic bezier curve.
%   p: control points as in [x1,x2,x3,x4;y1,y2,y3,y4].
%   xy: curve points as in [x, ...; y, ...].
function xy = PlotCubicBezier(p)
  t = 0;
  xy = [];
  lastxy = [];
  dp = p * [-1,0,0;1,-1,0;0,1,-1;0,0,1];
  while 1
    if t >= 1, t = 1; end
    thisxy = round(sum(p * diag([(1-t)^3,3*t*(1-t)^2,3*(1-t)*t^2,t^3]), 2));
    if ~isempty(lastxy) && (abs(lastxy(1)-thisxy(1)) > 1 || abs(lastxy(2)-thisxy(2)) > 1)
      intxy = round((lastxy + thisxy)/2);
      xy = cat(2, xy, intxy);
    end
    if isempty(lastxy) || lastxy(1)~=thisxy(1) || lastxy(2)~=thisxy(2)
      xy = cat(2, xy, thisxy);
      lastxy = thisxy;
    end
    if t >= 1, break; end
    % B'(t) = 3(1-t)^2(P_1-P_0) + 6(1-t)t(P_2-P_1) + 3t^2(P_3-P_2).
    dB = sum(dp * diag([3*(1-t)^2,6*(1-t)*t,3*t^2]), 2);
    % t += 1/sqrt(Bx'^2+By'^2).
    t = t + 1/sqrt(sum(dB.^2)); % do it in step of a half.
  end
  plot(xy(1,:),xy(2,:));
end