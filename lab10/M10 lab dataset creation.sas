data mph_biostat_lab;
    call streaminit(12345);
    do id = 1 to 600;

        age = rand("normal", 55, 10);
        sex = rand("bernoulli", 0.48);
        smoker = rand("bernoulli", 0.40);
        severity = ceil(rand("uniform")*4);

        followup_time = rand("uniform")*5;

        /* Mean exacerbation rate */
        lambda = exp(-1.5 
                     + 0.03*age 
                     + 0.4*smoker 
                     + 0.6*severity);

        /* Overdispersed count outcome */
        exacerbations = rand("negbinomial", lambda, 1.2);

        /* Survival outcome */
        baseline_hazard = 0.15;
        hospital_time = rand("exponential") / 
                        (baseline_hazard * 
                         exp(0.03*age + 
                             0.5*smoker + 
                             0.7*severity));

        if hospital_time <= followup_time then do;
            hospital_event = 1;
        end;
        else do;
            hospital_event = 0;
            hospital_time = followup_time;
        end;

        output;
    end;
run;

proc contents data=mph_biostat_lab;
run;

libname m10 'C:\Users\bsaltzm2\OneDrive - University of Tennessee\Teaching\Courses\PUBH 531 - Biostats II\Module 10\M10 - SAS lab';
data M10.hospital;
set mph_biostat_lab;
run;
