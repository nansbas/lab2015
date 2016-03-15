% Learn RBM for V4 shape feature.
%  img: training image.
%  w: weight matrix, size(w)=[n*n,m].
%  b,c: bias vector, size(b)=[1,n*n] for visible units, size(c)=[1,m] for hidden.
%  lrate: learning rate.
function [w,b,c,response] = LearnV4ShapeRBM(img, lrate, w, b, c)
  if ~exist('w','var'), w = rand(19*19,128); end
  if ~exist('b','var'), b = rand(1,19*19); end
  if ~exist('c','var'), c = rand(1,128); end
  rfsize = 9; % n = rfsize*2+1.
  bsize = 100;
  [rf,~] = MakeSimpleRF(rfsize, 0:30:170);
  [~,~,ridge] = SimpleCell(img, rf);
  mridge = max(ridge(:));
  out = ridge/mridge;
  ridge = (ridge>mridge/10);
  v = [];
  response = zeros(size(ridge));
  for x = (rfsize+1):(size(img,2)-rfsize)
    for y = (rfsize+1):(size(img,1)-rfsize)
      if ~ridge(y,x), continue; end
      patch = out(y-rfsize:y+rfsize,x-rfsize:x+rfsize);
      v = cat(1, v, patch(:)');
      response(y,x) = max(patch(:)'*w+c);
      if size(v,1) == bsize
        [w,b,c] = TrainRBM(v,w,b,c,lrate); 
        v = [];
      end
    end
  end
  if ~isempty(v), [w,b,c] = TrainRBM(v,w,b,c,lrate); end
end

% Train RBM.
%  v1: samples piled in rows.
function [w,b,c] = TrainRBM(v1, w, b, c, lrate)
  n = size(v1,1);
  h1 = sigmrnd(v1*w+repmat(c,n,1));
  v2 = sigmrnd(h1*w'+repmat(b,n,1));
  h2 = sigm(v2*w+repmat(c,n,1));
  c1 = v1' * h1;
  c2 = v2' * h2;
  w = w + lrate * (c1 - c2) / n;
  b = b + lrate * sum(v1 - v2) / n;
  c = c + lrate * sum(h1 - h2) / n;
  err = sum(sum((v1 - v2) .^ 2)) / n;
  fprintf('TrainRBM, err=%f\n', err);
end

function X = sigmrnd(P)
  X = double(1./(1+exp(-P)) > rand(size(P)));
end

function X = sigm(P)
  X = 1./(1+exp(-P));
end