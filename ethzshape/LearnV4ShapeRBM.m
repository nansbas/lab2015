% Learn RBM for V4 shape feature.
%  img: training image.
%  w: weight matrix, size(w)=[n*n*k,m]. n is patch size.
%  k is #orientations. m is #output neurons.
%  b,c: bias vector, size(b)=[1,n*n*k] for visible units, size(c)=[1,m] for hidden.
%  lrate: learning rate.
function [w,b,c,response] = LearnV4ShapeRBM(img, lrate, w, b, c)
  rng('shuffle');
  if ~exist('w','var'), w = rand(19*19*4,512); end
  if ~exist('b','var'), b = rand(1,19*19*4); end
  if ~exist('c','var'), c = rand(1,512); end
  rfsize = 9; % n = rfsize*2+1.
  bsize = 800;
  [rf,~] = MakeSimpleRF(rfsize, 0:45:170);
  [out,~,ridge] = SimpleCell(img, rf);
  mridge = max(ridge(:));
  out = out/mridge;
  ridge = (ridge>mridge/8);
  v = [];
  response = zeros(size(ridge));
  dw = 0; db = 0; dc = 0;
  for x = (rfsize+1):(size(img,2)-rfsize)
    for y = (rfsize+1):(size(img,1)-rfsize)
      if ~ridge(y,x), continue; end
      patch = out(y-rfsize:y+rfsize,x-rfsize:x+rfsize,:);
      response(y,x) = max(patch(:)'*w+c);
      if lrate <= 0, continue; end
      v = cat(1, v, patch(:)');
      if size(v,1) == bsize
        [w,b,c,dw,db,dc] = TrainRBM(v,w,b,c,dw,db,dc,lrate,0.5,0.0001); 
        v = [];
      end
    end
  end
  if ~isempty(v), [w,b,c,~,~,~] = TrainRBM(v,w,b,c,dw,db,dc,lrate,0.5,0.0001); end
end

% Train RBM.
%  v1: samples piled in rows.
function [w,b,c,dw,db,dc] = TrainRBM(v1, w, b, c, dw, db, dc, lrate, moment, decay)
  n = size(v1,1);
  h1 = sigmrnd(v1*w+repmat(c,n,1));
  v2 = sigmrnd(h1*w'+repmat(b,n,1));
  h2 = sigm(v2*w+repmat(c,n,1));
  c1 = v1' * h1;
  c2 = v2' * h2;
  dw = dw * moment + lrate * (c1 - c2) / n;
  db = db * moment + lrate * sum(v1 - v2) / n;
  dc = dc * moment + lrate * sum(h1 - h2) / n;
  w = w * (1-decay) + dw;
  b = b * (1-decay) + db;
  c = c * (1-decay) + dc;
  err = sum(sum((v1 - v2) .^ 2)) / n;
  fprintf('TrainRBM, err=%f\n', err);
end

function X = sigmrnd(P)
  X = double(1./(1+exp(-P)) > rand(size(P)));
end

function X = sigm(P)
  X = 1./(1+exp(-P));
end