/************************************************************************

3. Is education level associated with diabetes? (Chi-square or Fisher’s exact)

/************************************************************************/
libname lab3 "/home/u64574211/sasuser.v94/Lab3";

ods graphics on;
options nodate nonumber;

proc import datafile="/home/u64574211/sasuser.v94/Lab3/lab_3_dataset.csv"
    out=lab3 dbms=csv replace;
    getnames=yes;
run;

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
