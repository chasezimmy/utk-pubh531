
/***************************************************

1: Import the dataset: 
	This lesson imports the 2021 general sample
	and focuses on Ohio _State=39


***************************************************/

/* Point to your BRFSS dataset (Set this for your year/state) */

LIBNAME TRANSPRT XPORT 'C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 8 - Complex Survey Sampling\M8 SAS Lesson - Complex Sampling in BRFSS\LLCP2021XPT\LLCP2021.XPT' access=readonly;

LIBNAME BRFSS 'C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 8 - Complex Survey Sampling\M8 SAS Lesson - Complex Sampling in BRFSS';
/* Copy dataset from the XPORT file into the SAS library */

PROC COPY IN=TRANSPRT OUT=BRFSS MEMTYPE=DATA;
run;

Proc contents data=brfss.LLCP2021;
RUN;

/* Make a working copy and construct analysis variables */
data work.brfss_ana;
    set brfss.LLCP2021;  /* <-- replace with actual table name/year */
where _state=39;
    /* Keep only respondents with positive final weight */
    if _llcpwt <= 0 then delete;

    /* Example: Create a continuous BMI and binary obesity outcome */
    if _bmi5 in (., 9999) then bmi = .;
    else bmi = _bmi5/100;

    obese = (bmi >= 30);
    label obese = "Obesity (BMI = 30 kg/m^2)";

    /* Example predictors: sex, age, race, education, income */
    /* NOTE: variable names can differ by year—adapt as needed */

    age = _age80;               label age     = "Age (top-coded 80)";
    educ = educa;             label educ    = "Education (recoded categories)";
    income = income3;           label income  = "Income (recoded categories)";
    race = _imprace;            label race    = "Imputed Race (recoded categories)";
    sex = sexvar;                  label sex     = "Sex (1=Male, 2=Female)";

    /* Set common BRFSS missing codes to missing for categorical vars (7=Don't know, 9=Refused) */
    array catv[*] educ income race sex;
    do i=1 to dim(catv);
        if catv[i] in (7,9,77,99) then catv[i]=.;
    end;
    drop i;
run;

proc contents data=brfss_ana;
run;

data brfss_ana;
set brfss_ana;
keep age educ income race sex bmi obese _ststr _psu _llcpwt;
run;

/***************************************************

2: Exploratory Data Analysis 


***************************************************/

/* Weighted mean BMI, with standard error, CI, and design effect */
proc surveymeans data=work.brfss_ana mean stderr clm;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
    var bmi;
run;

PROC MEANS DATA=BRFSS_ANA MEAN STDERR CLM;
VAR BMI;
RUN;



/* Weighted mean BMI by sex using DOMAIN analysis (subpopulation by groups) */
proc surveymeans data=work.brfss_ana;
   	strata _ststr;
    cluster _psu;
    weight _llcpwt;
    domain sex;  /* produces design-correct estimates by sex levels */
	 var bmi;
run;

/* Weighted frequencies and percentages*/
proc surveyfreq data=brfss_ana;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
table sex;
run;

proc freq data=brfss_ana;
table sex;
run;

proc surveyfreq data=brfss_ana;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
table obese;
run;

proc surveyfreq data=brfss_ana;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
table educ;
run;


proc surveyfreq data=brfss_ana;
    strata _ststr;
    cluster _psu;
    weight _llcpwt;
table obese*sex/chisq;
run;


/* Weighted logistic*/

proc surveylogistic data=brfss_ana;
  strata  _ststr;
  cluster _psu;
  weight  _llcpwt;

  /* Categorical predictor */
  class sex (param=ref ref='1') / desc;

  /* Model: obese + sex; event='1' means obese=1 is the modeled event */
  model obese(event='1') = sex
        / clodds
          covb
          rsquare;

run;

proc logistic data=brfss_ana;
  class sex (param=ref ref='1') / desc;
  model obese(event='1') = sex;
  run;

  /* Weighted linear regression*/

  proc surveyreg data=brfss_ana;
    strata strata_var;
    cluster psu_var;
    weight weight_var;

    model bmi = age sex / solution clparm;
run;

  proc reg data=brfss_ana;
    model bmi = age sex;
run;
