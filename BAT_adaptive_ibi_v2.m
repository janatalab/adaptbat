function[] = BAT_adaptive_ibi_v2(subject, params)

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

Screen('Preference', 'VisualDebugLevel', 1);
Screen('Preference', 'SkipSyncTests', 1);
%HideCursor;
PsychDefaultSetup(2);

%Set screen number to my one screen (this can detect multiple displays if
%needed)
screenNum = max(Screen('Screens'));

%Define colors
white = WhiteIndex(screenNum);
grey = white / 2;
black = BlackIndex(screenNum);

% Keyboard Information
escapeKey = KbName('ESCAPE');
NO = KbName('q'); % No (off beat) is q during experiment, and 0 in output file
YES = KbName('p'); % Yes (on beat) is p during experiment, and 1 in output file
% downKey = KbName('DownArrow');

%instruction_screen____________________________
%Black screen appears first
[window, rect] = PsychImaging('OpenWindow', screenNum, black);
Screen('Flip',window);

%Query frame duration
ifi = Screen('GetFlipInterval',window);

%Query maximum priority level
topPriorityLevel = MaxPriority(window);

%Get the center coordinate of the window
[X,Y] = RectCenter(rect);

%Set text properties
Screen('TextSize',window, 30);
Screen('TextFont',window,'Ariel');
Screen('TextStyle', window, 1);
textString = ['Welcome to the experiment. \n\n\n\n\n Please listen to each ' ...
    'musical excerpt and judge whether the click track is on-beat or off-' ...
    'beat. \n\n\n Respond at the end of each musical excerpt by pressing ' ...
    'Q if the tone is off-beat or P if the tone is on-beat. \n\n\n This ' ...
    'should take about 7 minutes.'];
DrawFormattedText(window, textString, 'center', 'center', white, 60);

Screen('TextSize',window, 15);
textString = '< Press any key to continue >';
DrawFormattedText(window, textString, 'center', 1000, white);

Screen('Flip', window);
KbStrokeWait;
tic

Screen('TextSize',window, 30);
textString = 'Press Q for off-beat, P for on-beat';
DrawFormattedText(window, textString, 'center', 'center', white)
Screen('Flip', window);
WaitSecs(2)

% Initialize Sounddriver
InitializePsychSound(1);

% Number of channels and Frequency of the sound
nrchannels = 2;
freq = 48000;

% How many times we wish to play the sound
repetitions = 1;

% Start immediately (0 = immediately)
startCue = 0;

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);

% Set the volume to half for this demo
PsychPortAudio('Volume', pahandle, 0.5);


%% TASK SPECIFIC CODE

% setting max # trials to 24
max_trials = 30;
% keep track of excerpt order
% trial_order = cell(max_trials,1);

% initialize data table for output
out_data_vars = {'response', 'aug_cond', 'aug_trial', 'score', ...
    'current_thresh', 'converged', 'excerpt'};
resp_tbl = cell2table(cell(max_trials,length(out_data_vars)), ...
    'VariableNames', out_data_vars);

for trial_number = 1:max_trials
    
    switch trial_number
        
        case 1 % for first trial
            
            % select random song index
            k = randperm(12,1);
            
            %Get stimulus and make sure it isn't a repeat
            stim = params.stim_names{k};
            song = stim(1:3);
            resp_tbl.excerpt{trial_number} = song;
            
            %Start with an on beat stimulus            
            aug_cond = 'onbeat';
            aug_trial = 0;
            
            stim_wvf = mkbat3(aug_trial, 'B', song, params.stim_dir, params.stim_dir);
            stim_wvf = stim_wvf';
            
            % Wait 0.5 s before starting
            WaitSecs(0.5);
            
            % Fill the audio playback buffer with the audio data
            PsychPortAudio('FillBuffer', pahandle, [stim_wvf; stim_wvf]);
            
            % Start audio playback
            PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
            
            % Collect keyboard response: on beat/YES = p, off beat/NO = q
            % and log score
            respToBeMade = true;
            while respToBeMade == true
                [~,~, keyCode] = KbCheck;
                if keyCode(YES)
                    response = 'yes';
                    score = 'correct';
                    respToBeMade = false;
                elseif keyCode(NO)
                    response = 'no';
                    score = 'incorrect';
                    respToBeMade = false;
                elseif keyCode(escapeKey)
                    sca;
                end
            end
            
            resp_tbl.response{trial_number} = response;
            resp_tbl.aug_cond{trial_number} = aug_cond;
            resp_tbl.aug_trial{trial_number} = aug_trial;
            resp_tbl.score{trial_number} = score;
            
        case 2 % for trial 2
            
            % randomly select a song index
            k = randperm(12,1);
            song = params.stim_names{k}(1:3);
            
            % Get stimulus and make sure it isn't a repeat.
            % If current selection matches previous trial, keep re-selecting
            % until we have a new song. Insures we never have back-to-back repeats.
            while strcmp(resp_tbl.excerpt{trial_number-1}, song)
                k = randperm(12,1);
                song = params.stim_names{k}(1:3);
            end
            resp_tbl.excerpt{trial_number} = song;
                        
            % use RAND to implement 0.80 probability of getting an off-beat trial.
            % This will randomize placement of catch trials
            x = rand;
            if x < 0.80
                aug_cond = 'offbeat';
            else
                aug_cond = 'onbeat';
            end
            
            % for on-beat trials, generate stim w/ on-beat metronome
            if strcmp(aug_cond,'onbeat')
                aug_cond = 'onbeat';
                aug_trial = 0;                
                stim_wvf = mkbat3(deviation, 'B', song, params.stim_dir, outdir);
                stim_wvf = stim_wvf';
            else
                % FIX: INSERT ZEST ALGORITHM HERE
                
                % generate stimulus
                stim_wvf = mkbat3(deviation, 'B', song, params.stim_dir, outdir);
                stim_wvf = stim_wvf';
                %       nrchannels = size(wavdata,1); % Number of rows == number of channels.
            end
            % Wait 0.5 s before starting
            WaitSecs(0.5);
            
            % Fill the audio playback buffer with the audio data
            PsychPortAudio('FillBuffer', pahandle, [stim_wvf; stim_wvf]);
            
            % Start audio playback
            PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
            
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
            
            resp_tbl.response{trial_number} = response;
            resp_tbl.aug_cond{trial_number} = aug_cond;
            resp_tbl.aug_trial{trial_number} = aug_trial;
            resp_tbl.score{trial_number} = score;
            
        otherwise % for trials 3-end
                        
            % Get stimulus and make sure it isn't a repeat.
            % If current selection matches previous trial, keep re-selecting
            % until we have a new song. Insures we never have back-to-back repeats.
            while strcmp(resp_tbl.excerpt{trial_number-1}, song)
                k = randperm(12,1);
                song = params.stim_names{k}(1:3);
            end
            resp_tbl.excerpt{trial_number} = song;
            
            % FIXME: INSERT ZEST HERE
            
            % generate stimulus
            stim_wvf = mkbat3(deviation, 'B', song, params.stim_dir, params.stim_dir);
            stim_wvf = stim_wvf';
            
            if aug_col == 1
                aug_cond = 1;
            else
                aug_cond = 0;
            end
            
            % Wait 0.5 s before starting
            WaitSecs(0.5);
            
            % Fill the audio playback buffer with the audio data
            PsychPortAudio('FillBuffer', pahandle, [stim_wvf; stim_wvf]);
            
            % Start audio playback
            PsychPortAudio('Start', pahandle, repetitions, startCue, waitForDeviceStart);
            
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
            
            resp_tbl.response{trial_number} = response;
            resp_tbl.response{trial_number} = aug_cond;
            resp_tbl.aug_trial{trial_number} = aug_trial;
            resp_tbl.score{trial_number} = score;
                        
    end % switch trial_number
    
end % for trial_number

sca

% write data to file
out_fname = fullfile(params.data_fpath, sprintf('%s_ibi_results.csv', subject));
csvwrite(out_fname,resp_tbl);

elapsedTime = toc;

fprintf(fid,'\n %f', elapsedTime);
close all
