/************************************************************************

Is education level associated with diabetes? (Chi-square or Fisher’s exact)

/************************************************************************/
libname lab3 "/home/u64574211/sasuser.v94/Lab3";

ods graphics on;
options nodate nonumber;

proc import datafile="/home/u64574211/sasuser.v94/Lab3/lab_3_dataset.csv"
    out=lab3 dbms=csv replace;
    getnames=yes;
run;

/* Descriptive Statistic */
/* Check for Normality */
/* Graphs & Tables */
/* Test Statistic */
