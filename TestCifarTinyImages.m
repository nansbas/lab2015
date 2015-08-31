function TestCifarTinyImages
  [in,out] = LoadCifarData;
  save('cifar10.mat', 'in', 'out');
end

function [input,output] = LoadCifarData
  names = {'data_batch_1.mat', 'data_batch_2.mat', 'data_batch_3.mat', ...
    'data_batch_4.mat', 'data_batch_5.mat', 'test_batch.mat'};
  input = [];
  output = [];
  for i = 1:6
    data = load(['saved-result/dataset/cifar-10-batches-mat/',names{i}]);
    for j = 1:size(data.data,1)
      img = permute(reshape(data.data(j,:),32,32,3),[2,1,3]);
      img2 = Image2Gray(img);
      f1 = NeuralFeature(img(:,:,1), [15,16,8]');
      f2 = NeuralFeature(img(:,:,1), [15,16,8]');
      f3 = NeuralFeature(img(:,:,1), [15,16,8]');
      f4 = NeuralFeature(img2, [14,14,6;14,17,6;17,14,6;17,17,6]');
      input = cat(2, input, [f1(:);f2(:);f3(:);f4(:)]);
      z = zeros(10,1);
      z(data.labels(j)+1) = 1;
      output = cat(2, output, z);
    end
  end
end