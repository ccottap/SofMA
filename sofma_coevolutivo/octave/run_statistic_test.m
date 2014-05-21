set (0, "defaultlinelinewidth", 2);
load results.mat;

number_of_experiments = size(runtime)(1);

combinations = nchoosek (1:number_of_experiments, 2);

table_evaluations = [];
table_runtime = [];
for i=1:size(combinations)
    
    comb = combinations(i, :);
    
    [pval, z] = u_test(evaluations(comb(1), :), evaluations(comb(2), :));
    table_evaluations(comb(2), comb(1)) = pval;
    
    [pval, z] = u_test(runtime(comb(1), :), runtime(comb(2), :));
    table_runtime(comb(2), comb(1)) = pval;
    
endfor

%table_evaluations
%table_runtime

save tables.mat table_evaluations table_runtime
