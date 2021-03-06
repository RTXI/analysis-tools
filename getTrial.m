function [trial] = getTrial(fname,trialNum)
%% [trial] = getTrial(fname,trialNum)
% 
% This function returns all the channel data, metadata, and parameters used 
% in the specified trial of a RTXI HDF5 file. Supports unmatlabized files.
%
%      trial_number: 3
%        parameters: [1x1 struct]
%     numParameters: 15
%          datetime: '2009-10-21T23:02:28'
%            exp_dt: 1.0000e-04
%           data_dt: 1.0000e-04
%         timestart: '10:01:29.6065'
%          timestop: '10:01:50.629'
%            length: 21.0225
%       numChannels: 3
%          channels: {1x3 cell}
%              data: [78813x3 double]
%              time: [78813x1 double]
%              file: 'dclamp.h5'
%
% AUTHOR: Risa Lin
%         Francis Ortega (12/13/2012)
% DATE:  10/31/2010

% MODIFIED:
% 9/27/2011 - use lower level functions to read the synchronous data, users
% no longer have to matlabize their files
%
% 11/11/2010 - corrected extraction of synchronous channel names when >=10
% channels are saved
%
% 12/13/2012 - corrected extraction of data when trials >= 10 by replacing
%              low level functions with high level functions using explicit
%              path as argument
%            - replaced depracted hdf5read function with h5read
%            - removed "Old Data Recorder" code
%            - added more comments and removed eval statements for
%              readability
%            - added Trial number
%            - rearranged order of variables, so file name and trial are at
%              top

%% Setup
% If trial is not specified, default to trial 1
if nargin < 2
    trialNum = 1;
end

% Load file and check if trial requested is valid
fileinfo = rtxi_read(fname);
if trialNum>fileinfo.numTrials
    error('There are only %i trials in this file.\n',fileinfo.numTrials)
end

% Trial path
path = strcat( '/Trial', num2str(trialNum) );

%% Metadata
% File
trial.file = fname;
% Trial Number
trial.trial_number = trialNum;
% Parameters 
[trial.parameters, trial.numParameters] = getParameters(fname,trialNum);
% Date
trial.datetime = h5read( fname, [path '/Date'] );
% Downsampling Rate
ds = double( h5read( fname, [path '/Downsampling Rate'] ) );
% RTXI Thread Period
trial.exp_dt = double( h5read( fname, [path '/Period (ns)'] ) ) * 1e-9;
% Period of Data Sampling
trial.data_dt = trial.exp_dt * ds;
% Time start
trial.timestart = double( h5read( fname, [path '/Timestamp Start (ns)'] ) ) * 1e-9;
trial.timestart = convertTime(trial.timestart);
% Time stop
try % try to get end timestamp (it will be missing if RTXI crashed while recording)
    trial.timestop = double( h5read( fname, [path '/Timestamp Stop (ns)'] ) ) * 1e-9;
    trial.timestop = convertTime(trial.timestop);
catch
    warning('Timestamp Stop (ns) is mising.');
	 trial.timestop = convertTime(0);
end
%% Channel Data
try
    trial.data = h5read( fname, [path '/Synchronous Data/Channel Data'] )';
catch HELLO
	 % Old RTXI versions spelled "Synchronous" as "Syncronous"
    msg = ['/Synchronous Data/Channel Data is missing. Trying /Syncronous Data instead']; 
    % Add something to check the error type... -Ansel
    trial.data = h5read( fname, [path '/Syncronous Data/Channel Data'] )';
end

% Number of Channels
trial.numChannels = size( trial.data, 2 );
%trial.numChannels = size(fileinfo.GroupHierarchy.Groups(trialNum).Groups(3).Datasets, 2) - 1;
trial.numChannels

% Names of Channels
for i=1:trial.numChannels
    %trial.channels{i} = h5read( fname, [path '/Synchronous Data/Channel ' num2str(i) ' Name'] );
    trial.channels{i} = h5read( fname, fileinfo.GroupHierarchy.Groups(trialNum).Groups(3).Datasets(i).Name );
end
trial.channels

%trial.data = h5read( fname, fileinfo.GroupHierarchy.Groups(trialNum).Groups(3).Datasets(trial.numChannels+1).Name );
%fileinfo.GroupHierarchy.Groups(trialNum).Groups(3).Datasets(trial.numChannels+1).Name

% Number of Samples
numsamples = size( trial.data, 1 );
trial.time = 0:trial.data_dt:numsamples*trial.data_dt-trial.data_dt;
trial.time = trial.time';
trial.length = trial.time(end);
end

%% convertTime Function
function strtime = convertTime(time)
hour = time/3600;
minute = rem(hour,1)*60;
second = rem(minute,1)*60;
hour = floor(hour);
minute = floor(minute);

if hour < 10; strtime = ['0',num2str(hour)]; else; strtime = num2str(hour);end
if minute < 10; strtime = [strtime,':0',num2str(minute)]; else; strtime = [strtime,':',num2str(minute)];end
if second < 10; strtime = [strtime,':0',num2str(second)]; else; strtime = [strtime,':',num2str(second)];end
end


