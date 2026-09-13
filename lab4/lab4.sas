/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 4

/************************************************************************/
libname lab4 "/home/u64574211/sasuser.v94/Lab4";

ods graphics on;
options nodate nonumber;

libname demo xport "/home/u64574211/sasuser.v94/Lab4/DEMO_L.xpt";
libname bmx xport "/home/u64574211/sasuser.v94/Lab4/BMX_L.xpt";
libname mcq xport "/home/u64574211/sasuser.v94/Lab4/MCQ_L.xpt";
libname bpxo xport "/home/u64574211/sasuser.v94/Lab4/BPXO_L.xpt";

/* Copy xport data into lab4 */
proc copy in=demo out=lab4;
run;

proc copy in=bmx out=lab4;
run;

proc copy in=mcq out=lab4;
run;

proc copy in=bpxo out=lab4;
run;

/************************************************************************

Initial data clean-up

/************************************************************************/

/* Sorts dataset copies in-place, over-writing .sas7bdat copies, not the .xpt files */
proc sort data=lab4.demo_l;
    by seqn;
run;

proc sort data=lab4.bmx_l;
    by seqn;
run;

proc sort data=lab4.mcq_l;
    by seqn;
run;

proc sort data=lab4.bpxo_l;
    by seqn;
run;

/* Merge datasets on seqn to lab4.merged */
data lab4.merged;
    merge lab4.demo_l lab4.bpxo_l lab4.bmx_l lab4.mcq_l;
    by seqn;
run;

/* Filter dataset to research question criteria */
data lab4.merged;
    set lab4.merged;
    where ridageyr > 17;
run;

/* Initial Descriptive Statistic */
title
    "Initial Descriptive Statistics for Diastolic Blood Pressure (BPXODI), Age (RIDAGEYR), and Body Mass Index (BMXBMI)";

proc means data=lab4.merged n mean std min p25 median p75 max;
    var bpxodi1 ridageyr bmxbmi;
run;

title "Initial Frequencies for Asthma Attack in Past Year (MCQ040)";

proc freq data=lab4.merged;
    tables mcq040 / missing norow nocol nopercent;
run;

/* Adjust dataset for NHANES top-coding */
data lab4.dataset;
    set lab4.merged;
    if 18 <= ridageyr < 80; /* NHANES ceils age at 80 */
run;

/* Re-code MCQ040 */
data lab4.dataset;
    set lab4.dataset;
    if mcq040=1 then mcq040=1; /* had an attack */
    else if mcq040=2 then mcq040=0; /* has asthma, no attack */
    else if mcq040 in (7, 9) then mcq040=.;
    /* refused / don't know -> missing */
    else mcq040=.;
run;

/************************************************************************

Research Questions:

Is age (RIDAGEYR) associated with diastolic blood pressure (BPXODI) among adults,
after adjusting for BMI (BMXBMI) and whether or not they had an asthma attack in the past year (MCQ040)?

/************************************************************************/
/* Descriptive Statistic */
title
    "Descriptive Statistics for Diastolic Blood Pressure (BPXODI), Age (RIDAGEYR), and Body Mass Index (BMXBMI)";

proc means data=lab4.dataset n mean std min p25 median p75 max;
    var bpxodi1 ridageyr bmxbmi;
run;

title "Frequencies for Asthma Attack in Past Year (MCQ040)";

proc freq data=lab4.dataset;
    tables mcq040 / missing norow nocol nopercent;
run;

/* Graphs & Tables */
title "Histogram + Density (BPXODI)";

proc sgplot data=lab4.dataset;
    histogram bpxodi1;
    density bpxodi1;
run;
title "Histogram + Density (RIDAGEYR)";

proc sgplot data=lab4.dataset;
    histogram ridageyr;
    density ridageyr;
run;
title "Histogram + Density (BMXBMI)";

proc sgplot data=lab4.dataset;
    histogram bmxbmi;
    density bmxbmi;
run;

title "Box plot (BPXODI)";

proc sgplot data=lab4.dataset;
    vbox bpxodi1;
run;

title "Box plot (RIDAGEYR)";

proc sgplot data=lab4.dataset;
    vbox ridageyr;
run;

title "Box plot (BMXBMI)";

proc sgplot data=lab4.dataset;
    vbox bmxbmi;
run;

/* Simple linear regression */
title "Simple linear regression (BPXODI1 by RIDAGEYR)";

proc reg data=lab4.dataset plots(maxpoints=100000);
    model bpxodi1=ridageyr;
    run;
quit;

/* Diagnostic & Linear Regression Assumptions */
title "Scatter (BPXODI1 by RIDAGEYR)";

proc sgplot data=lab4.dataset;
    scatter x=ridageyr y=bpxodi1;
    reg x=ridageyr y=bpxodi1 / clm;
run;

title "Scatter (BPXODI1 by BMXBMI)";

proc sgplot data=lab4.dataset;
    scatter x=bmxbmi y=bpxodi1;
    reg x=bmxbmi y=bpxodi1 / clm;
run;

title "Scatter (BPXODI1 by MCQ040)";

proc sgplot data=lab4.dataset;
    scatter x=mcq040 y=bpxodi1;
    reg x=mcq040 y=bpxodi1 / clm;
run;

title "Correlation matrix - linearity check";

proc corr data=lab4.dataset plots(maxpoints=100000)=matrix;
    var bpxodi1 ridageyr bmxbmi;
run;

title "Correlation matrix - linearity check";

proc corr data=lab4.dataset plots;
    var bpxodi1 ridageyr bmxbmi;
run;

title "Regression";

proc reg data=lab4.dataset plots(maxpoints=100000)=diagnostics(unpack);
    model bpxodi1=ridageyr bmxbmi mcq040;
    output out=work.res_s p=pred_s r=res_s rstudent=rstud_s cookd=cookd_s
        h=lev_s;
    run;
quit;

/* Residual */
title "Residual Normality";

proc univariate data=work.res_s normal;
    var res_s;
    histogram res_s / normal;
    qqplot res_s / normal(mu=est sigma=est);
run;

title "Residuals vs predicted";

proc sgplot data=work.res_s;
    scatter x=pred_s y=res_s;
    refline 0 / axis=y;
run;

/* Collinearity Check */
title "Collinearity";

proc reg data=lab4.dataset;
    model bpxodi1=ridageyr bmxbmi mcq040 / vif collin tol;
    output out=work.res_m p=pred_m r=res_m rstudent=rstud_m cookd=cookd_m
        h=lev_m;
    run;
quit;

/* Inspect top potential influential points */
proc sort data=work.res_m out=work.top_infl;
    by descending cookd_m;
run;

proc print data=work.top_infl(obs=10);
    var bpxodi1 ridageyr bmxbmi mcq040 pred_m res_m rstud_m cookd_m lev_m;
run;
