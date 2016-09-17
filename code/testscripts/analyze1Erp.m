clear; close all;
load('data/erp_time_channels.mat');

%% Parameters
dir= 'data/PTES_2/matfilesT1/';
savefile= 'data/results/features/tmp/svmTrainingSet_tmp.mat';
tresultsfile= 'data/results/svm/tmp/trainResults_tmp.mat';

parameters.feature.preproc= struct( ...
  'channelICA',false, ...
  'channelICAfilt',false, ...
  'filtFrq',[84,92] ...
);
parameters.feature.wave= struct( ...
  'waveMaxFrq',60, ...
  'voicesPerOct',16, ...
  'waveSmoothStd',2, ...
  'prominenceThreshold',0.008 ...
);
parameters.class.predictor= struct( ...
  'predICA',false, ...
  'predRanking',false, ...
  'rankSelect',1:3, ...
  'selectedPredictors',[1 2 4 5] ...
);
parameters.class.func= struct( ...
  'svmPlotGraphs',false, ...
	'singlePredictorPerformance',false, ...
	'singlePredictorPerformThreshold',48 ...
);
parameters.class.gen= struct('verbose',false);

genderAnalysis= false;
extractFeatures= true;

%timeLimits= [30,150]; % start-end (milliseconds)
%channels= [108,115:117,124:126,137:139,149:151,159];
timeLimits= timeLims_N170;
channels= channels_N170;


% Show parameters
if parameters.class.gen.verbose
  fprintf('\tParameters:\n\n');
  disp(parameters.feature.preproc)
  disp(parameters.feature.wave)
  disp(parameters.class.predictor)
  disp(parameters.class.func)
end
%% Extract features
if extractFeatures
  fprintf('--> Extracting features...\n');
  saveFeatures(dir,savefile,timeLimits,channels, parameters.feature);
else
  fprintf('--> Feature extraction SKIPPED!\n');
end

%% Train SVMs
fprintf('\n--> Training SVMs\n');
if ~genderAnalysis
  fprintf('-> Training model: both genders\n');
  [model, err, conf]= trainSvm(savefile, parameters.class);
  save(tresultsfile, 'model','err','conf');
else
  [savefile_men, savefile_women]= splitMenWomen(savefile, 'data/menWomen.mat');
  tresultsfile_men=   [tresultsfile(1:end-4),'_men.mat'];
  tresultsfile_women=   [tresultsfile(1:end-4),'_women.mat'];
  % Train men's SVM
  fprintf('-> Training model: MEN\n');
  [model, err, conf]= trainSvm(savefile_men, parameters.class);
  save(tresultsfile_men, 'model','err','conf');
  % Train women's SVM
  fprintf('\n-> Training model: WOMEN\n');
  [model, err, conf]= trainSvm(savefile_women, parameters.class);
  save(tresultsfile_women, 'model','err','conf');
end
fprintf('\n');
