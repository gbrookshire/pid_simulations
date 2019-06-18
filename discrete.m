function discrete_x = discrete(x, n_bins)
% Group a continuous variable x into n equally-populated bins.
% Only works for a vector

if ~isvector(x)
    error('Only works for vectors')
end

q = [min(x) quantile(x, n_bins-1) (max(x) + 1)];
[~, discrete_x] = histc(x, q);

% Preserve NaNs in the input vector
discrete_x(isnan(x)) = nan; 