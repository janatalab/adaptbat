function outData = adaptive_bat_plots(inData,params)
% This is the entry point for any plots of response data from the attmap_intensitydec experiment
%
% 4 Dec 2015    BH

bat_trial_data = inData.data{strcmp(inData.vars,'adaptBAT_trial_data')};
bat_thresh_data = inData.data{strcmp(inData.vars,'adaptBAT_thresh_data')};

% add column of threshold absolute value to data table
bat_thresh_data.abs_thresh = abs(bat_thresh_data.thresh);
bat_trial_data.abs_thresh = abs(bat_trial_data.thresh);

subids = unique(bat_thresh_data.subject_id);
nsubs = length(subids);
test_types = unique(bat_thresh_data.test); % all stims have 4 probe times

nfig = 0;

%% PLOT THRESHOLD TRAJECTORIES

if params.plot.subj_traj    

    % initialize data fields for plotting tempo data
    batTraj_data.tempo.subject_id = cell(nsubs,1);
    batTraj_data.tempo.deviation = cell(nsubs,1);
    batTraj_data.tempo.test_trials = cell(nsubs,1);
    batTraj_data.tempo.correct_trials = cell(nsubs,1);
    batTraj_data.tempo.final_thresh = nan(nsubs,1);
    
    % populate phase plotting data with same fields
    batTraj_data.phase = batTraj_data.tempo;

    for isub = 1:nsubs
        curr_sub = subids{isub};        
        sub_msk = ismember(bat_trial_data.subject_id,curr_sub);
        sub_data = bat_trial_data(sub_msk,:);
        curr_test_types = unique(sub_data.test);
        n_tests = length(curr_test_types);        

        for itest = 1:n_tests
            % get response data
            curr_test = curr_test_types{itest};
            test_msk = ismember(sub_data.test,curr_test);
            sub_test_data = sub_data(test_msk,:);
            n_trials = length(sub_test_data.response);
            
            % create mask for test trials
            test_trial_msk = ismember(sub_test_data.aug_cond,'offbeat');                        
            % create mask for correct responses
            correct_resp_msk = ismember(sub_test_data.score,'correct');  
            % get converged threshold
            converged_msk = sub_test_data.converged == 1;
            final_thresh = sub_test_data.thresh(converged_msk);
            
            % populate plotting data struct
            batTraj_data.(curr_test).subject_id{isub} = curr_sub;
            batTraj_data.(curr_test).deviation{isub} = sub_test_data.deviation;
            batTraj_data.(curr_test).correct_trials{isub} = correct_resp_msk;
            batTraj_data.(curr_test).test_trials{isub} = test_trial_msk;
            batTraj_data.(curr_test).final_thresh(isub) = final_thresh;
            
        end % for itest
                
    end % for isub
    
    
    % cycle through test types and plot subject trajectories     
    
    for i_test = 1:n_tests
        this_test = test_types{i_test};
        % plot each subject's data for this test
        
        for i_sub = 1:nsubs
            curr_data = batTraj_data.(this_test).deviation{i_sub}';            
            
            % if we have no data on this subject for the current test, skip
            % to next subject
            if isempty(curr_data)
                continue
            else
                % get this subject's data
                curr_correct_msk = batTraj_data.(this_test).correct_trials{i_sub}';
                curr_test_msk = batTraj_data.(this_test).test_trials{i_sub}';
                curr_thresh = batTraj_data.(this_test).final_thresh(i_sub);                
                curr_sub = batTraj_data.(this_test).subject_id{i_sub};                                
                ntrials = length(curr_data);
                trial_vect = 1:ntrials;
                
                % plot absolute value if desired                             
                if params.plot_abs_val
                    curr_data = abs(curr_data);
                    curr_thresh = abs(curr_thresh);                    
                    out_fname = sprintf('batTraj_%s_%s_absval.eps',curr_sub,this_test);
                    y_lab = sprintf('Percent %s change (absolute value)',this_test);
                else                    
                    out_fname = sprintf('batTraj_%s_%s.eps',curr_sub,this_test);
                    y_lab = sprintf('Percent %s change',this_test);
                end
                
                nfig = nfig+1;
                figure(nfig),clf
                hold on
                
                % plot threshold trajectory for test trials
                h1 = plot(trial_vect(curr_test_msk), curr_data(curr_test_msk), '-b', 'linewidth', 1.75);
                % filled marker for correct-response trials
                h2 = plot(trial_vect(curr_correct_msk & curr_test_msk), curr_data(curr_correct_msk & curr_test_msk), ...
                    'bo','markerfacecolor', 'b', 'markersize', 7);
                % open marker for incorrect responses
                h3 = plot(trial_vect(~curr_correct_msk & curr_test_msk), curr_data(~curr_correct_msk & curr_test_msk), ...
                    'bo','markerfacecolor', 'w', 'markersize', 7);
                % plot final threshold as triangle
                h4 = plot(trial_vect(end)+1, curr_thresh, 'b^','markerfacecolor', 'b', ...
                    'markersize', 7);
                
                % plot catch trials
                h5 = plot(trial_vect(curr_correct_msk & ~curr_test_msk), curr_data(curr_correct_msk & ~curr_test_msk), ...
                    'bs','markerfacecolor', 'b', 'markersize', 7);
                h6 = plot(trial_vect(~curr_correct_msk & ~curr_test_msk), curr_data(~curr_correct_msk & ~curr_test_msk), ...
                    'bs','markerfacecolor', 'w', 'markersize', 7);
                
                
                if strcmp(this_test, 'tempo')
                    if params.plot_abs_val
                        set(gca,'ylim',[0 25])
                    else
                        set(gca,'ylim',[-25 25])
                    end
                elseif strcmp(this_test, 'phase')
                    if params.plot_abs_val
                        set(gca,'ylim',[0 45])
                    else
                        set(gca,'ylim',[-45 45])
                    end
                end
                
                set(gca,'xlim', [1 (ntrials+2)])    
                set(gca,'Xtick',1:(ntrials))                
                xlabel('Trial','fontsize',14)
                ylabel(y_lab,'fontsize',14)
                
                empty_handle_msk = cellfun(@isempty,{h2 h3 h5 h6 h4});
                legend_handles = [h2 h3 h5 h6 h4];
                
                legend_lables = {'correct test trial', 'incorrect test trial', ...
                    'correct catch trial', 'incorrect catch trial', ...
                    'final threshold'};
                % remove label if a plot handle is empty
                legend_lables(empty_handle_msk) = [];
                
                legend((legend_handles), legend_lables, 'location', 'southoutside')
                title(sprintf('Adaptive BAT %s test\nSubject: %s', this_test, curr_sub), 'fontsize', 16)
                
                hold off
                
                % write to disk
                if params.plot_abs_val
                    out_fname = sprintf('batTraj_%s_%s_absval.eps',curr_sub,this_test);
                else
                    out_fname = sprintf('batTraj_%s_%s.eps',curr_sub,this_test);
                end
                print(fullfile(params.fig_path,out_fname),'-depsc')
                close all
                
            end % if isempty
                        
        end % for i_sub
        
    end % for i_test
    
end % if params.plot.subj_traj

if params.plot.mean_traj
    
    
end

outData = [];

end