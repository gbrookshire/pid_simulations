% Testing out the PID (Partial Information Decomposition)

addpath('~/rds_share/gb/projects/pid_simulations')
addpath('~/Documents/MATLAB/partial-info-decomp-master')
addpath('~/Documents/MATLAB/gcmi-master/matlab')

clear variables

if ~exist('plots', 'dir')
    error('Create a directory called ''plots/'' to save the output.')
end

% Find the PID
pid_simulate % Creates the 'data' object

% Prep the data
eeg_raw = cat(2, data.trial{:}); % Append all EEG data into one long trial
eeg_raw = eeg_raw'; % Transpose so this works with copnorm

% Make the data for the two models
model1_raw = eeg_raw(:, end);
model2_raw = eeg_raw(:, end-1);

eeg_raw = eeg_raw(:, 1:(end-2));

for pid_type = {'gc' 'disc'}
    % Calculate PID
    switch pid_type{1}
        
        case 'gc' % Gaussian copula
            model1_cop = copnorm(model1_raw);
            model2_cop = copnorm(model2_raw);
            clear eeg_cop
            for i_chan = 1:size(eeg_raw, 2)
                eeg_cop(:, i_chan) = copnorm(eeg_raw(:, i_chan));
            end
            % Set up data structures for PID
            lat = lattice2d();
            Vs = [1 1 1]; % How many dimensions in each variable 
            % Calculate PID for each sensor
            for i_chan = 1:size(eeg_cop, 2)
                dat = [model1_cop model2_cop eeg_cop(:, i_chan)];
                Cfull = cov(dat);
                res = calc_pi_mvn(lat, Cfull, Vs, @Iccs_mvn_P2);

                info = res.PI;
                I(1, i_chan) = info(1); % Redundancy
                I(2, i_chan) = info(2); % Unique info in first signal
                I(3, i_chan) = info(3); % Unique info in second signal
                I(4, i_chan) = info(4); % Synergy
            end
            
        case 'disc' % Discrete Info
            % Make discrete (binned) versions of each variable
            nbins = 20;
            model1_disc = discretize(model1_raw, nbins);
            model2_disc = discretize(model2_raw, nbins);
            for i_chan = 1:size(eeg_raw, 2)
                eeg_disc(:, i_chan) = discretize(eeg_raw(:, i_chan), nbins);
            end

            % Calculate PID for each sensor
            for i_chan = 1:size(eeg_cop, 2)
                dat = [model1_disc model2_disc eeg_disc(:, i_chan)];

                % Joint distributions
                Cxxy = accumarray(dat, 1);
                Pxxy = Cxxy ./ size(eeg_disc, 1);

                % PID
                lat = lattice2d();
                res = calc_pi(lat, Pxxy, @Imin);
%                 res = calc_pi(lat, Pxxy, @Iccs); % Causes python to crash

                info = res.PI;
                I(1, i_chan) = info(1); % Redundancy
                I(2, i_chan) = info(2); % Unique information to first signal
                I(3, i_chan) = info(3); % Unique information to second signal
                I(4, i_chan) = info(4); % Synergy
            end
            
        otherwise
            error('pid_type must be ''gc'' or ''disc''')
    end
    % Make the plots
    % Plots
    chans = 1:size(eeg_cop, 2);
    info_types = {'Redundancy' 'Unique to A' 'Unique to B' 'Synergy'};
    info_labels = {'Red' 'U(A)' 'U(B)' 'Syn'};

    % Group into a different subplot for each type of Info
    figure(1)
    for info_type = 1:4
        subplot(2,2,info_type)
        x = I(info_type,:);
        bar(x)
        xlim([0.5 6.5])
        ylim([min([0 x]), max(x) * 1.1]);
        xticks(chans)
        xticklabels(data.label)
        title(info_types{info_type})
    end
    print('-dpng', ['plots/' pid_type{1} '-by-infotype'])

    % Group into a different subplot for each channel
    figure(2)
    for i_chan = chans
        subplot(3,2,i_chan)
        x = I(:,i_chan);
        bar(x)
        xlim([0.5 4.5])
        ylim([min([0 x']), max(x) * 1.1]);
        xticks(chans)
        xticklabels(info_labels)
        title(data.label{i_chan})
    end
    print('-dpng', ['plots/' pid_type{1} '-by-channel'])
  
end