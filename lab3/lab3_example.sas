/************************************************************************/
/*   Module 3 SAS Lesson                                                */
/*   Dataset: M3_SAS_lesson_health_dataset (CSV or XLSX in same folder) */
/*                                                                      */
/************************************************************************/
ods graphics on;
options nodate nonumber;

/* === Import: choose one === */

/* CSV
proc import datafile="C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 3\SAS Lesson\M3_SAS_lesson_health_dataset.csv"
out=work.lesson dbms=csv replace;
guessingrows=max;
run;*/
proc import datafile="/home/u64574211/sasuser.v94/Lab3/m3_sas.csv" out=lab3
    dbms=csv replace;
    getnames=yes;
run;

/* === Part A: Descriptive statistics & normality === */
proc contents data=lab3;
run;

proc means data=lab3 n mean std min p25 median p75 max;
    var age bmi sbp cholesterol;
run;

proc freq data=lab3;
    tables sex smoker physical_activity hypertension / missing;
run;

/* Normality assessments */
proc univariate data=lab3 normal;
    var age bmi sbp cholesterol;
    histogram age bmi sbp cholesterol / normal;
    qqplot age bmi sbp cholesterol / normal(mu=est sigma=est);
run;

/* === Part B: Research Questions === */

/* RQ1: Is mean SBP different between men and women? (Parametric t-test if assumptions OK) */
proc ttest data=lab3;
    class sex;
    var sbp;
run;

/* RQ2: Is BMI distribution different across physical activity categories? (Nonparametric Kruskal–Wallis) */
proc npar1way data=lab3 wilcoxon;
    class physical_activity;
    var bmi;
run;

/* Optionally, parametric one-way ANOVA for comparison */
proc glm data=lab3;
    class physical_activity;
    model bmi=physical_activity;
    means physical_activity / hovtest=levene;
    run;
quit;

/* RQ3: Is smoking status associated with hypertension? (Chi-square; Fisher if needed) */
proc freq data=lab3;
    tables smoker*hypertension / chisq expected norow nocol nopercent;
    exact fisher; /* used automatically if small expected counts */
run;

ods graphics off;
