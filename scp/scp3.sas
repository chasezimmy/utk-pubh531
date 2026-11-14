libname project "/home/u64574211/sasuser.v94/Project";

ods graphics on;
options nodate nonumber;

/* Data cleaning and preparation */
data analysis;
    set project.llcp2023_scp_tn;

    /* Non-answer codes to missing */
    if CIMEMLO1 in (7,9) then CIMEMLO1=.;
    if ADDEPEV3 in (7,9) then ADDEPEV3=.;
    if DIABETE4 in (7,9) then DIABETE4=.;
    if DEAF in (7,9) then DEAF=.;
    if CVDSTRK3 in (7,9) then CVDSTRK3=.;
    if BPHIGH6 in (2,4,7,9) then BPHIGH6=.;
    if EDUCA=9 then EDUCA=.;
    if MARITAL=9 then MARITAL=.;
    if EMPLOY1=9 then EMPLOY1=.;
    if _SMOKER3=9 then _SMOKER3=.;
    if _RFDRHV8=9 then _RFDRHV8=.;
    if _TOTINDA=9 then _TOTINDA=.;
    if INCOME3 in (77,99) then INCOME3=.;

    /* Recodes (see A.5) */
    if CIMEMLO1=1 then scd=1;
    else if CIMEMLO1=2 then scd=0;
    if ADDEPEV3=1 then dep=1;
    else if ADDEPEV3=2 then dep=0;
    if _AGE_G in (4,5,6) then age_cat=_AGE_G - 3;

    if _IMPRACE=1 then race_cat=1;
    else if _IMPRACE=2 then race_cat=2;
    else if _IMPRACE=5 then race_cat=3;
    else if _IMPRACE in (3,4,6) then race_cat=4;

    if EDUCA in (1,2,3) then educ_cat=1;
    else if EDUCA=4 then educ_cat=2;
    else if EDUCA=5 then educ_cat=3;
    else if EDUCA=6 then educ_cat=4;

    if INCOME3 in (1,2,3,4) then inc_cat=1;
    else if INCOME3 in (5,6) then inc_cat=2;
    else if INCOME3 in (7,8) then inc_cat=3;
    else if INCOME3 in (9,10,11) then inc_cat=4;

    if MARITAL=1 then marital_cat=1;
    else if MARITAL=6 then marital_cat=2;
    else if MARITAL in (2,3,4) then marital_cat=3;
    else if MARITAL=5 then marital_cat=4;

    if EMPLOY1 in (1,2) then employ_cat=1;
    else if EMPLOY1 in (3,4) then employ_cat=2;
    else if EMPLOY1=7 then employ_cat=3;
    else if EMPLOY1=8 then employ_cat=4;
    else if EMPLOY1 in (5,6) then employ_cat=5;

    if _SMOKER3=4 then smoke_cat=1;
    else if _SMOKER3=3 then smoke_cat=2;
    else if _SMOKER3 in (1,2) then smoke_cat=3;

    if BPHIGH6=1 then htn=1;
    else if BPHIGH6=3 then htn=0;
    if DIABETE4=1 then diab=1;
    else if DIABETE4 in (2,3,4) then diab=0;
    if _RFDRHV8=2 then heavydrink=1;
    else if _RFDRHV8=1 then heavydrink=0;
    if _TOTINDA=2 then inactive=1;
    else if _TOTINDA=1 then inactive=0;
    if DEAF=1 then deaf_bin=1;
    else if DEAF=2 then deaf_bin=0;
    if CVDSTRK3=1 then stroke=1;
    else if CVDSTRK3=2 then stroke=0;

    /* 45+ with outcome and exposure */
    analytic_sample=(not missing(age_cat) and not missing(scd) and not
        missing(dep));
run;

proc freq data=analysis;
    tables analytic_sample;
run;

/* Weighted frequencies and percentages with 95% CIs */
proc surveyfreq data=analysis;
    strata _STSTR;
    cluster _PSU;
    weight _LLCPWT;

    tables analytic_sample * (scd dep age_cat SEXVAR race_cat educ_cat inc_cat
        marital_cat employ_cat htn _BMI5CAT smoke_cat diab heavydrink inactive
        deaf_bin stroke) / row cl;

    /* SCD and depression within each age band */
    tables analytic_sample * age_cat * (scd dep) / row cl;
run;

/* Continuous BMI for _BMICAT5 analysis */
proc surveymeans data=analysis mean stderr clm median q1 q3 min max
    plots=(histogram boxplot);
    strata _STSTR;
    cluster _PSU;
    weight _LLCPWT;
    domain analytic_sample;
    var _BMI5;
run;

/* B.2 Rao-Scott chi-square, weighted row % with 95% CIs */
proc surveyfreq data=analysis;
    strata _STSTR;
    cluster _PSU;
    weight _LLCPWT;

    /* Depression x SCD */
    tables analytic_sample * dep * scd / row cl chisq;

    /* Depression x SCD within each age band */
    tables analytic_sample * age_cat * dep * scd / row cl chisq;

    /* Each covariate x depression */
    tables analytic_sample * (age_cat SEXVAR race_cat educ_cat inc_cat
        marital_cat employ_cat htn _BMI5CAT smoke_cat diab heavydrink inactive
        deaf_bin stroke) * dep / row cl chisq;

    /* Each covariate x SCD */
    tables analytic_sample * (age_cat SEXVAR race_cat educ_cat inc_cat
        marital_cat employ_cat htn _BMI5CAT smoke_cat diab heavydrink inactive
        deaf_bin stroke) * scd / row cl chisq;
run;
