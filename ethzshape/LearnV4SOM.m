function LearnV4SOM(files)
end

function GetGroundTruth(files)
  for i = 1:length(files)
    v4 = files(i).v4;
    v4 = [v4, ComputePeakPointAndScale(v4)];
    gt0 = files(i).groundtruth;
    % Relax groundtruth boundary box.
    gt = gt0 * (diag(ones(1,4))+0.03*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1]);
    for j = 1:size(files(i).groundtruth,1)
      % Find features within groundtruth box.
      v = (v4(:,[1,3,10])<gt(j,3)) + (v4(:,[1,3,10])>gt(j,1)) + (v4(:,[2,4,11])<gt(j,4)) + (v4(:,[2,4,11])>gt(j,2));
      v = v4(sum(v,2)==12,:);
      % Use mask.
      if isfield(files(i),'mask')
        m = files(i).mask{j};
      end
      % Normalize middle point position and scale.
      v(:,10) = v(:,10) - (gt(j,1)+gt(j,3))/2;
      v(:,11) = v(:,11) - (gt(j,2)+gt(j,4))/2;
      v(:,10:12) = v(:,10:12) / sqrt((gt0(j,3)-gt0(j,1)+1)*(gt0(j,4)-gt0(j,2)+1));
      v = NormalizeV4(v);
    end
  end
end

% Compute the middle peak point and scale of V4 features.
function f = ComputePeakPointAndScale(v4)
  ab = sum(v4(:,5:6),2);
  ee = ones(size(v4,1),1);
  f(:,1) = sum(v4(:,1:4).*[ee,ab,ee,-ab],2)/2;
  f(:,2) = sum(v4(:,1:4).*[-ab,ee,ab,ee],2)/2;
  f(:,3) = sqrt(sum((v4(:,1:4)*[0.5,0;0,0.5;-0.5,0;0,-0.5]).^2,2));
end

% Normalize V4 feature.
function v = NormalizeV4(v)
  v(:,1:4) = v(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  v(:,1:4) = v(:,1:4)./repmat(sqrt(sum(v(:,1:2).^2,2)),1,4);
end

