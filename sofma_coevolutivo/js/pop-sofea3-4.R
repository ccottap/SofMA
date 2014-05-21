plot(pop.avg.sofea3.R2$V1, pop.avg.sofea3.R2$V0,type='l',col='red', main='Average population, SofEA 3 vs SofEA 4', sub="2 clients",xlab='Steps',ylab='Population',xlim=c(0,14000))
lines(pop.avg.sofea4.R2$V1, pop.avg.sofea4.R2$V0,type='l',lty=2)
