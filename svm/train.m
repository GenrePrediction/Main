function [accuracy,stdev,time, model ] = train( X,y,TestRatio,nTrain,model,commands)
%TRAÝN Training giving dataset in svm with given parameters
%X : Input Set
%y : Output Set
%TestRatio : how many percent of dataset is going to use as test set
%nTrain : number of train to get average accuracy
%model : storing details
%commands : commands of libsvm as explained below:
% -s svm_type : set type of SVM (default 0)
% 	0 -- C-SVC
% 	1 -- nu-SVC
% 	2 -- one-class SVM
% 	3 -- epsilon-SVR
% 	4 -- nu-SVR
% -t kernel_type : set type of kernel function (default 2)
% 	0 -- linear: u'*v
% 	1 -- polynomial: (gamma*u'*v + coef0)^degree
% 	2 -- radial basis function: exp(-gamma*|u-v|^2)
% 	3 -- sigmoid: tanh(gamma*u'*v + coef0)
% 	4 -- precomputed kernel (kernel values in training_set_file)
% -d degree : set degree in kernel function (default 3)
% -g gamma : set gamma in kernel function (default 1/num_features)
% -r coef0 : set coef0 in kernel function (default 0)
% -c cost : set the parameter C of C-SVC, epsilon-SVR, and nu-SVR (default 1)
% -n nu : set the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
% -p epsilon : set the epsilon in loss function of epsilon-SVR (default 0.1)
% -m cachesize : set cache memory size in MB (default 100)
% -e epsilon : set tolerance of termination criterion (default 0.001)
% -h shrinking : whether to use the shrinking heuristics, 0 or 1 (default 1)
% -b probability_estimates : whether to train a SVC or SVR model for probability estimates, 0 or 1 (default 0)
% -wi weight : set the parameter C of class i to weight*C, for C-SVC (default 1)
% -v n: n-fold cross validation mode
% -q : quiet mode (no outputs)


tic;
nSongs = size(X,1);
trainId = size(model,1)+1;
sTrainId = trainId;
idx = randperm(nSongs);
sumTop1=0;
sumTop2=0;
sumTop3=0;

    for i=1:nTrain
    i    
    borderUp = floor(nSongs*TestRatio*(i-1)+1);
    borderDown = floor(nSongs*TestRatio*(i));

    % Pick %90(1-TestRatio) of data as Training Set
        XTrain = X(idx([1:(borderUp-1) (borderDown+1):end]),:);
        yTrain = y(idx([1:(borderUp-1) (borderDown+1):end]),:);
    %Pick %10(TestRatio) of data as Test Set
        XTest =  X(idx(borderUp:borderDown),:);
        yTest =  y(idx(borderUp:borderDown),:);

    %Training
        model{trainId,5} = svmtrain(yTrain, XTrain, commands);
        [~, accuracy,prob] =   svmpredict(yTest, XTest, model{trainId,5}, '-b 1');
    %top 2 and 3 accuracy
        lookuptable=model{trainId,5}.Label;
        [~,probi]=sort(prob,2,'descend');
        top2 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest)/size(probi,1);
        top3 = sum(lookuptable(probi(:,1))==yTest |lookuptable(probi(:,2))==yTest|lookuptable(probi(:,3))==yTest)/size(probi,1);
    %Results
        model{trainId,1} = accuracy(1);
        model{trainId,2} = top2*100;
        model{trainId,3} = top3*100;
        model{trainId,4} = commands;
        
        sumTop1 = sumTop1 + accuracy(1);
        sumTop2 = sumTop2 + top2;
        sumTop3 = sumTop3 + top3;
        trainId = trainId +1;
    end
    
    accuracy = mean(cell2mat(model(sTrainId:trainId-1,1:3)),1);
    stdev = std(cell2mat(model(sTrainId:trainId-1,1:3)),0,1);
    time = toc;
end

