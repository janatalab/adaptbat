function bat_stim = mkbat3(deviation, type, excerpts, params)
% make bat stimuli, version 3.0
%
%   originals used mean ITI of my tapping along with the excerpts
%   started at first tap after 5 seconds
%
%   now we'll construct using actual tap ITIs to define 'on the beat'
%
%   tempo cases are scaled. For faster tempo we need to figure out
%   a sensible way to add additional beeps at the end--do w/ mean ITI?
%
%   phase will be using relative phase of surrounding ITIs
%
% 30 Sept 2016

% deviation = [0 -10 10 -30 30];
% type = {'B' 'B' 'B' 'P' 'P'}; %beat and phase perturbations

% excerpts = {'ACL', 'HSG', 'HTH', 'KPS', 'NYN', 'OCJ', 'OWA', ...
%     'PAN', 'RRW', 'SAS', 'SMA', 'TJU'};

%%Set these according to where your files are
% indir = '/data0/stimuli/audio/bat/stimuli';
% outdir = indir;

toneFreq = 1000;
toneDur = .100;
riseFall = 0.005;

% transform TYPE and EXCERPTS parameters to cells if not already
if ~iscell(type)
    type = {type};
end

if ~iscell(excerpts)
    excerpts = {excerpts};
end
n_excerpts = length(excerpts);

% iterate through excerpts
for iE = 1:n_excerpts
    
    timing = batBeatTimes(excerpts{iE},params.IBI_fpath);
    taps = timing.t;
    ITIm = timing.IBI;
    
    %start taps after 5000ms
    taps(taps<5000) = [];
    
    %create BAT stimuli
    stimlen = 17; %set this to the longest excerpt length
    
    % iterate through deviations
    for iS = 1:length(deviation)
        
        fprintf(2,'%s: %c%s\n',excerpts{iE}, type{iS}, num2str(deviation(iS)));
        
        %determine timing of beeps
        switch type{iS},
            case 'B', %tempo manipulation
                if deviation(iS) == 0 %on beat
                    beats = taps;                    
                else          
                    %scale tap times by deviation
                    tmp = taps - taps(1); %anchor on initial beat
                    tmp = tmp * (1+deviation(iS)/100);
                    beats = tmp + taps(1);
                    if deviation(iS) > 0, %slower, so truncate
                        beats(beats > stimlen*1000) = [];
                    else %faster, add extra beeps at mean ITI
                        extra = (beats(end)+ITIm):ITIm:stimlen*1000;
                        beats = [beats extra];
                    end                    
                end
                
            case 'P', %phase manipulation
                ITI = diff(taps); 
                if deviation(iS) > 0, %shift after the beat
                    shift = [[ITI(1:end) ITIm]*deviation(iS)/100];
                else %shift before the beat
                    shift = [ [ITIm ITI(1:end)]*deviation(iS)/100];
                end
                beats = taps + shift;
            otherwise
        end
        
        beats = beats/1000; %ms to s
        excerptFname = fullfile(params.stim_fpath,[excerpts{iE} '.WAV']);
        outfname = fullfile(params.stim_fpath,[excerpts{iE} '_' type{iS} ...
          num2str(deviation(iS)) '_v3.wav']);
  
        %superimpose beeps at times in beats vector
        bat_stim = mkbatstim_out(excerptFname, toneFreq, beats, outfname);
        
    end %loop over stimulus variants
end %loop over excerpt