

/***********************************************************/
/*                                                         */
/*	M4 - Linear Regression SAS Lesson					   */
/*                                                         */
/*	Research question: Is age associated with systolic     */
/*			           blood pressure (SBP) among adults,  */
/*			           after adjusting for BMI and sex?    */
/*                                                         */
/*  Data Source: NHANES 2021-2023 Cycle Data               */
/*	Data files: DEMO_L, BMX_L, MCQ_L					   */
/*  Data format: .xpt SAS transport files                  */
/*                                                         */
/***********************************************************/


/***********************************************************/
*1. SAS Data import;
/***********************************************************/

/* Assign a library to the folder where you want the SAS dataset saved */
libname mydata 
	"C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 4\NHANES";

/* Assign a library to the XPORT file using the XPORT engine */
libname xptfile xport 
	"C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 4\NHANES\Demo_l.xpt" access=readonly;

/* Copy all datasets from the XPORT file into the SAS library */
proc copy inlib=xptfile outlib=work;
run;

/* Clear the libnames */
libname xptfile clear;
libname mydata clear;

/* Assign a library to the folder where you want the SAS dataset saved */
libname mydata 
	"C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 4\NHANES";

/* Assign a library to the XPORT file using the XPORT engine */
libname xptfile xport 
	"C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 4\NHANES\BMX_l.xpt" access=readonly;

/* Copy all datasets from the XPORT file into the SAS library */
proc copy inlib=xptfile outlib=work;
run;

/* Clear the libnames */
libname xptfile clear;
libname mydata clear;

/* Assign a library to the folder where you want the SAS dataset saved */
libname mydata 
	"C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 4\NHANES";

/* Assign a library to the XPORT file using the XPORT engine */
libname xptfile xport 
	"C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 4\NHANES\MCQ_l.xpt" access=readonly;

/* Copy all datasets from the XPORT file into the SAS library */
proc copy inlib=xptfile outlib=work;
run;

/* Clear the libnames */
libname xptfile clear;
libname mydata clear;

/***********************************************************/
*1. Merge Data sets;
/***********************************************************/

* Sort the data by SEQN with a Proc Sort;
proc sort data=demo_l;
	by seqn;
proc sort data=bmx_l;
	by seqn;
proc sort data=mcq_l;
	by seqn;
run;

data m4_lesson;
	merge demo_l bmx_l mcq_l;
	by seqn;
run;

*Check the merged data. Examine the log and make sure the number of variables and observations across the three
data sets match;

*Look at the contents;
proc contents data=m4_lesson varnum;
run;

* Research question reminder: Is age associated with systolic blood pressure (SBP) among adults, after adjusting for BMI
and sex?;

/* Explore the variables. */

*Variables to explore SBP, age, BMI, sex;

*explore categorical variables;
proc freq data=m4_lesson;
table sex;
run;

proc freq data=m4_lesson;
table RIAGENDR;
run;

*Explore continuous variables;

proc means data=m4_lesson n mean std min p25 median p75 max; 
var SBP age BMI;
run;
* Let's find the varible names for SBP, age and BMI;
* Age is RIDAGEYR, BMI is BMXBMI;
* Can you find SBP?
*






* Uh oh! We need to go back to NHANES for the examination dataset;
* There is an altenate way to get the NHANES datafiles into SAS;
/* Define the URL filename */

filename BPXO_L url "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/BPXO_L.xpt" ;
libname  BPXO_L xport;

proc copy inlib=BPXO_L out=work;
run;

/* Clean up (optional) */
libname BPXO_L clear;
filename BPXO_L clear;

/* Check what you got */
proc contents data=work.BPXO_L; run;

*Merge in the new data;

proc sort data=BPXO_L;
BY seqn;
data m4_lesson;
merge M4_lesson bpxo_l;
by seqn;
run;

proc print data=m4_lesson (obs=10);
run;

proc sort data=BPXO_L;
BY seqn;
data m4_lesson;
merge M4_lesson bpxo_l (in=a);
by seqn;
if a;
run;

*Run the proc print again;
*Look at the output;

data m4_lesson;
set m4_lesson;
where ridageyr >=18;
run;

*Run proc print again or proc means or univariate to check that the age restriction worked;

Proc means data=m4_lesson;
var ridageyr;
run;
/**** Back to the research quesiton */

/* Exploratory Data Analysis (EDA)*/
proc means data=m4_lesson n mean std min p25 median p75 max; 
var SBP age BMI;
run;
proc means data=m4_lesson n mean std min p25 median p75 max; 
var BPXOSY1 ridageyr BMXBMI;
run;

proc univariate data=m4_lesson plot;
var BPXOSY1 ridageyr BMXBMI;
run;



/* HISTOGRAMS + DENSITY */ 

proc sgplot data=m4_lesson; 
histogram ridageyr; 
density ridageyr; 
run; 
proc sgplot data=m4_lesson; 
histogram bpxosy1; 
density bpxosy1;
run; 

proc sgplot data=m4_lesson; 
histogram bmxbmi; 
density bmxbmi; 
run; 

/* BOX PLOTS */ 
proc sgplot data=m4_lesson; 
vbox bpxosy1; 
run; 
proc sgplot data=m4_lesson; 
vbox ridageyr; 
run; 

proc sgplot data=m4_lesson; 
vbox bmxbmi; 
run; 

/* SCATTER WITH FITTED LINE */ 
proc sgplot data=m4_lesson; 
scatter x=ridageyr y=bpxosy1; 
reg x=ridageyr y=bpxosy1 / cli; 
run;

PROC CORR DATA=m4_lesson PLOTS(maxpoints=100000)=MATRIX;
VAR bpxosy1 ridageyr bmxbmi;
RUN;
quit;

PROC CORR DATA=m4_lesson PLOTS;
VAR bpxosy1 ridageyr bmxbmi;
RUN;
quit;
/***********************************************************************************************************/
/*		Linear Regression Assumptions                                                                      */
/*		1. Linearity: Scatter of residuals vs fitted shows no strong curvature; scatter of Y vs X looks    */
/*			approximately linear.                                                                          */
/*		2. Homoscedasticity: Residuals have roughly constant spread across fitted values (no funnel shape).*/
/*		3. Independence: Observations are independent (check design; no clustering unless modeled).        */
/*		4. Normality of residuals: Residual histogram and Q–Q plot are approximately normal; Shapiro–Wilk  */
/*			acceptable for large N via CLT.                                                                */
/***********************************************************************************************************/


/* SIMPLE MODEL for diagnostics */ 
proc reg data=m4_lesson plots=diagnostics(unpack);
model bpxosy1 = ridageyr; output out=work.res_s p=pred_s r=res_s rstudent=rstud_s cookd=cookd_s
h=lev_s; 
run; 
quit; 

proc reg data=m4_lesson plots=diagnostics(unpack) plots(maxpoints=100000);
model bpxosy1 = ridageyr; output out=work.res_s p=pred_s r=res_s rstudent=rstud_s cookd=cookd_s
h=lev_s; 
run; 
quit; 

/* Residual normality */ 
proc univariate data=work.res_s normal; 
var res_s; 
histogram res_s / normal; 
qqplot res_s / normal(mu=est sigma=est); 
run; 

/*Residuals vs predicted */ 
proc sgplot data=work.res_s; 
scatter x=pred_s y=res_s; 
refline 0 / axis=y; 
run;


/*  Modeling - Fit a simple model, then an adjusted model.*/

/* Simple linear regression */ 
proc reg data=M4_lesson; 
model bpxosy1 = ridageyr; 
run; 
quit;

/* Multiple linear regression (adjusted) */ 
proc reg data=M4_lesson; 
model bpxosy1 = ridageyr bmxbmi riagendr; 
run; 
quit;


/* Influence & Collinearity*/
/* Influence metrics from multiple model */ 

proc reg data=M4_lesson; 
model bpxosy1 = ridageyr bmxbmi riagendr / vif collin tol; 
output out=work.res_m p=pred_m r=res_m rstudent=rstud_m cookd=cookd_m h=lev_m; 
run; 
quit; 

/* Inspect top potential influential points */ 
proc sort data=work.res_m out=work.top_infl; 
by descending cookd_m; 
run; 

proc print data=work.top_infl (obs=10); 
var bpxosy1 ridageyr bmxbmi riagendr pred_m res_m rstud_m cookd_m lev_m; 
run;

*Go back to the module for examples of how to write up your conclusions;
