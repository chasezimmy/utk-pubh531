/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 10

/************************************************************************/
libname lab10 "/home/u64574211/sasuser.v94/Lab10";

ods graphics on;
options nodate nonumber;

/* Copy the provided dataset (hospital.sas7bdat) to lab10.data */
data lab10.data;
    set lab10.hospital;
run;

proc contents data=lab10.data;
run;

/*********************************************
 *1-2) EDA and Data cleaning
 *********************************************/
title "Missingness check";

proc means data=lab10.data n nmiss;
run;

/* Re-code missing exacerbations to 0, create offset */
data lab10.data;
    set lab10.data;
    if missing(exacerbations) then exacerbations=0;
    log_fu=log(followup_time);
run;

title "Frequencies for Sex, Smoking Status, and Disease Severity";

proc freq data=lab10.data;
    tables sex smoker severity / missing norow nocol;
run;

title "Frequencies for Hospital Event";

proc freq data=lab10.data;
    tables hospital_event / missing norow nocol;
run;

title "Frequencies for Exacerbations";

proc freq data=lab10.data;
    tables exacerbations / missing norow nocol;
run;

title "Distribution of Exacerbations";

proc sgplot data=lab10.data;
    histogram exacerbations;
    density exacerbations;
run;

title "Normality Checks (Age)";

proc univariate data=lab10.data normal;
    var age;
    histogram age / normal;
    qqplot age / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Normality Checks (Follow-up Time)";

proc univariate data=lab10.data normal;
    var followup_time;
    histogram followup_time / normal;
    qqplot followup_time / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Normality Checks (Hospital Time)";

proc univariate data=lab10.data normal;
    var hospital_time;
    histogram hospital_time / normal;
    qqplot hospital_time / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Exacerbations: Mean vs. Variance";

proc means data=lab10.data n mean var std min max;
    var exacerbations;
run;

title "Hospitalization Time by Event Status";

proc means data=lab10.data n mean median min max;
    class hospital_event;
    var hospital_time;
run;

title "Time to First Hospitalization";

proc lifetest data=lab10.data plots=survival;
    time hospital_time*hospital_event(0);
run;
title;

/*********************************************
 *3) Poisson Regression (With and Without Offset)
 *********************************************/

*3.1 Bivariable Poisson Models;
proc genmod data=lab10.data;
    class sex(ref='0');
    model exacerbations=sex / dist=poisson link=log;
    title "Poisson: exacerbations ~ sex";
run;

proc genmod data=lab10.data;
    class smoker(ref='0');
    model exacerbations=smoker / dist=poisson link=log;
    title "Poisson: exacerbations ~ smoker";
run;

proc genmod data=lab10.data;
    class severity(ref='1');
    model exacerbations=severity / dist=poisson link=log;
    title "Poisson: exacerbations ~ severity";
run;

/** fails to converge, no good fit **/
proc genmod data=lab10.data;
    model exacerbations=age / dist=poisson link=log;
    title "Poisson: exacerbations ~ age";
run;

*3.2 Multiple Poisson Model (No Offset);
proc genmod data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model exacerbations=age sex smoker severity / dist=poisson link=log type3;
    ods output ParameterEstimates=pois_parms;
    title "Multiple Poisson (no offset)";
run;

/* Convert 3.2 coefficients to IRR = exp(beta) */
data pois_irrs;
    set pois_parms;
    where Parameter ne 'Scale';
    IRR=exp(Estimate);
    LCL=exp(LowerWaldCL);
    UCL=exp(UpperWaldCL);
run;

proc print data=pois_irrs label noobs;
    var Parameter Level1 Estimate IRR LCL UCL;
    label IRR='Incidence Rate Ratio' LCL='LCL (95%)' UCL='UCL (95%)';
    title "Poisson IRRs (no offset)";
run;

*3.3 Multiple Poisson Model (With Offset);
proc genmod data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model exacerbations=age sex smoker severity / dist=poisson link=log
        offset=log_fu type3;
    ods output ParameterEstimates=pois_parms_offset;
    title "Multiple Poisson (with offset)";
run;

/* Convert 3.3 coefficients to IRR = exp(beta) */
data pois_off_irrs;
    set pois_parms_offset;
    where Parameter ne 'Scale';
    IRR=exp(Estimate);
    LCL=exp(LowerWaldCL);
    UCL=exp(UpperWaldCL);
run;

proc print data=pois_off_irrs label noobs;
    var Parameter Level1 Estimate IRR LCL UCL;
    label IRR='Incidence Rate Ratio' LCL='LCL (95%)' UCL='UCL (95%)';
    title "Poisson IRRs (with offset)";
run;
title;

/*********************************************
4) Overdispersion Checks and Negative Binomial
 *********************************************/
*4.1 Overdispersion Diagnostics (Poisson);

/* Get model deviance and Pearson chi-square; check value/df > ~1.5 as a quick flag */
proc genmod data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model exacerbations=age sex smoker severity / dist=poisson link=log
        offset=log_fu;
    output out=pois_out resdev=devres reschi=pearres pred=muhat;
    title "Poisson Fit for Dispersion Diagnostics";
run;

proc means data=pois_out mean;
    var devres pearres;
    title "Residuals (mean should be ~0)";
run;

proc sgplot data=pois_out;
    scatter x=muhat y=pearres / transparency=0.4;
    refline 0 / axis=y;
    title "Pearson Residuals vs Fitted (Look for pattern/spread)";
run;
title;

*4.2 Negative Binomial (NB) Model;
proc genmod data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model exacerbations=age sex smoker severity / dist=negbin link=log
        offset=log_fu type3;
    ods output ParameterEstimates=nb_parms ModelFit=nb_fit;
    title "Negative Binomial with Offset";
run;

/* Convert NB coefficients to IRR = exp(beta) */
data nb_irrs;
    set nb_parms;
    IRR=exp(Estimate);
    LCL=exp(LowerWaldCL);
    UCL=exp(UpperWaldCL);
run;

proc print data=nb_irrs label noobs;
    var Parameter Level1 Estimate IRR LCL UCL;
    label IRR='Incidence Rate Ratio' LCL='LCL (95%)' UCL='UCL (95%)';
    title "Negative Binomial IRRs";
run;
title;

/*********************************************
5) Survival Analysis: Cox Proportional Hazards
 *********************************************/

*5.1 Kaplan-Meier (KM) Curves;
proc lifetest data=lab10.data plots=survival(atrisk);
    time hospital_time*hospital_event(0);
    strata smoker;
    title "Kaplan-Meier by Smoking Status";
run;

proc lifetest data=lab10.data plots=survival(atrisk);
    time hospital_time*hospital_event(0);
    strata severity;
    title "Kaplan-Meier by Disease Severity";
run;

*5.2 Basic Cox Model + Hazard Ratios;
proc phreg data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model hospital_time*hospital_event(0)=age sex smoker severity / ties=efron;
    title "Cox Proportional Hazards: age, sex, smoker, severity";
run;

*5.3 Proportional Hazards (PH) Diagnostics;
* Don't forget what the three main assumptions are for the Cox Model:
1. Proportional Hazard Assumption
2. Detecting non-linearity in relationships
3. Handling of outliers;
/* Schoenfeld residual plots and global test to test the PH assumption */
ods graphics on;

proc phreg data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model hospital_time*hospital_event(0)=age sex smoker severity / ties=efron;
    assess ph / resample; /* tests PH; resample option for stability */
    title "PH Assumption Diagnostics (Schoenfeld)";
run;

ods graphics on;

proc phreg data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model hospital_time*hospital_event(0)=age sex smoker severity / ties=efron;

    hazardratio age;
    hazardratio sex;
    hazardratio smoker;
    hazardratio severity;

    assess ph / resample;
    title "PH Assumption Diagnostics (Schoenfeld)";
run;

/* Martingale residuals (functional form check for continuous covariates) */
proc phreg data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    /* Including so categorical variables aren't treated as continuous */
    model hospital_time*hospital_event(0)=age sex smoker severity / ties=efron;
    output out=phresids resmart=martingale;
    title "Martingale Residuals Output for assessment of linearity";
run;

proc sgplot data=phresids;
    scatter x=age y=martingale / transparency=0.4;
    loess x=age y=martingale / nomarkers;
    refline 0 / axis=y;
    title "Martingale Residuals vs Age (Check functional form)";
run;

/* Influence diagnostics (DFBETAs) */
proc phreg data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model hospital_time*hospital_event(0)=age sex smoker severity;
    output out=dfbeta dfbeta=dfage;
    id id;
    title "Influence Diagnostics: DFBETAs";
run;

proc sgplot data=dfbeta;
    scatter x=age y=dfage;
run;
title;

*5.4 Optional: Stratified Cox or Time-Varying Effect;

/* Stratified by sex (baseline hazard differs by sex so different assumed baseline hazards, an adjustment in a way) */
proc phreg data=lab10.data;
    class smoker(ref='0') severity(ref='1');
    strata sex;
    model hospital_time*hospital_event(0)=age smoker severity;
    title "Stratified Cox by Sex";
run;

proc phreg data=lab10.data;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model hospital_time*hospital_event(0)=age smoker severity / ties=efron;
    title "Cox Proportional Hazards: age, smoker, severity (no sex)";
run;

/* Time-varying effect for smoking (illustrative using interaction with log(time)) */
data time_tv;
    set lab10.data;
    lntime=log(hospital_time);
run;

proc phreg data=time_tv;
    class sex(ref='0') smoker(ref='0') severity(ref='1');
    model hospital_time*hospital_event(0)=age sex smoker severity smoker*lntime;
    title "Cox with Time-Varying Smoking Effect (smoker x log(time))";
run;
title;
