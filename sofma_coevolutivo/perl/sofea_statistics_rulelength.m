load rulelength.mat;

hold on
for exp=1:rows(rulelength)
    size = rulelength(exp, end);
    x=[1:size];
    plot(x, rulelength(exp, 1:size), 'r*');
endfor

max_v = max(max(rulelength(:,1:end-1)))

title ("Rule Length Evolution");
print("results_rulelength.png")


