function outData = BAT(subject_id)% wrapper function for the BAT test% calls functions for IBI and phase preturbation tasks in random order%% 14 Sept 2016 - BH% randomize task ordertask_order = randperm(2);for i_order = 1:length(task_order)        if task_order(i_order) == 1        BAT_adaptive_ibi(subject_id);            elseif task_order(i_order) == 2        BAT_adaptive_phase(subject_id);                end    end