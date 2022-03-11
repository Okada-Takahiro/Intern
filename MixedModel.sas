*Import;
	%web_drop_table(WORK.D50HZ);
	FILENAME REFFILE '/home/u58594083/sasuser.v71/data50Hz.csv';
	PROC IMPORT DATAFILE=REFFILE
		DBMS=CSV
		OUT=WORK.D50HZ;
		GETNAMES=YES;
	RUN;
	PROC CONTENTS DATA=WORK.D50HZ; RUN;
	%web_open_table(WORK.D50HZ);


*pi,sin;	
	data sincos; set WORK.D50HZ;
		pi=atan(1)*4;
		sin = sin(2*pi*('t.s.'n/0.02));
		cos = cos(2*pi*('t.s.'n/0.02));
		MFD = 'Max_Flux_Density'n*0.1;
	run;


*MIXED1;	
	ods noproctitle;
	ods graphics / imagemap=on;

	proc mixed data=WORK.SINCOS method=ml plots=(residualPanel) plots(maxpoints=none) alpha=0.05 covtest cl asycorr asycov mmeq mmeqsol;
		class Number_Of_Determination Determination_Day;
		model 'N1.I.A.'n= MFD*sin / solution cl alpha=0.05 alphap=0.05 corrb covb ddfm=bw outp=work.Mixed_pred;
		random Intercept / subject=Number_Of_Determination cl alpha=0.05 g gcorr;
		random intercept / subject=Determination_Day solution cl alpha=0.05 g gcorr;
	run;


	ods noproctitle;
	ods graphics / imagemap=on;

	proc mixed data=WORK.SINCOS method=ml plots=(residualPanel) plots(maxpoints=none) alpha=0.05 covtest cl asycorr asycov mmeq mmeqsol;
		class Number_Of_Determination Determination_Day;
		model 'N1.I.A.'n= MFD*sin cos / solution cl alpha=0.05 alphap=0.05 corrb covb ddfm=bw outp=work.Mixed_pred2;
		random Intercept / subject=Number_Of_Determination solution cl alpha=0.05 gcorr;
		random intercept / subject=Determination_Day solution cl alpha=0.05 gcorr;
	run;


ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.MIXED_PRED;
	scatter x='t.s.'n y=Pred / group=MFD;
	scatter x='t.s.'n y='N1.I.A.'n / group=MFD;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;


*MIXED2;
ods noproctitle;
ods graphics / imagemap=on;

proc glmselect data=WORK.SINCOS outdesign(addinputvars)=Work.reg_design;
	class Determination_Day Number_Of_Determination MFD / param=glm;
	model 'N1.I.A.'n=sin*MFD / showpvalues selection=none;
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		rstudentbypredicted observedbypredicted) plots(maxpoints=none);
	where Determination_Day is not missing and Number_Of_Determination is not 
		missing and MFD is not missing;
	ods select DiagnosticsPanel ResidualPlot RStudentByPredicted 
		ObservedByPredicted;
	model 'N1.I.A.'n=&_GLSMOD /;
	output out=work.Reg_stats p=p_ r=r_;
	run;
quit;

proc delete data=Work.reg_design;
run;


ods noproctitle;
ods graphics / imagemap=on;

proc glmselect data=WORK.SINCOS outdesign(addinputvars)=Work.reg_design;
	class Determination_Day Number_Of_Determination MFD / param=glm;
	model 'N1.I.A.'n=sin*MFD cos / showpvalues selection=none;
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		rstudentbypredicted observedbypredicted) plots(maxpoints=none);
	where Determination_Day is not missing and Number_Of_Determination is not 
		missing and MFD is not missing;
	ods select DiagnosticsPanel ResidualPlot RStudentByPredicted 
		ObservedByPredicted;
	model 'N1.I.A.'n=&_GLSMOD /;
	output out=work.Reg_stats2 p=p_ r=r_;
	run;
quit;

proc delete data=Work.reg_design;
run;



ods graphics / reset width=6.4in height=4.8in imagemap;

proc sort data=WORK.REG_STATS out=_SeriesPlotTaskData;
	by MFD 't.s.'n;
run;

proc sgplot data=_SeriesPlotTaskData;
	series x='t.s.'n y='N1.I.A.'n /;
	series x='t.s.'n y='p_'n /;
	xaxis grid;
	yaxis grid;
run;


ods graphics / reset width=6.4in height=4.8in imagemap;

proc sort data=WORK.REG_STATS2 out=_SeriesPlotTaskData;
	by MFD 't.s.'n;
run;

proc sgplot data=_SeriesPlotTaskData;
	series x='t.s.'n y='N1.I.A.'n /;
	series x='t.s.'n y='p_'n /;
	xaxis grid;
	yaxis grid;
run;
