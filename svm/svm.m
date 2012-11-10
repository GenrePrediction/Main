
%% Genre Prediction from Lyrics
clear;

%% Preprocessing
vocabList = [];
load('db\rawdbbig.mat');
db=rawdbbig;
X = [];tic
for song=1:size(db,1)
    %song
    [features vocabList] = processLyric(db{song,2},vocabList);
    X(song,1:size(features,1)) = features';
    if(mod(song,500)==0)
        toc
        tic
        song
        vocabList= vocabList(find(sum(X)>10)');
        X = X(:,find(sum(X)>10));
    end
end
toc
cats = cell2mat(db(1:size(X,1),1));
nWords = size(X,2);
nSongs = size(X,1);

%% If preprocessed, Skip First step do this.
load('db/newdblarge');

%% Training
% We need to do these manually:
% % addpath to the libsvm toolbox
addpath('libsvm-3.12');
addpath('libsvm-3.12/windows');

y=cats;

TestRatio = 0.1;
Results =[];
model = {};
trainId = 1;

%% Model Structure:
% 1. Column : Specify the Kernel (0:Linear, 1:Polynomial, 2:Gaussian, 3:Sigmoid)
% 2. Column : Command of libsvm. We can see parameters in it
% 3. Column : Accuracies of being in top 1, top 2, top 3 respectively
% 4. Column : Standart Deviations of Accuracies
% 5. Column : Time of Execution
% 6. Column : Details of sub training
%% 

%% Final Train

%% preloading
c= 1e+6;
command = sprintf('-t 0 -b 1 -h 0 -c %d',c);
n = size(X,1);
mix = randperm(n);
X = X(mix,:);
y = y(mix,:);
XTrain = X(1:10000,:);
yTrain = y(1:10000);
XTest = X(10001:50000,:);
yTest = y(10001:50000);

%% Preloaded
addpath('libsvm-3.12');
addpath('libsvm-3.12/windows');
load('db/finaltrain');

%% Training
tic
model = svmtrain(yTrain, XTrain, command);
time = toc;

%% Linear
for c=1e+6
    c
    command = sprintf('-t 0 -b 1 -h 0 -c %d',c);
    [accuracy,stdev,time, submodel ] = train (X_PickC, y_PickC,TestRatio ,10,{},command )
    model{trainId,1} = 0 ;
    model{trainId,2} = command;
    model{trainId,3} = accuracy ;
    model{trainId,4} = stdev;
    model{trainId,5} = time;
    model{trainId,6} = submodel;
    trainId = trainId +1
end

%% Linear
for c =1%[1e-10 1e-6 1e-3 1e+0 1e+3 1e+6 1e+10]
    tic
    model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 0 -b 1 -c %d',c));
    [pred, accuracy,prob] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
    %top 2 and 3 accuracy
    lookuptable=model{trainId,1}.Label;
    [~,probi]=sort(prob,2,'descend');
    top2 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest)/size(probi,1);
    top3 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest|lookuptable(probi(:,3))==yTest)/size(probi,1);
    Results = [Results ; accuracy',0,c,-1,-1,top2,top3];
    model{trainId,2} = toc;
    model{trainId,3} = [accuracy',0,c,-1,-1,top2,top3];
    trainId = trainId +1;
end

%% Polynomial
for d = [2:4]
    for g = [1e-5  1e+0  1e+5]
        for r= [1e-5  1e+0  1e+5]
            [d g r]
            tic
            model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 1 -b 1 -d %d -g %d -r %d -q',d,g,r));
            [~, accuracy,prob] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
            %top 2 and 3 accuracy
            lookuptable=model{trainId,1}.Label;
            [~,probi]=sort(prob,2,'descend');
            top2 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest)/size(probi,1);
            top3 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest|lookuptable(probi(:,3))==yTest)/size(probi,1);
            Results = [Results ; accuracy',1,d,g,r,top2,top3];
            model{trainId,2} = toc;
            model{trainId,3} = [accuracy',1,d,g,r,top2,top3];
            trainId = trainId +1;
        end
    end
end

%% Gaussian
for g =1e-3 %[1e-10 1e-6 1e-3 1e+0 1e+3 1e+6 1e+10]    
    for c = 1e+3 %[1e-10 1e-6 1e-3 1e+0 1e+3 1e+6 1e+10]  
        tic
        [g c]
        model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 2 -b 1 -g %d -c %d -q',g,c));
        [~, accuracy,probi] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
        %top 2 and 3 accuracy
        lookuptable=model{trainId,1}.Label;
        [~,probi]=sort(prob,2,'descend');
        top2 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest)/size(probi,1);
        top3 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest|lookuptable(probi(:,3))==yTest)/size(probi,1);
        Results = [Results ; accuracy',2,g,c,-1,top2,top3]  
        model{trainId,2} = toc;  
        model{trainId,3} = [accuracy',2,g,c,-1,top2,top3];
        trainId = trainId +1;
    end
end

%% Sigmoid
for g = [1e-10 1e-5  1e+0 1e+5  1e+10]
    for r= [1e-10 1e-5  1e+0 1e+5  1e+10]
        tic
        model{trainId,1} = svmtrain(yTrain, XTrain, sprintf('-t 3 -b 1 -g %d -r %d -q',g,r));
        [~, accuracy,probi] =   svmpredict(yTest, XTest, model{trainId,1}, '-b 1');
        %top 2 and 3 accuracy
        lookuptable=model{trainId,1}.Label;
        [~,probi]=sort(prob,2,'descend');
        top2 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest)/size(probi,1);
        top3 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest|lookuptable(probi(:,3))==yTest)/size(probi,1);
        Results = [Results ; accuracy',3,g,r,-1,top2,top3]   
        model{trainId,2} = toc;       
        model{trainId,3} = [accuracy',3,g,r,-1,top2,top3];
        trainId = trainId +1;
    end
end





