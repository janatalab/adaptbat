function timing = batBeatTimes(excerpt)
%batBeatTimes  get beat times for BAT stimuli
%
%   timing = batBeatTimes(excerpt)
%
%     excerpt is name of song, or iso350, iso600, iso850
%
%   timing.IBI = mean IBI, ms
%   timing.t   = beat times (as tapped by JRI, mean of multiple runs), ms
%   timing.tISO = isochronized beat times (used in BAT stimuli), ms
%   
%
% JRI 5/12/08

global G

if strncmp(excerpt,'iso',3),
  ioi = str2num(excerpt(4:end));
  require(any(ioi==[350 600 850]),'bad ITI value')
  
  stimLength = 30*1000;
  times = 0:ioi:stimLength;
  
  timing.excerpt = excerpt;
  timing.IBI = ioi;
  timing.t = times;
  timing.tISO = times; %t is isochronous
  
else %songs
  
  %logdir = fullfile(G.paths.root, 'projects','bat','ITI');
  %fix this to point at the directory of ITI data -- this works only if calling
  %from directory where this mfile resides
  logdir = '/Users/bkhurley/svn/private/matlab/projects/attmap/bat/ITI';
  
  try,
  mfilename = fullfile(logdir, ['ji_' excerpt '2.txt']);
  times = load(mfilename);
  catch
    timing.excerpt = excerpt;
    timing.IBI = [];
    timing.t = [];
    timing.tISO = [];
    return
  end
  
  timing.excerpt = excerpt;
  timing.IBI = mean(diff(times));
  timing.t = times';
  
  %anchor at first tap after 5 second
  tBeepStart = 5000;
  
  times(times<tBeepStart) = [];
  
  timing.tISO = times(1):timing.IBI:times(end);
  
end