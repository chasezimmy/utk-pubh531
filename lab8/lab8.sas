/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 8

/************************************************************************/
libname lab8 "/home/u64574211/sasuser.v94/Lab8";

options nodate nonumber;

/***************************************************

Variable Clean

 ***************************************************/
data lab8.scp_transform;
    set lab8.scp_tn_2023;

    /* Keep only respondents with a positive final weight */
    if _llcpwt <= 0 then delete;

    /* ---- Outcome (Y): CIMEMLO1 - SCD, binary ---- */
    /* 1=Yes, 2=No; 7/9 -> missing. */
    if cimemlo1 in (7,9) then scd=.;
    else if cimemlo1=1 then scd=1; /* Yes */
    else if cimemlo1=2 then scd=0; /* No  */
    label scd="Subjective cognitive decline (1=Yes, 0=No)";

    /* ---- Categorical predictor (X1): ADDEPEV3 - depression ---- */
    /* 1=Yes, 2=No; 7/9 -> missing. */
    if addepev3 in (7,9) then dep=.;
    else dep=addepev3; /* 1=Yes, 2=No (reference) */
    label dep="Ever told had depressive disorder (1=Yes, 2=No)";

    /* ---- Continuous predictor (X2): MENTHLTH - mental health days ---- */
    /* 1-30 = days; 88=None -> 0; 77/99 -> missing. Range becomes 0-30. */
    if menthlth in (77,99) then menthdays=.;
    else if menthlth=88 then menthdays=0;
    else menthdays=menthlth;
    label menthdays="Days mental health not good, past 30 (0-30)";

    /* ---- Domain / inclusion: TN adults 45+ via _AGE_G (4,5,6) ---- */
    if _age_g in (4,5,6) then dom45=1;
    else dom45=0;
    label dom45="Domain: TN adults aged 45+ (1=in domain)";
run;

title
    "Final analytic N (unweighted) and weighted population size (45+, complete cases)";

proc surveymeans data=lab8.scp_transform nobs sum;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    where _age_g in (4,5,6) and nmiss(scd, dep, menthdays)=0;
    /* 45+ AND complete */
    var scd;
run;

/***************************************************

Exploratory Data Analysis in Dom45 (TN adults 45+ via _AGE_G (4,5,6))

 ***************************************************/
/* --- Weighted outcome alone --- */
title "EDA 1 - Weighted: CIMEMLO1 (SCD) prevalence (TN adults 45+)";

proc surveyfreq data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    tables dom45*scd / row cl; /* dom45 first = subgroup; read dom45=1 */
run;

/* --- Unweighted outcome alone --- */
title "EDA 2 - Unweighted: CIMEMLO1 counts (sample)";

proc freq data=lab8.scp_transform;
    where _age_g in (4,5,6);
    tables scd;
run;

/* --- Weighted mean MENTHLTH by ADDEPEV3 --- */
title
    "EDA 3 - Weighted: Mean MENTHLTH (mental health days) by ADDEPEV3 (depression)";

proc surveymeans data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    domain dom45*dep;
    var menthdays;
run;

/* --- Weighted distribution of the categorical predictor --- */
title "EDA 4 - Weighted: ADDEPEV3 prevalence (TN adults 45+)";

proc surveyfreq data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    tables dom45*dep / row cl;
run;

/* --- Unweighted distribution of the categorical predictor --- */
title "EDA 5 - Unweighted: ADDEPEV3 counts (sample)";

proc freq data=lab8.scp_transform;
    where _age_g in (4,5,6);
    tables dep;
run;

/* --- Outcome by categorical predictor, with design-based chi-square --- */
title "EDA 6 - Weighted: CIMEMLO1 by ADDEPEV3, chi-square (TN adults 45+)";

proc surveyfreq data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    tables dom45*scd*dep / chisq;
run;

/* --- Continuous predictor (X2): MENTHLTH overall, 45+ (4.3) --- */
title "EDA 7 - Weighted: MENTHLTH mean/CI, SD, median, IQR (TN adults 45+)";

proc surveymeans data=lab8.scp_transform mean clm std median q1 q3;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    domain dom45;
    var menthdays;
run;

/* --- MENTHLTH Univariate --- */
title "EDA 7b - MENTHLTH Univariate";

proc univariate data=lab8.scp_transform;
    where _age_g in (4,5,6);
    var menthdays;
    histogram menthdays;

    /* --- Bivariable: CIMEMLO1 <> MENTHLTH --- */
    title "EDA 8 - CIMEMLO1 <> MENTHLTH (TN adults 45+)";

proc surveylogistic data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    domain dom45;
    model scd(event='1')=menthdays / clodds;
run;

/***************************************************

Regression Models

 ***************************************************/
/* --- Weighted logistic: CIMEMLO1 on ADDEPEV3 + mental health days --- */
title
    "Model 1 - Weighted logistic: CIMEMLO1 = ADDEPEV3 + MENTHLTH (TN adults 45+)";

proc surveylogistic data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;

    domain dom45;

    /* Categorical predictor: No (2) as reference */
    class dep (param=ref ref='2') / desc;

    /* event='1' => model the odds of SCD=Yes */
    model scd(event='1')=dep menthdays / clodds covb rsquare;
run;

/* --- Unweighted logistic --- */
title "Model 2 - Unweighted logistic: CIMEMLO1 = ADDEPEV3 + MENTHLTH";

proc logistic data=lab8.scp_transform;
    where _age_g in (4,5,6);
    class dep (param=ref ref='2') / desc;
    model scd(event='1')=dep menthdays;
run;

/***************************************************

Model diagnostics & assumptions

 ***************************************************/
/* --- Linearity of MENTHLTH  --- */
title "Linearity of MENTHLTH";

proc surveylogistic data=lab8.scp_transform;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    domain dom45;
    class dep (param=ref ref='2') / desc;
    model scd(event='1')=dep menthdays menthdays*menthdays;
run;

/* --- influence --- */
title "Influence MENTHLTH";

proc logistic data=lab8.scp_transform;
    where _age_g in (4,5,6);
    class dep (param=ref ref='2') / desc;
    model scd(event='1')=dep menthdays / lackfit;
run;
