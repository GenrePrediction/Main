function [ Acc ] = forwardSelectionBasic( X , y, TestRatio ,nTrain,command  )
%FORWARDSELECTÝON Summary of this function goes here
%   Detailed explanation goes here

nFeature = size(X,2);

oldF = 1:nFeature;
Acc = zeros(nFeature,2);

    clock
    maximum = 0;
    maxind = -1;
    for i = oldF
        result = train (X(:, i), y,TestRatio ,nTrain,{},command );
        Acc(i,:) = result(1:2);
    end
end

