% finding plastic regions


ss22 = readtable("..\data\Sample 22.8_1_1.csv","NumHeaderLines",8,"VariableNamesLine", 7);
al23 = readtable("..\data\Sample 23.1_1_1.csv","NumHeaderLines",8,"VariableNamesLine", 7);
hs24 = readtable("..\data\Sample 24.1_1_1.csv","NumHeaderLines",8,"VariableNamesLine", 7);

% Extract force and displacement data
force_ss22 = ss22.Force;
displacement_ss22 = ss22.Displacement;

force_al23 = al23.Force;
displacement_al23 = al23.Displacement;

force_hs24 = hs24.Force;
displacement_hs24 = hs24.Displacement;

% Plot force-displacement curves
figure;
hold on;
plot(displacement_ss22, force_ss22, 'r', 'DisplayName', 'Sample 22.8');
plot(displacement_al23, force_al23, 'g', 'DisplayName', 'Sample 23.1');
plot(displacement_hs24, force_hs24, 'b', 'DisplayName', 'Sample 24.1');
xlabel('Displacement');
ylabel('Force');
title('Force-Displacement Curves');
legend show;
hold off;

% Determine the elastic region using linear regression
elastic_limit_ss22 = find_elastic_limit(displacement_ss22, force_ss22);
elastic_limit_al23 = find_elastic_limit(displacement_al23, force_al23);
elastic_limit_hs24 = find_elastic_limit(displacement_hs24, force_hs24);

% Display the elastic limits
disp(['Elastic limit for Sample 22.8: ', num2str(elastic_limit_ss22)]);
disp(['Elastic limit for Sample 23.1: ', num2str(elastic_limit_al23)]);
disp(['Elastic limit for Sample 24.1: ', num2str(elastic_limit_hs24)]);

% Find index locations matching elastic limits
idx_ss22 = find(displacement_ss22 >= elastic_limit_ss22, 1);
idx_al23 = find(displacement_al23 >= elastic_limit_al23, 1);
idx_hs24 = find(displacement_hs24 >= elastic_limit_hs24, 1);

% Plot elastic response regions
hold on;
plot(displacement_ss22(1:idx_ss22), polyval(polyfit(displacement_ss22(1:idx_ss22), force_ss22(1:idx_ss22), 1), displacement_ss22(1:idx_ss22)), 'r-x', 'DisplayName', 'Elastic Region 22.8');
plot(displacement_al23(1:idx_al23), polyval(polyfit(displacement_al23(1:idx_al23), force_al23(1:idx_al23), 1), displacement_al23(1:idx_al23)), 'g-x', 'DisplayName', 'Elastic Region 23.1');
plot(displacement_hs24(1:idx_hs24), polyval(polyfit(displacement_hs24(1:idx_hs24), force_hs24(1:idx_hs24), 1), displacement_hs24(1:idx_hs24)), 'b-x', 'DisplayName', 'Elastic Region 24.1');
legend show;
hold off;

function elastic_limit = find_elastic_limit(displacement, force)
    % Use first 20% of data for initial linear fit
    n_points = round(length(displacement) * 0.2);
    
    % Fit line to initial linear region
    p = polyfit(displacement(1:n_points), force(1:n_points), 1);
    slope = p(1);
    intercept = p(2);
    
    % Create 0.2% offset line
    offset = 0.002 * max(displacement);
    offset_line = @(x) slope*x + (intercept - slope*offset);
    
    % Remove duplicate x values for interpolation
    [unique_disp, ia, ~] = unique(displacement);
    unique_force = force(ia);
    
    % Find intersection with actual curve
    x_interp = linspace(min(unique_disp), max(unique_disp), 1000);
    y_interp = interp1(unique_disp, unique_force, x_interp, 'spline');
    
    % Find where offset line intersects actual curve
    diff = y_interp - offset_line(x_interp);
    cross_idx = find(diff > 0, 1, 'first');
    
    if isempty(cross_idx)
        elastic_limit = displacement(end);
    else
        elastic_limit = x_interp(cross_idx);
    end
end