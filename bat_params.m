function params = bat_params
% parameters for BAT task psychtoolbox.
% populates parameters for experiment filhandling and stimuli as well as
% for the ZEST algorithm that estimates subjects' thresholds.
%
% 4 Oct 2016 Brian Hurley

% file paths
params.stim_fpath = 'C:\Users\janatalab\Documents\BAT\stimuli'; % '/data0/stimuli/audio/bat/stimuli/';
params.data_fpath = 'C:\Users\janatalab\Documents\BAT\subject_data\attmap_altstim';% '/data1/attmap/attmap_altstim/subject_data/bat_data/';
params.IBI_fpath = 'C:\Users\janatalab\Documents\svn\private\matlab\projects\attmap\bat\ITI';
params.ibi_outdata_fname = 'bat_ibi_zest.csv';
params.phase_outdata_fname = 'bat_phase_zest.csv';

% stims
params.stim_names = {
    'ACL.wav', 'SAS.wav', 'OWA.wav', 'KPS.WAV', 'SMA.WAV', 'PAN.wav', ...
    'HSG.WAV', 'NYN.WAV', 'TJU.wav', 'RRW.WAV', 'HTH.wav', 'OCJ.WAV'
    };
params.freq = 48000;
params.nrchannels = 2;
params.repetitions = 1; % should be >1 if repeating stim during playback

%% zest params
% params for initial p.d.f.
params.zest.zestA = 1;
params.zest.zestB = 2.5;
params.zest.zestC = 2.5;
params.zest.zestmaxrange = log10(20); % log of highest threshold value possible; 
params.zest.zestminrange = log10(.01); % log of lowest threshold value possible; 
params.zest.zest_init_lvl = 10; % initial difference level

% Parameters for Response function (Weibull function) (P(yes) given stimulus)
params.zest.zestfa = 0.1; %gamma in the text, false alarm rate (guess rate for 2AFC)
params.zest.zestmiss = 0.02; %delta in the text, miss rate (1/2 inattention rate for 2AFC)
params.zest.zestbeta = 6; %beta in the text, slope of response function
params.zest.zesteta = 0; %eta in the text, "sweat factor" or response criterion parameter

% stopping criteria
params.zest.sd_stop = 1.1;
params.zest.max_trials = 20;

% variables that should be reverted back to non-log units
params.zest.zestconvert = {'delta_L', 'sd_pdf'};