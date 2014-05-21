set (0, "defaultlinelinewidth", 2);
load results_bars;

confs = ["L1-R1-1"; "L2-R1-1"; "L2-R1-2"; "L2-R2-1"; "L4-R1-1"; "L4-R1-2"; "L4-R2-1"; "L4-R1-4"; "L4-R4-1"];

experiments = ["l128-r128"; "l128-r64"; "l128-r32"; "l64-r128"; "l64-r64"; "l64-r32"; "l32-r128"; "l32-r64"; "l32-r32"];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trap=trap';
h = bar(trap);

set (h(1), "facecolor", [1 0 0]);
set (h(2), "facecolor", [1 0.54902 0]);
set (h(3), "facecolor", [1 0.843137 0]);
set (h(4), "facecolor", [0 0 0.545098]);
set (h(5), "facecolor", [0.580392 0 0.827451]);
set (h(6), "facecolor", [0.117647 0.564706 1]);
set (h(7), "facecolor", [0 0.392157 0]);
set (h(8), "facecolor", [ 0.196078 0.803922 0.196078]);
set (h(9), "facecolor", [0.498039 1 0]);
legend(experiments, "location", "northeast"); %"outside"

%axis([0 1 0 max(max(trap))+1], "autox")
tics("x", [1 : size(confs)(1)], confs);
print("bars_trap.png", "-S1200,500");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmdp=mmdp';
h = bar(mmdp);

set (h(1), "facecolor", [1 0 0]);
set (h(2), "facecolor", [1 0.54902 0]);
set (h(3), "facecolor", [1 0.843137 0]);
set (h(4), "facecolor", [0 0 0.545098]);
set (h(5), "facecolor", [0.580392 0 0.827451]);
set (h(6), "facecolor", [0.117647 0.564706 1]);
set (h(7), "facecolor", [0 0.392157 0]);
set (h(8), "facecolor", [ 0.196078 0.803922 0.196078]);
set (h(9), "facecolor", [0.498039 1 0]);
legend(experiments, "location", "north"); %"outside"

%axis([0 1 0 max(max(mmdp))+1], "autox")
tics("x", [1 : size(confs)(1)], confs);
print("bars_mmdp.png", "-S1200,500");

