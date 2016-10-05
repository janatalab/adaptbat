function BAT_adaptive_ibi_v2(subject, type, params)

% Adaptive inter-beat interval version of the Beat Alignment Test, version
% 2. See the following paper for more info on the BAT test:
% Iversen, JR, Patel, AD. The Beat Alignment Test (BAT): Surveying beat processing
% abilities in the general population. Proceedings of the 10th International Conference
% on Music Perception and Cognition 2008: 465-468.
%
% Discriminate between correct ibi and augmented ibi. The 12 stimuli from
% the BAT are used. Trial 1 and 2 have correct ibi's. Trial 3 has an ibi that
% has been augmented by 10%. For each trial after trial 3, an incorrect
% response will result in the next trial being easier (using a bigger ibi).
% 2 correct responses in a row will result in the next trial being harder
% (using a smaller ibi). A correct response followed by an incorrect
% response will result in the next trial using the same ibi as the previous
% trial, but with a new musical stimulus. Lengthened and shortened ibi's
% are alternated.
%
% INPUT:
%     subject: subject ID string (e.g., 'JR1')
%     type: deviant type string. 'B' for ibi test; 'P' for phase test
%     params:
%       - stim_fpath
%       - stim_names
%       - data_fpath
%
%
% Written by Brian Hurley, Sept 2016.
%
% PsychToolbox portion of the code adapted from BAT_adaptive_ibi.m &
% BAT_adaptive_phase.m written by Jessica Ross, March 2016.

%% PSYCHTOOLBOX CODE

% Make sure we start with PsychPortAudio closed so that soundcard is not
% blocked
PsychPortAudio('Close');

% Initialize Sounddriver
InitializePsychSound(1);

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
pahandle = PsychPortAudio('Open', [], 1, 1, params.freq, params.nrchannels);

% Keyboard Information
escapeKey = KbName('ESCAPE');
NO = KbName('q'); % Q key = NO
YES = KbName('p'); % P key = YES

% Start immediately (0 = immediately)
startCue = 0;

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

%% TASK/TRIAL HANDLING
clear mean_pdf sd_pdf

max_offbeat_trials = params.zest.max_trials; % doesn't include onbeat catch trials
offbeat_trial_counter = 0;

% initialize data table for output
out_data_vars = {'response', 'aug_cond', 'deviation', 'score', ...
    'thresh', 'sd_pdf', 'converged', 'excerpt'};
resp_tbl = cell2table(cell(max_offbeat_trials,length(out_data_vars)), ...
    'VariableNames', out_data_vars);

% INITIALIZE ZEST HERE
% if (second) params input given, zest ignores (first) response input
% position and intializes zest...hence NaN
mean_pdf = zest(NaN, params.zest);

for trial_number = 1:max_offbeat_trials
    
    % select random song index
    k = randperm(12,1);
    
    % first trial starts with on-beat stim, subsequent trials, probability
    % of off-beat stim is 0.80
    switch trial_number
        case 1 % for first trial
            song = params.stim_names{k}(1:3);
            aug_cond = 'onbeat';            
        otherwise % all subsequent trials
            % Get stimulus and make sure it isn't a repeat.
            % If current selection matches previous trial, re-select
            % until we have a new song. Insures we never have back-to-back repeats.
            while strcmp(resp_tbl.excerpt{trial_number-1}, song)
                k = randperm(12,1);
                song = params.stim_names{k}(1:3);
            end
            
            % use RAND to implement 0.80 probability of getting an off-beat trial.
            % This will randomize placement of catch trials
            x = rand;
            if x < 0.80
                aug_cond = 'offbeat';
                % add this trial to offbeat trial counter
                offbeat_trial_counter = offbeat_trial_counter + 1;
            else
                aug_cond = 'onbeat';
            end
            
    end % switch trial_number
    
    % for on-beat trials, generate stim w/ on-beat metronome
    if strcmp(aug_cond,'onbeat')
        deviation = 0;
        stim_wvf = mkbat3(deviation, type, song, params);
        stim_wvf = stim_wvf';
        
        % not tracking thresh metrics on catch trials
        resp_tbl.thresh{trial_number} = NaN;
        resp_tbl.sd_pdf{trial_number} = NaN;
        resp_tbl.converged{trial_number} = NaN;
        
    else % else, generate stim w/ deviation specified by threshold algorithm        
        
        % randomize whether deviation is positive (faster) or
        % negative (slower)
        dev_sign = randperm(2,1);
        switch dev_sign
            case 1
                deviation = mean_pdf;
            case 2
                deviation = -mean_pdf;
        end
        
        % generate stimulus
        stim_wvf = mkbat3(deviation, type, song, params);
        stim_wvf = stim_wvf';
        
    end
    
    %% PLAY AUDIO AND GET RESPONSE
    
    % Wait 0.5 s before starting
    WaitSecs(0.5);
    
    % Fill the audio playback buffer with the audio data
    PsychPortAudio('FillBuffer', pahandle, [stim_wvf; stim_wvf]);
    
    % Start audio playback
    PsychPortAudio('Start', pahandle, params.repetitions, startCue, waitForDeviceStart);
    
    % Collect keyboard response: on beat/YES = p, off beat/NO = q
    respToBeMade = true;
    while respToBeMade == true
        [~,~, keyCode] = KbCheck;
        if keyCode(YES)
            response = 'yes';
            if strcmp(aug_cond, 'onbeat')
                score = 'correct';
            else
                score = 'incorrect';
            end
            respToBeMade = false;
        elseif keyCode(NO)
            response = 'no';
            if strcmp(aug_cond, 'offbeat')
                score = 'correct';
            else
                score = 'incorrect';
            end
            respToBeMade = false;
        elseif keyCode(escapeKey)
            sca;
        end
    end        
    
    % populate this trial in response table
    resp_tbl.response{trial_number} = response;
    resp_tbl.aug_cond{trial_number} = aug_cond;
    resp_tbl.deviation{trial_number} = deviation;
    resp_tbl.score{trial_number} = score;
    resp_tbl.excerpt{trial_number} = song;
    
    % if it's an off-beat trial, estimate threshold
    % for the ZEST function, 1 is correct response, 0 is incorrect response
    if strcmp(aug_cond, 'offbeat')
        if strcmp(response, 'no')
            zest_resp = 1;
        elseif strcmp(response, 'yes')
            zest_resp = 0;
        end
        
        % estmate thresh
        [mean_pdf, sd_pdf] = zest(zest_resp);        
        
        resp_tbl.thresh{trial_number} = mean_pdf;
        resp_tbl.sd_pdf{trial_number} = sd_pdf;
        
        % check for convergence. 
        % if converged, stop the trial_number loop (i.e. stop delivering stims)
        if sd_pdf <= params.zest.sd_stop || offbeat_trial_counter == max_offbeat_trials
            resp_tbl.converged{trial_number} = 1;
            break
        else
            resp_tbl.converged{trial_number} = 0;
        end        
    end    
    
end % for trial_number

%% OUTPUT RESULTS TO FILE

% write data to file
out_fname = fullfile(params.data_fpath, sprintf(['%s_' params.ibi_outdata_fname], subject));
writetable(resp_tbl, out_fname);

%%
% close PsychPortAudio
PsychportAudio('Close', pahandle);

end
