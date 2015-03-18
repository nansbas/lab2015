folder = '../ethz-jpg/';
files = dir([folder, '*.jpg']);
load som.mat;
k = [-1,-1,-1;-1,8,-1;-1,-1,-1]/8;
out = ones(79,79);
for loop=1:20
for i = 1:length(files)
    fprintf('%d: file %s\n', i, files(i).name);
    img = imread([folder, files(i).name]);
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    if size(img,3) > 1
        img = img(:,:,1);
    end
    img = abs(imfilter(img, k, 'replicate'));
    img = double(img)/double(max(img(:)))*1.5;
    img(img>1) = 1;
    som = LearnSimpleSOM(som, img, neighbor, 0.001);
    for j = 1:size(som,3)
       x = mod(j-1,8);
       y = (j-x-1)/8;
       out((1:9)+y*10, (1:9)+x*10) = som(:,:,j);
    end
    imwrite(out, 'som.png');
    save('-mat', 'som.mat', 'som', 'neighbor');
end
end

