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

1. Is HbA1c different between diabetes groups? (t-test or Wilcoxon)

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

title "Histogram for HbA1c by Diabetes";

proc sgpanel data=lab3;
    panelby diabetes / rows=2;
    histogram hba1c;
run;
title;

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

/************************************************************************

2. Is resting heart rate different across physical activity levels? (ANOVA or Kruskal–Wallis)

/************************************************************************/
/* Descriptive Statistic */
title "Descriptive Statistics for Resting Heart Rate";

proc means data=lab3 mean median std var min max p25 p75 n nmiss;
    var resting_hr;
run;

title "Frequencies for Activity Levels";

proc freq data=lab3;
    tables physical_activity / missing norow nocol nopercent;
run;

/* Check for Normality */
title "Normality Checks (Resting Heart Rate)";

proc univariate data=lab3 normal;
    var resting_hr;
    histogram resting_hr / normal;
    qqplot resting_hr / normal(mu=est sigma=est);
    inset n mean std median p25 p75 / position=ne;
run;
/* Graphs & Tables */
title "Histogram of Resting Heart Rate";

proc sgplot data=lab3;
    histogram resting_hr;
    density resting_hr / type=normal;
    xaxis label="Resting Heart Rate";
run;

title "Bar Chart of Activity Levels";

proc sgplot data=lab3;
    vbar physical_activity;
run;
/* Test Statistic */
Title 'One-Way ANOVA comparing mean Resting Heart Rate across Activity Levels';

proc glm data=lab3 plots=diagnostics(unpack);
    class physical_activity;
    model resting_hr=physical_activity;
    means physical_activity/ hovtest=levene;
    lsmeans physical_activity / adjust=tukey cl;
    run;
quit;

Title
    'Kruskal-Wallis comparing medians of Resting Heart Rate across Activity Levels';

proc npar1way data=lab3 wilcoxon;
    class physical_activity;
    var resting_hr;
run;
/************************************************************************

3. Is education level associated with diabetes? (Chi-square or Fisher’s exact)

/************************************************************************/
/* Descriptive Statistic */
title "Frequencies for Education Levels and Diabetes";

proc freq data=lab3;
    tables education diabetes / missing norow nocol nopercent;
run;

title "Education Levels by Diabetes - Crosstabulation";

proc freq data=lab3;
    tables education*diabetes;
run;

/* Graphs & Tables */
title "Bar Chart of Education Levels";

proc sgplot data=lab3;
    vbar education;
run;

title "Bar Chart of Diabetes";

proc sgplot data=lab3;
    vbar diabetes;
run;

title "Diabetes by Education Levels";

proc sgplot data=lab3;
    vbar education / group=diabetes groupdisplay=cluster;
run;

/* Test Statistic */
title "Chi-Square Test for Association of Education Levels and Diabetes";

proc freq data=lab3;
    tables education * diabetes / chisq expected norow nocol nopercent;
run;
