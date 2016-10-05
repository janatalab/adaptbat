function BAT(subject_id)% wrapper function for the BAT test% calls function adaptive_bat, which implements IBI and/or phase% preturbation tasks and estimates subject threshold on each test%% 14 Sept 2016 - BH% set paramsparams = bat_params;%% Graphics and audio initializationScreen('Preference', 'VisualDebugLevel', 1);Screen('Preference', 'SkipSyncTests', 1);%HideCursor;PsychDefaultSetup(2)%Set screen number to my one screen (this can detect multiple displays if%needed)screenNum = max(Screen('Screens'));%Define colorswhite = WhiteIndex(screenNum);black = BlackIndex(screenNum);%% Instruction Screen%Black screen appears first[window, ~] = PsychImaging('OpenWindow', screenNum, black);Screen('Flip',window);% Deliver instruction textScreen('TextSize',window, 30);Screen('TextFont',window,'Ariel');Screen('TextStyle', window, 1);textString = ['Please listen to each musical excerpt and judge whether ' ...  'the click track is on-beat or off-beat. \n\n\n Respond at the end of ' ...   'each musical excerpt by pressing Q if the tone is off-beat or P if ' ...   'the tone is on-beat.'];DrawFormattedText(window, textString, 'center', 'center', white, 60);Screen('TextSize',window, 15);textString = '< Press any key to continue >';DrawFormattedText(window, textString, 'center', 1000, white);Screen('Flip', window);KbStrokeWait;% start timer to measure task lengthtic% subject will see abbreviated on-screen instructions throughout taskScreen('TextSize',window, 30);textString = 'Press Q for off-beat, P for on-beat';DrawFormattedText(window, textString, 'center', 'center', white);Screen('Flip', window);WaitSecs(2)%% Task% randomize task ordertask_order = randperm(2);for i_order = 1:length(task_order)    if i_order == length(task_order)    textString = ['You will now perform a similar task on the same music. Again, '...      'please listen to each musical excerpt and judge whether ' ...      'the click track is on-beat or off-beat. \n\n\n Respond at the end of ' ...      'each musical excerpt by pressing Q if the tone is off-beat or P if ' ...      'the tone is on-beat.'];    DrawFormattedText(window, textString, 'center', 'center', white, 60);        Screen('TextSize',window, 15);    textString = '< Press any key to continue >';    DrawFormattedText(window, textString, 'center', 1000, white);        Screen('Flip', window);    KbStrokeWait;    tic  end    if task_order(i_order) == 1    % implement ibi (tempo) test    BAT_adaptive_ibi_v2(subject_id, 'B', params);  elseif task_order(i_order) == 2    % implement phase test    BAT_adaptive_ibi_v2(subject_id, 'P', params);  end  end% show elapsed time (s)time_elapsed = toc;disp(time_elapsed);% close subject interface screenscaend