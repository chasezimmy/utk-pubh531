/************************************************************************

Chase Zimmerman
PUBH 531 - Fall 2026
Lab 13

/************************************************************************/
libname lab13 "/home/u64574211/sasuser.v94/Lab13";

ods graphics on;
options nodate nonumber;

/* Copy the provided dataset (framingham5.sas7bdat) to lab13.data */
data lab13.data;
    set lab13.framingham5;
run;

proc contents data=lab13.data;
run;

title "Status Frequency";

proc freq data=lab13.data;
    tables status;
run;

title "Categorical Candidate Predictors: Number of Levels";

proc freq data=lab13.data nlevels;
    tables Sex BP_Status Chol_Status Smoking_Status Weight_Status / missing
        plots=freqplot;
run;

title "Continuous Candidate Predictors: Summary";

proc means data=lab13.data n nmiss mean std min max maxdec=1;
    var AgeAtStart Height Weight MRW Systolic Diastolic Cholesterol Smoking;
run;

data lab13.complete_case;
    set lab13.data;
    if cmiss(Status, AgeAtStart, Sex, BP_Status, Chol_Status, Smoking_Status,
        Weight_Status)=0;
run;

title "Complete-Case Subset: Outcome Distribution";

proc freq data=lab13.complete_case;
    tables Status;
run;

title "Backward Elimination: Logistic Regression";

proc logistic data=lab13.complete_case;
    class Sex (ref='Female') BP_Status (ref='Optimal') Chol_Status
        (ref='Desirable') Smoking_Status (ref='Non-smoker') Weight_Status
        (ref='Normal') / param=ref;
    model Status(event='Dead')=AgeAtStart Sex BP_Status Chol_Status
        Smoking_Status Weight_Status / selection=backward slstay=0.05 include=2;
run;

title "Forward Selection: Logistic Regression";

proc logistic data=lab13.complete_case;
    class Sex (ref='Female') BP_Status (ref='Optimal') Chol_Status
        (ref='Desirable') Smoking_Status (ref='Non-smoker') Weight_Status
        (ref='Normal') / param=ref;
    model Status(event='Dead')=AgeAtStart Sex BP_Status Chol_Status
        Smoking_Status Weight_Status / selection=forward slentry=0.05 include=2
        details;
run;
