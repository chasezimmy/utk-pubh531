/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 14

/************************************************************************/
libname lab14 "/home/u64574211/sasuser.v94/Lab14";

ods graphics on;
options nodate nonumber;

/*============================================================================
Part A - B
============================================================================*/
title "Missingness Checks (Categorical)";

proc freq data=lab14.lab_mi;
    tables sex smoker outcome / missing norow nocol;
run;

title "Missingness Checks (Continuous)";

proc means data=lab14.lab_mi n nmiss mean std min max;
    var age bmi sbp;
run;

title "Missingness Checks Age by Sex and Smoking Status";

proc means data=lab14.lab_mi n nmiss missing;
    class sex smoker;
    var age;
run;

title "Missingness BMI by Sex and Smoking Status";

proc means data=lab14.lab_mi n nmiss missing mean std min max;
    class sex smoker;
    var bmi;
run;

proc format;
    value bmi30f .='Missing' low - 30='<= 30' 30 <- high='> 30';
run;

title "Missingness BMI >30";

proc freq data=lab14.lab_mi;
    tables bmi / missing;
    format bmi bmi30f.;
run;

title "Missingness SBP by Sex and Smoking Status";

proc means data=lab14.lab_mi n nmiss missing;
    class sex smoker ;
    var sbp;
run;

title "Normality Checks (Age)";

proc univariate data=lab14.lab_mi normal;
    var age;
    histogram age / normal;
    qqplot age / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Normality Checks (BMI)";

proc univariate data=lab14.lab_mi normal;
    var bmi;
    histogram bmi / normal;
    qqplot bmi / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Normality Checks (SBP)";

proc univariate data=lab14.lab_mi normal;
    var sbp;
    histogram sbp / normal;
    qqplot sbp / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Monotone check";

proc mi data=lab14.lab_mi nimpute=0;
    var age bmi sbp;
run;

/*============================================================================
Part C
============================================================================*/

/* Step 1: Imputation (Part B settings) */
proc mi data=lab14.lab_mi nimpute=25 seed=20261121 out=mi_out;
    class sex smoker outcome;
    var sex smoker outcome age bmi sbp;
    fcs reg(age bmi sbp);
run;

/* Step 2: Logistic regression fitted separately in each imputed dataset */
ods exclude all; /* hide printed output */
title "Logistic Regression by Imputation";

proc logistic data=mi_out;
    by _imputation_;
    model outcome(event='1')=age sex bmi sbp smoker;
    ods output ParameterEstimates=lgsparms;
run;
ods exclude none; /* turn printing back on */
title "Model Fits per Imputation";

proc freq data=lgsparms;
    tables _imputation_ / nocum nopercent;
run;

title "Logistic Estimates, Imputations 1–3";

proc print data=lgsparms noobs;
    where _imputation_ <= 3;
    var _imputation_ Variable Estimate StdErr ProbChiSq;
run;

/*============================================================================
Part D
============================================================================*/
title "Pooled Logistic Regression Estimates";

proc mianalyze parms=lgsparms;
    modeleffects Intercept age sex bmi sbp smoker;
    ods output ParameterEstimates=pooled;
run;

/* Convert pooled estimates to odds ratios */
data pooled_or;
    set pooled;
    OR=exp(Estimate);
    OR_LCL=exp(LCLMean);
    OR_UCL=exp(UCLMean);
run;

title "Pooled Odds Ratios (95% CI)";

proc print data=pooled_or noobs;
    where Parm ne 'Intercept';
    var Parm Estimate StdErr OR OR_LCL OR_UCL Probt;
    format OR OR_LCL OR_UCL 8.3 Probt pvalue6.4;
run;

/*============================================================================
Part E
============================================================================*/
title "Complete Case Logistic Regression";

proc logistic data=lab14.lab_mi;
    model outcome(event='1')=age sex bmi sbp smoker / clodds=wald;
run;
