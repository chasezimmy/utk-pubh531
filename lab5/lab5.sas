/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 5

/************************************************************************/
libname lab5 "/home/u64574211/sasuser.v94/Lab5";

ods graphics on;
options nodate nonumber;

proc import
    datafile="/home/u64574211/sasuser.v94/Lab5/health_behavior_round2.csv"
    out=lab5 dbms=csv replace;
    getnames=yes;
    guessingrows=max;
run;

proc format;
    value sexfmt 1='Male' 0='Female';
    value smokefmt 1='Current smoker' 0='Non-smoker';
    value exfmt 1='Exercises regularly' 0='Does not exercise regularly';
    value diabetesfmt 1='Positive diabetes screen' 0='Negative Diabetes Screen';
    value bpfmt 1='High BP' 0='Normal BP';
run;

data lab5;
    set lab5;
    format sex sexfmt. smoke smokefmt. exercise exfmt. outcome diabetesfmt.
        bp_high bpfmt.;
    label outcome='Positive diabetes screen';
run;

/*

Research Question:

Among adults in Wave 2 of the Health Behavior Study,
what behavioral and clinical factors including smoking status (smoke), age (age), exercise (excercise), and high blood pressure (bp_high)
predict screening positive for a cardiometabolic condition (outcome)?

 */
/* PART 1: EDA/Descriptives run the appropriate univariable descriptive statistics to assess center and spread of all variables.*/
title "Descriptive Statistics for Age";

proc means data=lab5 n mean std min p25 median p75 max;
    var age;
run;

title
    "Frequencies for Sex, Smoking Status, Exercise, High Blood Pressure, and Diabetes";

proc freq data=lab5;
    tables sex smoke exercise bp_high outcome / missing;
run;

title "Normality Checks (Age)";

proc univariate data=lab5 normal;
    var age;
    histogram age / normal;
    qqplot age / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

title "Boxplot of Age by Diabetes";

proc sgplot data=lab5;
    vbox age / category=outcome;
    xaxis label="Diabetes";
    yaxis label="Age";
run;

title "Histogram for Age by Diabetes";

proc sgpanel data=lab5;
    panelby outcome / rows=2;
    histogram age;
run;
title;

/* PART 1 (continued): Table 1 - Characteristics of cases vs. controls */
/* Age by outcome: group means/SDs + t-test (with normality/variance checks) */
title "Table 1: Age by Diabetes Screen Status (t-test)";

proc ttest data=lab5;
    class outcome;
    var age;
run;

/* Categorical predictors by outcome: n (%) + chi-square */
title "Table 1: Categorical Predictors by Diabetes Screen";

proc freq data=lab5;
    tables (sex smoke exercise bp_high)*outcome / chisq nocol nopercent;
run;

/* PART 2: Crude model Use proc logistic to examine each of the potential predictors of cardiometabolic condition separately.) */
proc logistic data=lab5 descending;
    model outcome=smoke;
    title "Crude Logistic Regression: Smoking Status and Diabetes Screen";
run;

proc logistic data=lab5 descending;
    model outcome=age;
    title "Crude Logistic Regression: Age and Diabetes Screen";
run;

proc logistic data=lab5 descending;
    model outcome=exercise;
    title "Crude Logistic Regression: Exercise and Diabetes Screen";
run;

proc logistic data=lab5 descending;
    model outcome=bp_high;
    title "Crude Logistic Regression: High Blood Pressure and Diabetes Screen";
run;

/* PART 3: Adjusted model consider which variables should remain in multivariable model. */
proc logistic data=lab5 descending;
    format outcome smoke exercise bp_high;
    class smoke(ref='0') bp_high(ref='0') exercise(ref='1') / param=ref;
    model outcome=smoke age bp_high exercise;
    title "Adjusted Logistic Regression Model - Descending";
run;

/* PART 4: Hosmer-Lemeshow Model Goodness of Fit Assessment */
proc logistic data=lab5 descending;
    format outcome smoke exercise bp_high;
    class smoke(ref='0') bp_high(ref='0') exercise(ref='1') / param=ref;
    model outcome=smoke age bp_high exercise / lackfit;
    title "Model Fit Statistics and Hosmer-Lemeshow Test";
run;

/* Model Diagnostics: Influential observations check */
proc logistic data=lab5 descending plots(only)=(influence dfbetas);
    format outcome smoke exercise bp_high;
    class smoke(ref='0') bp_high(ref='0') exercise(ref='1') / param=ref;
    model outcome=smoke age bp_high exercise;
    title "Model Diagnostics: Influence";
run;

/* Model Diagnostics: Linearity of the logit for age (Box-Tidwell) */
data lab5_bt;
    set lab5;
    age_ln=log(age);
    age_bt=age * age_ln;
run;

proc logistic data=lab5_bt descending;
    format outcome smoke exercise bp_high;
    class smoke(ref='0') bp_high(ref='0') exercise(ref='1') / param=ref;
    model outcome(event='1')=smoke age age_bt bp_high exercise;
    title "Linearity of the Logit (Box-Tidwell): Age";
run;

/* Model Diagnostics: Multicollinearity (VIF) */
title "Multicollinearity Check: Variance Inflation Factors";

proc reg data=lab5;
    model outcome=smoke age bp_high exercise / vif tol collin;
    run;
quit;

/* PART 5: ROC & AUC Examination */
proc logistic data=lab5 descending plots(only)=roc;
    format outcome smoke exercise bp_high;
    class smoke(ref='0') bp_high(ref='0') exercise(ref='1') / param=ref;
    model outcome=smoke age bp_high exercise;
    title "ROC Curve and AUC (c-statistic) Examination";
run;

/* PART 6: Predicted probabilities plot */
proc logistic data=lab5 descending plots(only)=effect;
    format outcome smoke exercise bp_high;
    class smoke(ref='0') bp_high(ref='0') exercise(ref='1') / param=ref;
    model outcome=smoke age bp_high exercise;
    title "Predicted Probability of Positive Diabetes Screen by Age";
run;
