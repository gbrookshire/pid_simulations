% Simulate data for PID analysis
% To make sure everything is working correctly

% can the prediction of S be improved by simultaneous observation of X and
% Y (synergistic representation), or is one alone sufficient to extract
% all the knowledge about S which they convey together (redundant 
% representation)

% Set the random seed
rng(1);

% Set up a fieldtrip data struct
data = [];
data.fsample = 250;
data.label = {};
t = 0:(1/data.fsample):10000;
data.time = {t};
data.trial = {};

% Make signals that influence the MEEG data
noise = @(amp) amp * detrend(rand(size(t)));
s_shared = noise(0); % Set the amount of redundant information
s_a = s_shared + noise(1);
s_b = s_shared + noise(1);

% Make the dependent variables, influenced by the two signals
% Different channels are composed of different combinations of the signals
n_chans = 6;
for i_chan = 1:n_chans
    switch i_chan
        case 1 % Only depends on signal A
            x = s_a;
            label = 'A';
        case 2 % Only depends on signal B
            x = s_b;
            label = 'B';
        case 3 % Depends on the two signals added together
            x = s_a + s_b;
            label = 'A+B';
        case 4 % Noise (no relation to either signal)
            x = noise(1);
            label = 'Noise';
        case 5 % Non-monotonic dependence on one variable
            x = (s_a) .^ 2;
            label = 'A^2';
        case 6 % XOR is the typical example of synergistic info
            x = xor(s_a > 0, s_b > 0);
            label = 'XOR';
        otherwise
            error('No details specified for channel %i', i_chan)
    end
    x = x + noise(1);
    data.trial{1}(i_chan, :) = x;
    data.label{end+1} = label;
end

% Include the IVs in the data
data.trial{1}(end + 1, :) = s_b;
data.label{end + 1} = 's_b';
data.trial{1}(end + 1, :) = s_a;
data.label{end + 1} = 's_a';

clear t n_chans sawtooth s_saw s_noise x i_chan label