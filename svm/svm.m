
%% Genre Prediction from Lyrics
clear;

%% Preprocessing
% vocabList = [];
% load('rawdb');
% X = [];
% for song=1:size(rawdb,1)
%     %song
%     [features vocabList] = processLyric(rawdb{song,2},vocabList);
%     X = [X  zeros(size(X,1),size(features',2) - size(X,2))];
%     X = [X ; features'];
%     if(mod(song,500)==0)
%         song
%         vocabList= vocabList(find(sum(X)~=1)');
%         X = X(:,find(sum(X)~=1));
%     end
% end
% cats = cell2mat(rawdb(1:size(X,1),1));
% nWords = size(X,2);
% nSongs = size(X,1);

%% Lyrics to vector of features
% Each row of X is a song
% Each column of X is a frequency of this word for a song(specified in row)
% Each row of y is genre of a song(specified in row)

% load('db');
% nWords = 15000;
% nSongs = size(db,1);
% 
% WordInd = zeros(nSongs,nWords);
% SongCat = db(:,1:2);
% cats = zeros(nSongs,1);
% 
% for i=1:nSongs
%     cats(i) = SongCat{i,2};
%     str = db(i,3);
%     index = 0;
%     while ~strcmp(str,'')
%         [index , str] = strtok(str);
%         try
%             index = str2num(index{1});
%         catch
%             index = index{1,1}; continue;
%         end
%         WordInd(i,index) = WordInd(i,index)+1;
%     end
% end
% 
% X = WordInd;

%%
load('newdb');

%% Training
% We need to do these manually:
% % addpath to the libsvm toolbox
% addpath('../svm/libsvm-3.12/matlab');
%
% % addpath to the data
% dirData = '../svm/libsvm-3.12';
% addpath(dirData);
y=cats;

TestRatio = 0.2;
nCat = 6;

% Find most frequent nCat category
cidx = unique(cats); %Category indices
catfreq = zeros(size(cidx,1),1);
for i=1:size(cidx,1)
    catfreq(i,:) = sum(cats==cidx(i));
end
[~,catfreqidx] = sort(catfreq,1,'descend');

%adding most frequent 5 category to y
% y=[];
% newX=[];
% for c = (1:nCat)
%     y = [y; cats(find(cats==catfreqidx(c)))];
%     newX = [newX; X(find(cats==catfreqidx(c)),:)];
% end
% X=newX;
% nSongs = size(X,1);
idx = randperm(nSongs);
% Pick %80(1-TestRatio) of data as Training Set
border = floor(nSongs*(1-TestRatio));
XTrain = X(idx(1:border),:);
yTrain = y(idx(1:border),:);
%Pick %20(TestRatio) of data as Test Set
XTest =  X(idx(border+1:end),:);
yTest =  y(idx(border+1:end),:);

Results =[];
model = {};
trainId = 1;

%% Linear
tic
model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 0 -b 1'));
[~, accuracy,~] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
Results = [Results ; accuracy',0,-1,-1,-1,-1];
model{trainId,2} = toc;
model{trainId,3} = [accuracy',0,-1,-1,-1,-1];
trainId = trainId +1;

%% Polynomial
for d = [2:4]
    for g = [1e-5  1e+0  1e+5]
        for r= [1e-5  1e+0  1e+5]
            [d g r]
            tic
            model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 1 -b 1 -d %d -g %d -r %d -q',d,g,r));
            [~, accuracy,~] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
            Results = [Results ; accuracy',1,d,g,r,-1];
            model{trainId,2} = toc;
            model{trainId,3} = [accuracy',1,d,g,r,-1];
            trainId = trainId +1;
        end
    end
end

%% Gaussian
for g = [1e-10 1e-6 1e-3 1e+0 1e+3 1e+6 1e+10]    
    for c = [1e-10 1e-6 1e-3 1e+0 1e+3 1e+6 1e+10]  
        tic
        [g c]
        model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 2 -b 1 -g %d -c %d -q',g,c));
        [~, accuracy,~] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
        Results = [Results ; accuracy',2,g,c,-1,-1]  
        model{trainId,2} = toc;  
        model{trainId,3} = [accuracy',2,g,c,-1,-1];
        trainId = trainId +1;
    end
end

%% Sigmoid
for g = [1e-10 1e-5  1e+0 1e+5  1e+10]
    for r= [1e-10 1e-5  1e+0 1e+5  1e+10]
        tic
        model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 3 -b 1 -g %d -r %d -q',g,r));
        [~, accuracy,~] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
        Results = [Results ; accuracy',3,g,r,-1,-1]   
        model{trainId,2} = toc;       
        model{trainId,3} = [accuracy',3,g,r,-1-1];
        trainId = trainId +1;
    end
end





