set (0, "defaultlinelinewidth", 2);
set (0, "defaultaxesfontname", "Helvetica")
set (0, "defaultaxesfontsize", 15)

load results.mat;

% sort runtime
a = boxplot(runtime');
[sorted, order] = sort(a(3, :)); % position 3 has the median!
sorted_runtime = [];
sorted_experiments = [];
for i=1:length(order)
    sorted_runtime = [sorted_runtime , runtime(order(i), :)'];
    sorted_experiments = [sorted_experiments ; experiments(order(i), :)];
endfor
%sorted_runtime

% Boxplot sorted runtime
boxplot(sorted_runtime);
ylabel("Tiempo de ejecución (s)");
%xlabel("Configuración");
xlabel("Tamaño de regla");
tics("x", [1 : size(experiments)(1)], sorted_experiments);
print("results_runtime.png");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sort evaluations
a = boxplot(evaluations');
[sorted, order] = sort(a(3, :)); % position 3 has the median!
sorted_evaluations = [];
sorted_experiments = [];
for i=1:length(order)
    sorted_evaluations = [sorted_evaluations , evaluations(order(i), :)'];
    sorted_experiments = [sorted_experiments ; experiments(order(i), :)];
endfor
%sorted_evaluations

% Boxplot sorted evaluations
boxplot(sorted_evaluations);
ylabel("Número de evaluaciones");
%xlabel("Configuración");
xlabel("Tamaño de regla");
tics("x", [1 : size(experiments)(1)], sorted_experiments);
print("results_evaluations.png");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Qualified Runtime Distribution

set (0, "defaultaxesfontsize", 13)
load results.mat;

total_time = max(max(runtime));
%total_time = 60
%total_time = 120
% number_of_executions = length(runtime)
step = 1; %total_time/number_of_executions
number_of_experiments = size(runtime)(1);
number_of_executions = size(runtime)(2);

x = 0:step:total_time;
clf;
hold on;

tol=0.5
lims=[1:number_of_experiments];
for row = lims
	
	r = runtime(row,:);
	for t_i = 1:length(r)
	    if abs(total_time - r(t_i)) < tol
	        r(t_i) = total_time;
        endif
	endfor
	y = [];
	
	for time = 1:length(x)
		ammount = length(r(lt(r,x(time))));
		y(time) = ammount/number_of_executions;
		
	endfor
	
	switch(row)
		case {1}
			color = [1 0 0];
		case {2}
			color = [1 0.54902 0];
		case {3}
			color = [1 0.843137 0];
		case {4}
			color = [0 0 0.545098];
		case {5}
			color = [0.580392 0 0.827451];
		case {6}
			color = [0.117647 0.564706 1];
		case {7}
			color = [0 0.392157 0];
		case {8}
			color = [ 0.196078 0.803922 0.196078];
		case {9}
			color = [0.498039 1 0];
		otherwise
			color = [0 0 0];
	endswitch
		
	h=plot(x,y, "color", color);
	
endfor
xlabel("Tiempo de ejecución (s)", "FontSize", 15);
legend(experiments(lims, :), "location", "northwest");%"outside");
axis([0 total_time 0 1])#, "autoy")

print("results_qrd.png");

%------------------------------------------------------------------------------%

%all_lims=[[1:3]; [4:6]; [7:9]; [1:3:9]; [2:3:9]; [3:3:9]];
%for index=1:6
%    lims = all_lims(index,:);
%    clf;
%    hold on;
%
%    for row = lims
%	
%	    r = runtime(row,:);
%	    y = [];
%	
%	    for time = 1:length(x)
%		    ammount = length(r(lt(r,x(time))));
%		    y(time) = ammount/number_of_executions;
%		
%	    endfor
%	
%	    switch(row)
%		    case {1}
%			    color = [1 0 0];
%		    case {2}
%			    color = [1 0.54902 0];
%		    case {3}
%			    color = [1 0.843137 0];
%		    case {4}
%			    color = [0 0 0.545098];
%		    case {5}
%			    color = [0.580392 0 0.827451];
%		    case {6}
%			    color = [0.117647 0.564706 1];
%		    case {7}
%			    color = [0 0.392157 0];
%		    case {8}
%			    color = [ 0.196078 0.803922 0.196078];
%		    case {9}
%			    color = [0.498039 1 0];
%		    otherwise
%			    color = [0 0 0];
%	    endswitch
%		
%	    h=plot(x,y, "color", color);
%	
%    endfor
%    xlabel("Tiempo de ejecución (s)", "FontSize", 15);
%    legend(experiments(lims, :), "location", "northwest");%"outside");
%
%    print(strcat("results_qrd", mat2str(index), ".png"));
%
%endfor



set (0, "defaultaxesfontsize", 15)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf;
load results.mat;

max_fitness=max(max(fitnesses));
%max_fitness=192
min_fitness=min(min(fitnesses));

% count how many finished
finished = [];
for i=1:size(fitnesses)(1)
    finished = [finished sum(map(@(x) x==max_fitness, fitnesses(i, :)))];
endfor
%finished

% sort finished
[sorted, order] = sort(finished);
sorted_finished = [];
sorted_experiments = [];
for i=fliplr(1:length(order))
    sorted_finished = [sorted_finished , finished(order(i))'];
    sorted_experiments = [sorted_experiments ; experiments(order(i), :)];
endfor
%sorted_finished


% Bar sorted evaluations
if length(sorted_finished) == 1
    bar([sorted_finished 0], "facecolor", [0.196078 0.803922 0.196078])
else
    bar(sorted_finished, "facecolor", [0.196078 0.803922 0.196078])
endif
axis([0 1 0 max(sorted_finished)+1], "autox")
ylabel("Número de soluciones encontradas");
%xlabel("Configuración");
xlabel("Tamaño de regla");
tics("x", [1 : size(experiments)(1)], sorted_experiments);
print("results_finished.png");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf;
load results.mat;

% sort fitnesses
a = boxplot(fitnesses');
[sorted, order] = sort(a(3, :)); % position 3 has the median!
sorted_fitnesses = [];
sorted_experiments = [];
for i=fliplr(1:length(order))
    sorted_fitnesses = [sorted_fitnesses , fitnesses(order(i), :)'];
    sorted_experiments = [sorted_experiments ; experiments(order(i), :)];
endfor
%sorted_fitnesses

% Boxplot sorted fitnesses
boxplot(sorted_fitnesses);
ylabel("Fitness final");
%xlabel("Configuración");
xlabel("Tamaño de regla");
tics("x", [1 : size(experiments)(1)], sorted_experiments);

max_fitness=max(max(fitnesses));
%max_fitness=240
%max_fitness=192
%max_fitness=40
min_fitness=min(min(fitnesses));

hold on
x_line=get(gca,'XLim');
y_line=max_fitness*ones(1,length(x_line));
plot(x_line,y_line, '--', "color", [0.196078 0.803922 0.196078])

axis([0 1 min_fitness-1 max_fitness+1], "autox")
%axis([0 1 0 max_fitness+1], "autox")

set(gca, 'YTick', [min_fitness get(gca, 'YTick') max_fitness]);
%[sorted, order] = sort([249985 , min_fitness get(gca, 'YTick') max_fitness]);
%set(gca, 'YTick', sorted);
%set(gca, 'YTick', [140 min_fitness 150:10:190 max_fitness 200]);
%set(gca, 'YTick', [150 min_fitness 160:10:230 max_fitness 250]);
%set(gca, 'YTick', [249980 min_fitness 249990:10:250040 max_fitness 250050]);

print("results_fitnesses.png");



