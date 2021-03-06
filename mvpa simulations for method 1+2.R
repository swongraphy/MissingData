load("/Users/Selene/Desktop/Updated Missing Data/extended data with activity and date.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/MVPA/aggregate data.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/days with more than 50% time.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/days with 50%-60% time missing.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/days with 60%-70% time missing.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/days with 70%-80% time missing.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/days with 80%-90% time missing.rdata")
load("/Users/Selene/Desktop/Updated Missing Data/days with 90%-100% time missing.rdata")
library(nlme)

##################################################################
##################################################################
#run 100 simulations, each time simulate missing patterns from the set of "complete" profiles using the pairwise comparison algorithm and then apply method 1 (weighted regression) and method 2 (imputed sum). 
#record the results from 100 simulations
##################################################################

#read health variables
nv=read.csv('/Users/Selene/Desktop/Updated Missing Data/variables.csv',h=T)
nv=nv[,c(1,3,4,16)]
names(nv)=c('identifier','BMI','age','depression')
nv$identifier=as.character(nv$identifier)
nv$depression=as.character(nv$depression)
#save(nv,file='covariates.rdata')



#save number of profiles in each stratum of "missingness". Used for simulating missing patterns from "complete" profiles later
sub=ag[ag$prop<0.5,]
sub5=ag[ag$prop>=0.5 & ag$prop<0.6,]
sub6=ag[ag$prop>=0.6 & ag$prop<0.7,]
sub7=ag[ag$prop>=0.7 & ag$prop<0.8,]
sub8=ag[ag$prop>=0.8 & ag$prop<0.9,]
sub9=ag[ag$prop>=0.9 & ag$prop<1,]
tots=list(sub5,sub6,sub7,sub8,sub9)
sum=nrow(ag)
perc=1:5
for (i in perc){
	perc[i]=nrow(tots[[i]])/sum
}
n=round(perc*nrow(sub))

#run 10 simulations at a time and save results for every 10 simluations
m0=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
m1=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
m2=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
m3=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
m4=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
rm1=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
rm2=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))
rm3=data.frame(matrix(rep(0,150), ncol = 15, nrow = 10))

for (k in 1:10){
	#start with the set of complete profiles (name is newd), choose an appropriate number of days to become days with 50%-60% time missing
	simd=newd
	ind5=1:nrow(sub)
	sam5=sample(ind5,n[1])
	samp5=sub[sam5,]
	index5=1:nrow(sub5)
	sample5=sub5[sample(index5,n[1]),]
	for (i in 1:n[1]){
		simd[simd$dt==samp5[i,1] & simd$identifier==samp5[i,2],5]=newd5[newd5$dt==sample5[i,1] & 			newd5$identifier==sample5[i,2],5]
	}
	
	#from what's left in the set of complete profiles, choose an appropriate number of days to become days with 60%-70% time missing
	sub.a5=sub[-sam5,]
	ind6=1:nrow(sub.a5)
	sam6=sample(ind6,n[2])
	samp6=sub.a5[sam6,]
	index6=1:nrow(sub6)
	sample6=sub6[sample(index6,n[2]),]
	for (i in 1:n[2]){
		simd[simd$dt==samp6[i,1] & simd$identifier==samp6[i,2],5]=newd6[newd6$dt==sample6[i,1] & 			newd6$identifier==sample6[i,2],5]
	}

	#from what's left in the set of complete profiles, choose an appropriate number of days to become days with 70%-80% time missing
	sub.a6=sub.a5[-sam6,]
	ind7=1:nrow(sub.a6)
	sam7=sample(ind7,n[3])
	samp7=sub.a6[sam7,]
	index7=1:nrow(sub7)
	sample7=sub7[sample(index7,n[3]),]
	for (i in 1:n[3]){
		simd[simd$dt==samp7[i,1] & simd$identifier==samp7[i,2],5]=newd7[newd7$dt==sample7[i,1] & 			newd7$identifier==sample7[i,2],5]
	}

	#from what's left in the set of complete profiles, choose an appropriate number of days to become days with 80%-90% time missing
	sub.a7=sub.a6[-sam7,]
	ind8=1:nrow(sub.a7)
	sam8=sample(ind8,n[4])
	samp8=sub.a7[sam8,]
	index8=1:nrow(sub8)
	sample8=sub8[sample(index8,n[4]),]
	for (i in 1:n[4]){
		simd[simd$dt==samp8[i,1] & simd$identifier==samp8[i,2],5]=newd8[newd8$dt==sample8[i,1] & 			newd8$identifier==sample8[i,2],5]
	}

	#from what's left in the set of complete profiles, choose an appropriate number of days to become days with 90%-100% time missing
	sub.a8=sub.a7[-sam8,]
	ind9=1:nrow(sub.a8)
	sam9=sample(ind9,n[5])
	samp9=sub.a8[sam9,]
	index9=1:nrow(sub9)
	sample9=sub9[sample(index9,n[5]),]
	for (i in 1:n[5]){
		simd[simd$dt==samp9[i,1] & simd$identifier==samp9[i,2],5]=newd9[newd9$dt==sample9[i,1] & 			newd9$identifier==sample9[i,2],5]
	}
	
	#get daily mvpa and scale it according to weartime
	simd[simd$miss==0,3]=NA
	simagg=aggregate(simd$activity,list(simd$dt,simd$identifier),mean,na.rm=TRUE)
	names(simagg)=c('dt','identifier','activity')	
	mvpa.0=list()
	for(i in 1:length(unique(simagg$identifier))){
		x=simd[simd$identifier==unique(simagg$identifier)[i],]
		s=rep(0,length(unique(x$dt)))
		for(j in 1:length(unique(x$dt))){
			s[j]=length(x[x$dt==unique(x$dt)[j] & x$activity>1951,3])
		}
		mvpa.0[[i]]=s
	}
	mvpa.0=unlist(mvpa.0)
	simagg$mvpa.0=mvpa.0
	miss=list()
	for(i in 1:length(unique(simagg$identifier))){
		x=simd[simd$identifier==unique(simagg$identifier)[i],]
		s=rep(0,length(unique(x$dt)))
		for(j in 1:length(unique(x$dt))){
			s[j]=length(x[x$dt==unique(x$dt)[j] & x$activity<0,3])
		}
		miss[[i]]=s
	}
	miss=unlist(miss)
	simagg$miss=miss
	simagg$mvpa=simagg$mvpa.0-simagg$miss
	simagg$wt=1440-simagg$miss
	simagg$mvpa.adj=simagg$mvpa/simagg$wt*720
	simag=na.omit(simagg)
	
	#running regression using method 1: weighted regression (with 5 different weighing schemes)
	simag$identifier=as.character(simag$identifier)
	simag$identifier=substr(simag$identifier,4,15)
	for(i in 1:nrow(simag)){
		ma=match(simag$identifier[i],nv[,1])
		simag$age[i]=nv[ma,3]
		simag$bmi[i]=nv[ma,2]
		simag$depression[i]=nv[ma,4]
	}
	simag$depression=ifelse(simag$depression=="Don't Know", NA,simag$depression)
	simag$depression=as.factor(simag$depression)
	simag$dt=as.Date(simag$dt)
	simag$dow=weekdays(simag$dt)
	simag$ind=ifelse(simag$dow=='Saturday'|simag$dow=='Sunday',1,0)
	simag$ind=as.factor(simag$ind)
	simag=na.omit(simag)
	simag$prop=simag$miss/1440
	simag$weights=1/(1-simag$prop)
	
	nvmodel=lme(mvpa.adj~age+bmi+depression+ind,random=~1|identifier,simag,method='REML')
	nvmodel1=update(nvmodel,weights=varFixed(~weights))
	nvmodel2=update(nvmodel,weights=varFixed(~prop))
	nvmodel3=update(nvmodel,weights=varFixed(~prop^2))
	nvmodel4=update(nvmodel,weights=varExp(1,form=~prop))
	
	m0[k,1]=summary(nvmodel)$AIC
	m0[k,2]=summary(nvmodel)$BIC
	m0[k,3]=summary(nvmodel)$logLik
	m0[k,4]=summary(nvmodel)$coefficients[[1]][2]
	m0[k,7]=summary(nvmodel)$coefficients[[1]][3]
	m0[k,10]=summary(nvmodel)$coefficients[[1]][4]
	m0[k,5]=summary(nvmodel)$tTable[2,2]
	m0[k,8]=summary(nvmodel)$tTable[3,2]
	m0[k,11]=summary(nvmodel)$tTable[4,2]
	m0[k,6]=summary(nvmodel)$tTable[2,5]
	m0[k,9]=summary(nvmodel)$tTable[3,5]
	m0[k,12]=summary(nvmodel)$tTable[4,5]
	m0[k,13]=summary(nvmodel)$coefficients[[1]][5]
	m0[k,14]=summary(nvmodel)$tTable[5,2]
	m0[k,15]=summary(nvmodel)$tTable[5,5]
	

	m1[k,1]=summary(nvmodel1)$AIC
	m1[k,2]=summary(nvmodel1)$BIC
	m1[k,3]=summary(nvmodel1)$logLik
	m1[k,4]=summary(nvmodel1)$coefficients[[1]][2]
	m1[k,7]=summary(nvmodel1)$coefficients[[1]][3]
	m1[k,10]=summary(nvmodel1)$coefficients[[1]][4]
	m1[k,5]=summary(nvmodel1)$tTable[2,2]
	m1[k,8]=summary(nvmodel1)$tTable[3,2]
	m1[k,11]=summary(nvmodel1)$tTable[4,2]
	m1[k,6]=summary(nvmodel1)$tTable[2,5]
	m1[k,9]=summary(nvmodel1)$tTable[3,5]
	m1[k,12]=summary(nvmodel1)$tTable[4,5]
	m1[k,13]=summary(nvmodel1)$coefficients[[1]][5]
	m1[k,14]=summary(nvmodel1)$tTable[5,2]
	m1[k,15]=summary(nvmodel1)$tTable[5,5]


	
	m2[k,1]=summary(nvmodel2)$AIC
	m2[k,2]=summary(nvmodel2)$BIC
	m2[k,3]=summary(nvmodel2)$logLik
	m2[k,4]=summary(nvmodel2)$coefficients[[1]][2]
	m2[k,7]=summary(nvmodel2)$coefficients[[1]][3]
	m2[k,10]=summary(nvmodel2)$coefficients[[1]][4]
	m2[k,5]=summary(nvmodel2)$tTable[2,2]
	m2[k,8]=summary(nvmodel2)$tTable[3,2]
	m2[k,11]=summary(nvmodel2)$tTable[4,2]
	m2[k,6]=summary(nvmodel2)$tTable[2,5]
	m2[k,9]=summary(nvmodel2)$tTable[3,5]
	m2[k,12]=summary(nvmodel2)$tTable[4,5]
	m2[k,13]=summary(nvmodel2)$coefficients[[1]][5]
	m2[k,14]=summary(nvmodel2)$tTable[5,2]
	m2[k,15]=summary(nvmodel2)$tTable[5,5]



	m3[k,1]=summary(nvmodel3)$AIC
	m3[k,2]=summary(nvmodel3)$BIC
	m3[k,3]=summary(nvmodel3)$logLik
	m3[k,4]=summary(nvmodel3)$coefficients[[1]][2]
	m3[k,7]=summary(nvmodel3)$coefficients[[1]][3]
	m3[k,10]=summary(nvmodel3)$coefficients[[1]][4]
	m3[k,5]=summary(nvmodel3)$tTable[2,2]
	m3[k,8]=summary(nvmodel3)$tTable[3,2]
	m3[k,11]=summary(nvmodel3)$tTable[4,2]
	m3[k,6]=summary(nvmodel3)$tTable[2,5]
	m3[k,9]=summary(nvmodel3)$tTable[3,5]
	m3[k,12]=summary(nvmodel3)$tTable[4,5]
	m3[k,13]=summary(nvmodel3)$coefficients[[1]][5]
	m3[k,14]=summary(nvmodel3)$tTable[5,2]
	m3[k,15]=summary(nvmodel3)$tTable[5,5]



	m4[k,1]=summary(nvmodel4)$AIC
	m4[k,2]=summary(nvmodel4)$BIC
	m4[k,3]=summary(nvmodel4)$logLik
	m4[k,4]=summary(nvmodel4)$coefficients[[1]][2]
	m4[k,7]=summary(nvmodel4)$coefficients[[1]][3]
	m4[k,10]=summary(nvmodel4)$coefficients[[1]][4]
	m4[k,5]=summary(nvmodel4)$tTable[2,2]
	m4[k,8]=summary(nvmodel4)$tTable[3,2]
	m4[k,11]=summary(nvmodel4)$tTable[4,2]
	m4[k,6]=summary(nvmodel4)$tTable[2,5]
	m4[k,9]=summary(nvmodel4)$tTable[3,5]
	m4[k,12]=summary(nvmodel4)$tTable[4,5]
	m4[k,13]=summary(nvmodel4)$coefficients[[1]][5]
	m4[k,14]=summary(nvmodel4)$tTable[5,2]
	m4[k,15]=summary(nvmodel4)$tTable[5,5]

	print(m0)
	
	#run regression using method 2: imputed sum (with 3 different mixed model approaches)
	simm=lme(mvpa~wt,random=~1|identifier,simag,method='REML')
	good=simag[simag$prop<0.5,]
	bad=simag[simag$prop>=0.5,]
	diff=720-bad$wt
	slope=simm$coefficients$fixed[2]
	act=diff*slope
	bad$mvpa.adj=bad$mvpa+act
	bad$wt=720
#	bad$activity=bad$activitysum/720
	newag=rbind(good,bad)


	mod=lme(mvpa.adj~age+bmi+depression+ind,random=~1|identifier,newag,method='REML')
	rm1[k,1]=summary(mod)$AIC
	rm1[k,2]=summary(mod)$BIC
	rm1[k,3]=summary(mod)$logLik
	rm1[k,4]=summary(mod)$coefficients[[1]][2]
	rm1[k,7]=summary(mod)$coefficients[[1]][3]
	rm1[k,10]=summary(mod)$coefficients[[1]][4]
	rm1[k,5]=summary(mod)$tTable[2,2]
	rm1[k,8]=summary(mod)$tTable[3,2]
	rm1[k,11]=summary(mod)$tTable[4,2]
	rm1[k,6]=summary(mod)$tTable[2,5]
	rm1[k,9]=summary(mod)$tTable[3,5]
	rm1[k,12]=summary(mod)$tTable[4,5]
	rm1[k,13]=summary(mod)$coefficients[[1]][5]
	rm1[k,14]=summary(mod)$tTable[5,2]
	rm1[k,15]=summary(mod)$tTable[5,5]


	simm2=lme(mvpa~wt,random=~1+wt|identifier,simag,method='REML')
	good=simag[simag$prop<0.5,]
	bad=simag[simag$prop>=0.5,]
	for(i in 1:nrow(bad)){
		name=bad[i,2]
		row=which(rownames(simm2$coefficients$random$identifier)==name)
		slope=simm2$coefficients$random$identifier[row,2]+simm2$coefficients$fixed[2]
		diff=720-bad[i,7]
		act=diff*slope
		bad$mvpa.adj[i]=bad$mvpa[i]+act
		bad$wt[i]=720

	}
	newag=rbind(good,bad)
	newag=na.omit(newag)

	mod2=lme(mvpa.adj~age+bmi+depression+ind,random=~1|identifier,newag,method='REML')
	rm2[k,1]=summary(mod2)$AIC
	rm2[k,2]=summary(mod2)$BIC
	rm2[k,3]=summary(mod2)$logLik
	rm2[k,4]=summary(mod2)$coefficients[[1]][2]
	rm2[k,7]=summary(mod2)$coefficients[[1]][3]
	rm2[k,10]=summary(mod2)$coefficients[[1]][4]
	rm2[k,5]=summary(mod2)$tTable[2,2]
	rm2[k,8]=summary(mod2)$tTable[3,2]
	rm2[k,11]=summary(mod2)$tTable[4,2]
	rm2[k,6]=summary(mod2)$tTable[2,5]
	rm2[k,9]=summary(mod2)$tTable[3,5]
	rm2[k,12]=summary(mod2)$tTable[4,5]
	rm2[k,13]=summary(mod2)$coefficients[[1]][5]
	rm2[k,14]=summary(mod2)$tTable[5,2]
	rm2[k,15]=summary(mod2)$tTable[5,5]

	simm3=lme(mvpa~wt-1,random=~wt-1|identifier,simag,method='REML')
	good=simag[simag$prop<0.5,]
	bad=simag[simag$prop>=0.5,]
	for(i in 1:nrow(bad)){
		name=bad[i,2]
		row=which(rownames(simm3$coefficients$random$identifier)==name)
		slope=simm3$coefficients$random$identifier[row,1]+simm3$coefficients$fixed[1]
		diff=720-bad[i,7]
		act=diff*slope
		bad$mvpa.adj[i]=bad$mvpa[i]+act
		bad$wt[i]=720

	}
	newag=rbind(good,bad)
	newag=na.omit(newag)

	mod3=lme(mvpa.adj~age+bmi+depression+ind,random=~1|identifier,newag,method='REML')
	rm3[k,1]=summary(mod3)$AIC
	rm3[k,2]=summary(mod3)$BIC
	rm3[k,3]=summary(mod3)$logLik
	rm3[k,4]=summary(mod3)$coefficients[[1]][2]
	rm3[k,7]=summary(mod3)$coefficients[[1]][3]
	rm3[k,10]=summary(mod3)$coefficients[[1]][4]
	rm3[k,5]=summary(mod3)$tTable[2,2]
	rm3[k,8]=summary(mod3)$tTable[3,2]
	rm3[k,11]=summary(mod3)$tTable[4,2]
	rm3[k,6]=summary(mod3)$tTable[2,5]
	rm3[k,9]=summary(mod3)$tTable[3,5]
	rm3[k,12]=summary(mod3)$tTable[4,5]
	rm3[k,13]=summary(mod3)$coefficients[[1]][5]
	rm3[k,14]=summary(mod3)$tTable[5,2]
	rm3[k,15]=summary(mod3)$tTable[5,5]

	print(rm1)
}

#save results after every 10 simulations	
setwd("/Users/Selene/Desktop")
sim1=list()
sim1[[1]]=m0
sim1[[2]]=m1
sim1[[3]]=m2
sim1[[4]]=m3
sim1[[5]]=m4
sim1[[6]]=rm1
sim1[[7]]=rm2
sim1[[8]]=rm3
save(sim1,file='sim1.rdata')


sim2=list()
sim2[[1]]=m0
sim2[[2]]=m1
sim2[[3]]=m2
sim2[[4]]=m3
sim2[[5]]=m4
sim2[[6]]=rm1
sim2[[7]]=rm2
sim2[[8]]=rm3
save(sim2,file='sim2.rdata')
	
sim3=list()
sim3[[1]]=m0
sim3[[2]]=m1
sim3[[3]]=m2
sim3[[4]]=m3
sim3[[5]]=m4
sim3[[6]]=rm1
sim3[[7]]=rm2
sim3[[8]]=rm3
save(sim3,file='sim3.rdata')

sim4=list()
sim4[[1]]=m0
sim4[[2]]=m1
sim4[[3]]=m2
sim4[[4]]=m3
sim4[[5]]=m4
sim4[[6]]=rm1
sim4[[7]]=rm2
sim4[[8]]=rm3
save(sim4,file='sim4.rdata')

sim5=list()
sim5[[1]]=m0
sim5[[2]]=m1
sim5[[3]]=m2
sim5[[4]]=m3
sim5[[5]]=m4
sim5[[6]]=rm1
sim5[[7]]=rm2
sim5[[8]]=rm3
save(sim5,file='sim5.rdata')

#combine results from all 100 simulations	
m0=rbind(sim1[[1]],sim2[[1]],sim3[[1]][1:39,],sim4[[1]],sim5[[1]])	
m1=rbind(sim1[[2]],sim2[[2]],sim3[[2]][1:39,],sim4[[2]],sim5[[2]])
m2=rbind(sim1[[3]],sim2[[3]],sim3[[3]][1:39,],sim4[[3]],sim5[[3]])
m3=rbind(sim1[[4]],sim2[[4]],sim3[[4]][1:39,],sim4[[4]],sim5[[4]])
m4=rbind(sim1[[5]],sim2[[5]],sim3[[5]][1:39,],sim4[[5]],sim5[[5]])
rm1=rbind(sim1[[6]],sim2[[6]],sim3[[6]][1:39,],sim4[[6]],sim5[[6]])
rm2=rbind(sim1[[7]],sim2[[7]],sim3[[7]][1:39,],sim4[[7]],sim5[[7]])
rm3=rbind(sim1[[8]],sim2[[8]],sim3[[8]][1:39,],sim4[[8]],sim5[[8]])

save(m0,file='m0.rdata')
save(m1,file='m1.rdata')
save(m2,file='m2.rdata')
save(m3,file='m3.rdata')
save(m4,file='m4.rdata')
save(rm1,file='rm1.rdata')
save(rm2,file='rm2.rdata')
save(rm3,file='rm3.rdata')

#tabulate model performance in terms of bias,  simulation standard deviation, and mean squared error
model0=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(model0)=c('MSE','Bias','Sim SD','Coverage')
rownames(model0)=c('age','bmi','depression','weekend')
model0[1,1]=sqrt(sum((m0[,4]+0.54238)^2)/100)
model0[1,2]=mean(m0[,4])+0.54238
model0[1,3]=sqrt((model0[1,1])^2-(model0[1,2])^2)
model0[1,4]=sum(ifelse(m0[,4]<0 & m0[,6]<0.01,1,0))/100
model0[2,1]=sqrt(sum((m0[,7]+0.69191)^2)/100)
model0[2,2]=mean(m0[,7])+0.69191
model0[2,3]=sqrt((model0[2,1])^2-(model0[2,2])^2)
model0[2,4]=sum(ifelse(m0[,7]<0 & m0[,9]<0.01,1,0))/100
model0[3,1]=sqrt(sum((m0[,10]+4.70393)^2)/100)
model0[3,2]=mean(m0[,10])+4.70393
model0[3,3]=sqrt((model0[3,1])^2-(model0[3,2])^2)
model0[3,4]=sum(ifelse(m0[,10]<0 & m0[,12]<0.01,1,0))/100
model0[4,1]=sqrt(sum((m0[,13]-0.10076)^2)/100)
model0[4,2]=mean(m0[,13])-0.10076
model0[4,3]=sqrt((model0[4,1])^2-(model0[4,2])^2)
model0[4,4]=sum(ifelse(m0[,13]>0 & m0[,15]>0.5,1,0))/100
save(model0,file='m0 result.rdata')

model1=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(model1)=c('MSE','Bias','Sim SD','Coverage')
rownames(model1)=c('age','bmi','depression','weekend')
model1[1,1]=sqrt(sum((m1[,4]+0.54238)^2)/100)
model1[1,2]=mean(m1[,4])+0.54238
model1[1,3]=sqrt((model1[1,1])^2-(model1[1,2])^2)
model1[1,4]=sum(ifelse(m1[,4]<0 & m1[,6]<0.01,1,0))/100
model1[2,1]=sqrt(sum((m1[,7]+0.69191)^2)/100)
model1[2,2]=mean(m1[,7])+0.69191
model1[2,3]=sqrt((model1[2,1])^2-(model1[2,2])^2)
model1[2,4]=sum(ifelse(m1[,7]<0 & m1[,9]<0.01,1,0))/100
model1[3,1]=sqrt(sum((m1[,10]+4.70393)^2)/100)
model1[3,2]=mean(m1[,10])+4.70393
model1[3,3]=sqrt((model1[3,1])^2-(model1[3,2])^2)
model1[3,4]=sum(ifelse(m1[,10]<0 & m1[,12]<0.01,1,0))/100
model1[4,1]=sqrt(sum((m1[,13]-0.10076)^2)/100)
model1[4,2]=mean(m1[,13])-0.10076
model1[4,3]=sqrt((model1[4,1])^2-(model1[4,2])^2)
model1[4,4]=sum(ifelse(m1[,13]>0 & m1[,15]>0.5,1,0))/100
save(model1,file='m1 result.rdata')

model2=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(model2)=c('MSE','Bias','Sim SD','Coverage')
rownames(model2)=c('age','bmi','depression','weekend')
model2[1,1]=sqrt(sum((m2[,4]+0.54238)^2)/100)
model2[1,2]=mean(m2[,4])+0.54238
model2[1,3]=sqrt((model2[1,1])^2-(model2[1,2])^2)
model2[1,4]=sum(ifelse(m2[,4]<0 & m2[,6]<0.01,1,0))/100
model2[2,1]=sqrt(sum((m2[,7]+0.69191)^2)/100)
model2[2,2]=mean(m2[,7])+0.69191
model2[2,3]=sqrt((model2[2,1])^2-(model2[2,2])^2)
model2[2,4]=sum(ifelse(m2[,7]<0 & m2[,9]<0.01,1,0))/100
model2[3,1]=sqrt(sum((m2[,10]+4.70393)^2)/100)
model2[3,2]=mean(m2[,10])+4.70393
model2[3,3]=sqrt((model2[3,1])^2-(model2[3,2])^2)
model2[3,4]=sum(ifelse(m2[,10]<0 & m2[,12]<0.01,1,0))/100
model2[4,1]=sqrt(sum((m2[,13]-0.10076)^2)/100)
model2[4,2]=mean(m2[,13])-0.10076
model2[4,3]=sqrt((model2[4,1])^2-(model2[4,2])^2)
model2[4,4]=sum(ifelse(m2[,13]>0 & m2[,15]>0.5,1,0))/100
save(model2,file='m2 result.rdata')

model3=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(model3)=c('MSE','Bias','Sim SD','Coverage')
rownames(model3)=c('age','bmi','depression','weekend')
model3[1,1]=sqrt(sum((m3[,4]+0.54238)^2)/100)
model3[1,2]=mean(m3[,4])+0.54238
model3[1,3]=sqrt((model3[1,1])^2-(model3[1,2])^2)
model3[1,4]=sum(ifelse(m3[,4]<0 & m3[,6]<0.01,1,0))/100
model3[2,1]=sqrt(sum((m3[,7]+0.69191)^2)/100)
model3[2,2]=mean(m3[,7])+0.69191
model3[2,3]=sqrt((model3[2,1])^2-(model3[2,2])^2)
model3[2,4]=sum(ifelse(m3[,7]<0 & m3[,9]<0.01,1,0))/100
model3[3,1]=sqrt(sum((m3[,10]+4.70393)^2)/100)
model3[3,2]=mean(m3[,10])+4.70393
model3[3,3]=sqrt((model3[3,1])^2-(model3[3,2])^2)
model3[3,4]=sum(ifelse(m3[,10]<0 & m3[,12]<0.01,1,0))/100
model3[4,1]=sqrt(sum((m3[,13]-0.10076)^2)/100)
model3[4,2]=mean(m3[,13])-0.10076
model3[4,3]=sqrt((model3[4,1])^2-(model3[4,2])^2)
model3[4,4]=sum(ifelse(m3[,13]>0 & m3[,15]>0.5,1,0))/100
save(model3,file='m3 result.rdata')

model4=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(model4)=c('MSE','Bias','Sim SD','Coverage')
rownames(model4)=c('age','bmi','depression','weekend')
model4[1,1]=sqrt(sum((m4[,4]+0.54238)^2)/100)
model4[1,2]=mean(m4[,4])+0.54238
model4[1,3]=sqrt((model4[1,1])^2-(model4[1,2])^2)
model4[1,4]=sum(ifelse(m4[,4]<0 & m4[,6]<0.01,1,0))/100
model4[2,1]=sqrt(sum((m4[,7]+0.69191)^2)/100)
model4[2,2]=mean(m4[,7])+0.69191
model4[2,3]=sqrt((model4[2,1])^2-(model4[2,2])^2)
model4[2,4]=sum(ifelse(m4[,7]<0 & m4[,9]<0.01,1,0))/100
model4[3,1]=sqrt(sum((m4[,10]+4.70393)^2)/100)
model4[3,2]=mean(m4[,10])+4.70393
model4[3,3]=sqrt((model4[3,1])^2-(model4[3,2])^2)
model4[3,4]=sum(ifelse(m4[,10]<0 & m4[,12]<0.01,1,0))/100
model4[4,1]=sqrt(sum((m4[,13]-0.10076)^2)/100)
model4[4,2]=mean(m4[,13])-0.10076
model4[4,3]=sqrt((model4[4,1])^2-(model4[4,2])^2)
model4[4,4]=sum(ifelse(m4[,13]>0 & m4[,15]>0.5,1,0))/100
save(model4,file='m4 result.rdata')

rmodel1=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(rmodel1)=c('MSE','Bias','Sim SD','Coverage')
rownames(rmodel1)=c('age','bmi','depression','weekend')
rmodel1[1,1]=sqrt(sum((rm1[,4]+0.54238)^2)/100)
rmodel1[1,2]=mean(rm1[,4])+0.54238
rmodel1[1,3]=sqrt((rmodel1[1,1])^2-(rmodel1[1,2])^2)
rmodel1[1,4]=sum(ifelse(rm1[,4]<0 & rm1[,6]<0.01,1,0))/100
rmodel1[2,1]=sqrt(sum((rm1[,7]+0.69191)^2)/100)
rmodel1[2,2]=mean(rm1[,7])+0.69191
rmodel1[2,3]=sqrt((rmodel1[2,1])^2-(rmodel1[2,2])^2)
rmodel1[2,4]=sum(ifelse(rm1[,7]<0 & rm1[,9]<0.01,1,0))/100
rmodel1[3,1]=sqrt(sum((rm1[,10]+4.70393)^2)/100)
rmodel1[3,2]=mean(rm1[,10])+4.70393
rmodel1[3,3]=sqrt((rmodel1[3,1])^2-(rmodel1[3,2])^2)
rmodel1[3,4]=sum(ifelse(rm1[,10]<0 & rm1[,12]<0.01,1,0))/100
rmodel1[4,1]=sqrt(sum((rm1[,13]-0.10076)^2)/100)
rmodel1[4,2]=mean(rm1[,13])-0.10076
rmodel1[4,3]=sqrt((rmodel1[4,1])^2-(rmodel1[4,2])^2)
rmodel1[4,4]=sum(ifelse(rm1[,13]>0 & rm1[,15]>0.5,1,0))/100
save(rmodel1,file='rm1 result.rdata')

rmodel2=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(rmodel2)=c('MSE','Bias','Sim SD','Coverage')
rownames(rmodel2)=c('age','bmi','depression','weekend')
rmodel2[1,1]=sqrt(sum((rm2[,4]+0.54238)^2)/100)
rmodel2[1,2]=mean(rm2[,4])+0.54238
rmodel2[1,3]=sqrt((rmodel2[1,1])^2-(rmodel2[1,2])^2)
rmodel2[1,4]=sum(ifelse(rm2[,4]<0 & rm2[,6]<0.01,1,0))/100
rmodel2[2,1]=sqrt(sum((rm2[,7]+0.69191)^2)/100)
rmodel2[2,2]=mean(rm2[,7])+0.69191
rmodel2[2,3]=sqrt((rmodel2[2,1])^2-(rmodel2[2,2])^2)
rmodel2[2,4]=sum(ifelse(rm2[,7]<0 & rm2[,9]<0.01,1,0))/100
rmodel2[3,1]=sqrt(sum((rm2[,10]+4.70393)^2)/100)
rmodel2[3,2]=mean(rm2[,10])+4.70393
rmodel2[3,3]=sqrt((rmodel2[3,1])^2-(rmodel2[3,2])^2)
rmodel2[3,4]=sum(ifelse(rm2[,10]<0 & rm2[,12]<0.01,1,0))/100
rmodel2[4,1]=sqrt(sum((rm2[,13]-0.10076)^2)/100)
rmodel2[4,2]=mean(rm2[,13])-0.10076
rmodel2[4,3]=sqrt((rmodel2[4,1])^2-(rmodel2[4,2])^2)
rmodel2[4,4]=sum(ifelse(rm2[,13]>0 & rm2[,15]>0.5,1,0))/100
save(rmodel2,file='rm2 result.rdata')

rmodel3=data.frame(matrix(rep(0,12), ncol = 4, nrow = 4))
colnames(rmodel3)=c('MSE','Bias','Sim SD','Coverage')
rownames(rmodel3)=c('age','bmi','depression','weekend')
rmodel3[1,1]=sqrt(sum((rm3[,4]+0.54238)^2)/100)
rmodel3[1,2]=mean(rm3[,4])+0.54238
rmodel3[1,3]=sqrt((rmodel3[1,1])^2-(rmodel3[1,2])^2)
rmodel3[1,4]=sum(ifelse(rm3[,4]<0 & rm3[,6]<0.01,1,0))/100
rmodel3[2,1]=sqrt(sum((rm3[,7]+0.69191)^2)/100)
rmodel3[2,2]=mean(rm3[,7])+0.69191
rmodel3[2,3]=sqrt((rmodel3[2,1])^2-(rmodel3[2,2])^2)
rmodel3[2,4]=sum(ifelse(rm3[,7]<0 & rm3[,9]<0.01,1,0))/100
rmodel3[3,1]=sqrt(sum((rm3[,10]+4.70393)^2)/100)
rmodel3[3,2]=mean(rm3[,10])+4.70393
rmodel3[3,3]=sqrt((rmodel3[3,1])^2-(rmodel3[3,2])^2)
rmodel3[3,4]=sum(ifelse(rm3[,10]<0 & rm3[,12]<0.01,1,0))/100
rmodel3[4,1]=sqrt(sum((rm3[,13]-0.10076)^2)/100)
rmodel3[4,2]=mean(rm3[,13])-0.10076
rmodel3[4,3]=sqrt((rmodel3[4,1])^2-(rmodel3[4,2])^2)
rmodel3[4,4]=sum(ifelse(rm3[,13]>0 & rm3[,15]>0.5,1,0))/100
save(rmodel3,file='rm3 result.rdata')





	


	
	
	


















