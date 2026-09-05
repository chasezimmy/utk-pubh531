/************************************************************************

Is resting heart rate different across physical activity levels? (ANOVA or Kruskal–Wallis)

/************************************************************************/
libname lab3 "/home/u64574211/sasuser.v94/Lab3";

ods graphics on;
options nodate nonumber;

proc import datafile="/home/u64574211/sasuser.v94/Lab3/lab_3_dataset.csv"
    out=lab3 dbms=csv replace;
    getnames=yes;
run;

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
