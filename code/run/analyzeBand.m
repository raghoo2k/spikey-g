%% Analyze band
clear; close all;
loadAll('data/eeg_experiment/sorted_band/');

%% Create Dataset
dsetB= zeros(15*200,3);
dsetNB= dsetB;

% Load data
count= 0;
datanames= who('ptes*Bul');
dataN= length(datanames);
for i=1: dataN
  band= eval(datanames{i});
  band= band(:,7:9);  % Select only the data
  t= size(band,1);
  band= (band - repmat(mean(band,1), t,1)) ./ repmat(std(band,0,1), t,1); % normalize
  x1= reshape(band(:,1),6,[]);
  x2= reshape(band(:,2),6,[]);
  x3= reshape(band(:,3),6,[]);
  x= x1; x(:,:,2)= x2; x(:,:,3)= x3;
  %band= squeeze(mean(x,1));                     % average for each epoch
  %band= squeeze(x(6,:,:));                      % last for each epoch
  dsetB(count+1: count+size(band,1), :)= band;
  count= count+ size(band,1);
end
dsetB= dsetB(1:count, :);

count= 0;
datanames= who('ptes*Nobul');
dataN= length(datanames);
for i=1: dataN
  band= eval(datanames{i});
  band= band(:,7:9);  % Select only the data
  t= size(band,1);
  band= (band - repmat(mean(band,1), t,1)) ./ repmat(std(band,0,1), t,1); % normalize
  x1= reshape(band(:,1),6,[]);
  x2= reshape(band(:,2),6,[]);
  x3= reshape(band(:,3),6,[]);
  x= x1; x(:,:,2)= x2; x(:,:,3)= x3;
  %band= squeeze(mean(x,1));                       % average for each epoch
  %band= squeeze(x(6,:,:));                        % last for each epoch
  dsetNB(count+1: count+size(band,1), :)= band;
  count= count+ size(band,1);
end
dsetNB= dsetNB(1:count, :);
clear('ptes*');

dset= [dsetB;dsetNB];
class= cell(size(dset,1),1);
class(1 : size(dsetB,1))= {'bul'};
class(size(dsetB,1)+1 : end)= {'nobul'};

dataToKeep= ~sum(isnan(dset),2);
dset= dset(dataToKeep,:);
class= class(dataToKeep);

classCut= length(dsetB);

clear('dsetB','dsetNB','dataToKeep');
%% Show data histograms
% 1: bpm, 2: R, 3: T
%
figure;
scatterhist(dset(:,1),dset(:,2),'Group',class, 'Location','SouthEast',...
  'Direction','out','Color','br','Marker','ox','MarkerSize',5);
title('Heart rate with Resistance'); xlabel('hr'); ylabel('resist');
figure;
scatterhist(dset(:,2),dset(:,3),'Group',class, 'Location','SouthEast',...
  'Direction','out','Color','br','Marker','ox','MarkerSize',5);
title('Resistance with Temperature'); xlabel('resist'); ylabel('temp');
figure;
scatterhist(dset(:,3),dset(:,1),'Group',class, 'Location','SouthEast',...
  'Direction','out','Color','br','Marker','ox','MarkerSize',5);
title('Temperature with Heart Rate'); xlabel('temp'); ylabel('hr');

figure;
scatter3(dset(1:classCut,1),dset(1:classCut,2),dset(1:classCut,3),'xr'); hold on;
scatter3(dset(classCut+1:end,1),dset(classCut+1:end,2),dset(classCut+1:end,3),'ob'); hold off;
xlabel('hr'); ylabel('R'); zlabel('T');
%
%% Train SVM
svmModel= fitcsvm(dset, class, 'Standardize',true, ...
                  'KernelScale','auto','KernelFunc','rbf', 'BoxConstraint',1000);
cvSvmModel= 0;
for i=1:10
  rng(i);
  cvSvmModel= svmModel.crossval('kfold',4);
  hoSvmModel= svmModel.crossval('Holdout', 0.5);
  classError(i)= 100*cvSvmModel.kfoldLoss;
  hoError(i)= 100*hoSvmModel.kfoldLoss;
end
confusMat= confusionMatrix(cvSvmModel, class, true, 'SVM');

% Show classification error
fprintf(' - SVM cv error: %.1f%%\tstd: %.2f \n', mean(classError), std(classError));
fprintf(' - SVM ho error: %.1f%%\tstd: %.2f \n', mean(hoError), std(hoError));
fprintf(' - SVM percent support vectors in dataset: %.1f%% \n', sum(svmModel.IsSupportVector)/size(dset,1)*100);
fprintf('Confusion matrix:\n');
format bank;
disp(confusMat);
format short;


%% Naive Bayes model
%{
altModel= fitcnb(dset, class, 'DistributionNames','kernel');
for i= 1:5
  rng(i); cvAltModel= altModel.crossval('kfold',4);
  altClassError(i)= 100*cvAltModel.kfoldLoss;
end
% Show alt model error
altConfusMat= confusionMatrix(cvAltModel, class, true, 'Naive Bayes');
fprintf(' - Naive Bayes error: %.1f%%\tstd: %.2f \n', mean(altClassError), std(altClassError));
fprintf('Naive Bayes confusion matrix:\n');
format bank;
disp(altConfusMat);
format short;

% ROC curves
plotROC(svmModel, altModel, class, 'Naive Bayes');
%}
%% Decision Tree model
dtModel= fitctree(dset, class, 'MaxNumSplits', 50);
for i= 1:10
  rng(i);
  cvDtModel= dtModel.crossval('kfold',4);
  hoDtModel= dtModel.crossval('Holdout', 0.5);
  dtClassError(i)= 100*cvDtModel.kfoldLoss;
  hoDtError(i)= 100*hoDtModel.kfoldLoss;
end
% Show alt model error
dtConfusMat= confusionMatrix(cvDtModel, class, true, 'Decision Tree');
fprintf(' - Decision Tree cv error: %.1f%%\tstd: %.2f \n', mean(dtClassError), std(dtClassError));
fprintf(' - Decision Tree ho error: %.1f%%\tstd: %.2f \n', mean(hoDtError), std(hoDtError));
fprintf('Decision Tree confusion matrix:\n');
format bank;
disp(dtConfusMat);
format short;

% ROC curves
plotROC(svmModel, dtModel, class, 'Decision Tree');
