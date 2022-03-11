*Import;
	%web_drop_table(WORK.D010);
	FILENAME REFFILE '/home/u58594083/sasuser.v73/data010.csv';
	PROC IMPORT DATAFILE=REFFILE
		DBMS=CSV
		OUT=WORK.D010;
		GETNAMES=YES;
	RUN;
	PROC CONTENTS DATA=WORK.D010; RUN;
	%web_open_table(WORK.D010);
	

*pi,sin;	
	data sincos; set WORK.D010;
		pi=atan(1)*4;
		sin = sin(2*pi*('t.s.'n/0.02));
		cos = cos(2*pi*('t.s.'n/0.02));
		MFD = 'Max_Flux_Density'n*0.1;
	run;


*MIXED;
	ods noproctitle;
	ods graphics / imagemap=on;

	proc mixed data=WORK.SINCOS method=ml noclprint noitprint covtest plots(maxpoints=none);
		class Number_Of_Determination Determination_Day;
		model 'N1.I.A.'n= Max_Flux_Density*sin / solution ddfm=bw outp=work.Mixed_pred;
		random Intercept / subject=Number_Of_Determination gcorr;
		random intercept / subject=Determination_Day gcorr;
	run;
	

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sort data=WORK.MIXED_PRED out=_SeriesPlotTaskData;
	by 't.s.'n;
run;

proc sgplot data=_SeriesPlotTaskData;
	series x='t.s.'n y='N1.I.A.'n /;
	series x='t.s.'n y=Pred /;	
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _SeriesPlotTaskData;
	run;


*MIXED2;
	ods noproctitle;
	ods graphics / imagemap=on;
	proc mixed data=WORK.SINCOS method=ml noclprint noitprint covtest plots(maxpoints=none);
		class Number_Of_Determination Determination_Day;
		model 'N1.I.A.'n= Max_Flux_Density*sin cos / solution ddfm=bw outp=work.Mixed_pred2;
		random Intercept / subject=Number_Of_Determination gcorr;
		random intercept / subject=Determination_Day gcorr;
	run;
	

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sort data=WORK.MIXED_PRED2 out=_SeriesPlotTaskData;
	by 't.s.'n;
run;

proc sgplot data=_SeriesPlotTaskData;
	series x='t.s.'n y='N1.I.A.'n /;
	series x='t.s.'n y=Pred /;	
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _SeriesPlotTaskData;
	run;



*MIXED3;
	ods noproctitle;
	ods graphics / imagemap=on;
	ods output CovParms = cov3;
	proc mixed data=WORK.SINCOS method=reml plots=(residualPanel) alpha=0.05 plots(maxpoints=500000) cl asycorr asycov mmeq mmeqsol;
		class Determination_Day Number_Of_Determination Max_Flux_Density;
		model 'N1.I.A.'n=sin*Max_Flux_Density cos / solution cl alpha=0.05 alphap=0.05 corrb covb influence;
		random Intercept / subject=Number_Of_Determination gcorr;
		random intercept / subject=Determination_Day gcorr;
	run;
	
	data icc;
		set cov3 end=last;
		retain bvar;
		if subject~="" then bvar = estimate;
		if last then icc = bvar/(bvar+estimate);
	run;
	
	proc print data = icc;
	run;


ods noproctitle;
ods graphics / imagemap=on;

proc glmselect data=WORK.SINCOS outdesign(addinputvars)=Work.reg_design;
	class Max_Flux_Density Determination_Day Number_Of_Determination / param=glm;
	model 'N1.I.A.'n=sin*Max_Flux_Density / showpvalues selection=none;
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted) plots(maxpoints=500000);
	where Max_Flux_Density is not missing and Determination_Day is not missing and 
		Number_Of_Determination is not missing;
	ods select DiagnosticsPanel ResidualPlot ObservedByPredicted;
	model 'N1.I.A.'n=&_GLSMOD /;
	run;
quit;

proc delete data=Work.reg_design;
run;
