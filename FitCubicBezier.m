% Fit cubic bezier curve from a series of line points.
function f = FitCubicBezier(line)
  xy = line(:,1:2);
  n = size(xy,1);
  t = linspace(0, 1, n)';
  P0 = xy(1,:);
  P3 = xy(n,:);
  A1 = sum((t.^2).*((1-t).^4))*9;
  A2 = sum((t.^4).*((1-t).^2))*9;
  A3 = sum((t.^3).*((1-t).^3))*9;
  PI = xy - repmat((1-t).^3,1,2)*diag(P0) - repmat(t.^3,1,2)*diag(P3);
  C1 = sum(repmat(t.*((1-t).^2),1,2) .* PI,1) * 3;
  C2 = sum(repmat((1-t).*(t.^2),1,2) .* PI,1) * 3;
  P1 = (A2*C1 - A3*C2) / (A1*A2 - A3*A3);
  P2 = (A1*C2 - A3*C1) / (A1*A2 - A3*A3);
  f = [P0',P1',P2',P3'];
end