set (0, "defaultlinelinewidth", 2);
load entropy.mat;

x = 0:length(entropy_chroms)-1;
plot(x,entropy_chroms);
title ("Chromosomes entropy per generation");
print("results_entropy_chroms.png");

x = 0:length(entropy_rules)-1;
plot(x,entropy_rules);
title ("Rule entropy per generation");
print("results_entropy_rules.png");

x = 0:length(entropy_rules_length)-1;
plot(x,entropy_rules_length);
title ("Rule length entropy per generation");
print("results_entropy_rules_length.png");

x = 0:length(mean_rules_length)-1;
plot(x,mean_rules_length);
title ("Rule length average per generation");
print("results_mean_rules_length.png");

