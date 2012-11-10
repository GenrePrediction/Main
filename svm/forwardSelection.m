function [ newF,newAcc ] = forwardSelection( X , y,maxNFeature, TestRatio ,nTrain,command  )
%FORWARDSELECTÝON Summary of this function goes here
%   Detailed explanation goes here

nFeature = size(X,2);

oldF = 1:nFeature;
newF = [];
newAcc = [];

for j = 1:maxNFeature
    j
    clock
    maximum = 0;
    maxind = -1;
    for i = oldF
        acc = train (X(:,[newF i]), y,TestRatio ,nTrain,{},command );
        if(acc(1) > maximum)
            maximum=acc(1);
            maxind=i;
        end
    end
    oldF(find(oldF==maxind)) = [];
    newF(end+1) = maxind;
    newAcc(end+1) = maximum;
    maxind
    maximum
    
end


end

