/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 3

/************************************************************************/
libname lab3 "/home/u64574211/sasuser.v94/Lab3";

ods graphics on;
options nodate nonumber;

proc import datafile="/home/u64574211/sasuser.v94/Lab3/lab_3_dataset.csv"
    out=lab3 dbms=csv replace;
    getnames=yes;
run;

/************************************************************************

Is HbA1c different between diabetes groups? (t-test or Wilcoxon)

/************************************************************************/
/* Descriptive Statistic */
title "Descriptive Statistics for HbA1c";

proc means data=lab3 mean median std var min max p25 p75 n nmiss;
    var hba1c;
run;

title "Frequencies for Diabetes";

proc freq data=lab3;
    tables diabetes / missing norow nocol nopercent;
run;

/* Check for Normality */
title "Normality Checks (HbA1c)";

proc univariate data=lab3 normal;
    var hba1c;
    histogram hba1c / normal;
    qqplot hba1c / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;

/* Graphs & Tables */
title "Histogram HbA1c diabetes";

proc sgplot data=lab3;
    histogram hba1c;
    density hba1c / type=normal;
    xaxis label="hba1c";
run;

title "Boxplot of HbA1c by Diabetes";

proc sgplot data=lab3;
    vbox hba1c / category=diabetes;
    xaxis label="Diabetes";
    yaxis label="HbA1c";
run;

/* Test Statistic */
title "Independent Samples t-test: HbA1c by Diabetes";

proc ttest data=lab3 plots(shownull)=interval;
    class diabetes;
    var hba1c;
run;

title "Wilcoxon Rank-Sum Test: HbA1c by Diabetes";

proc npar1way data=lab3 wilcoxon;
    class diabetes;
    var hba1c;
run;
