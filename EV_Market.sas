data project;
infile '/home/u63652615/sasuser.v94/EV_Data.csv' dlm=',' firstobs=2;
length VIN $15 County $25 City $15 CAFV_Eligibility $45 Veh_Loc $35 E_Utility $55;
input VIN $ County $ City $ State $ Postal_Code Model_year Make $ Model $ EV_Type $ CAFV_Eligibility $ EV_Range Base_MSRP Leg_Dist DOL_VehicleID Veh_Loc $ E_Utility $ Census ;

proc means data=project nmiss;
run;

PROC FREQ DATA=project ;
    TABLES Model_Year / OUT=ev_adoption_by_year;
RUN;

PROC FREQ DATA=project;
    TABLES Model_Year / OUT=ev_adoption_by_year;
RUN;

PROC SGPLOT DATA=ev_adoption_by_year;
    VBAR Model_Year / RESPONSE=COUNT;
RUN;

proc sort data=project;
by County;
run;

data county;
set project; by County;
run;

PROC FREQ DATA=county order=freq;
    TABLES County / OUT=Top_Counties ;
RUN;
DATA Top_Counties1;
    SET Top_COunties;
    IF COUNT >= 80;
RUN;
PROC SGPLOT DATA=Top_Counties1;
    HBAR County / RESPONSE=COUNT categoryorder=respdesc;
RUN;

PROC SGPLOT DATA=project;
    HBAR EV_Type / categoryorder=respdesc;
RUN;

PROC SORT DATA=project;
    BY Make;
RUN;

data make;
set project; by Make;
run;



PROC FREQ DATA=Make order=freq;
    TABLES Make / OUT=Top_Makers ;
RUN;

DATA Top_Makers1;
    SET Top_Makers;
    IF COUNT >= 1500;
RUN;

PROC SGPLOT DATA=Top_Makers1;
    HBAR Make / Response= Count categoryorder=respdesc;
RUN;

PROC SORT DATA=project;
    BY Model;
RUN;

data model;
set project; by Model;
run;

PROC FREQ DATA=model order=freq;
    TABLES Model / OUT=Top_Models ;
RUN;

DATA Top_Models1;
    SET Top_Models;
    IF COUNT >= 2000;
RUN;

PROC SGPLOT DATA=Top_Models1;
    HBAR Model / Response= Count categoryorder=respdesc;
RUN;


PROC SORT DATA=project;
    BY EV_Range;
RUN;

/* Define a custom format for the ranges */
PROC FORMAT;
    VALUE ev_range low-<25 = '0-24'
                   25-<50 = '25-49'
                   50-<75 = '50-74'
                   75-HIGH = '75+';
RUN;

/* Apply the format to your variable */
DATA newRange;
    SET project;
    FORMAT EV_Range ev_range.;
RUN;


data ev_range;
set newRange; by EV_Range;
run;


PROC FREQ DATA=ev_range order=freq;
    TABLES EV_Range / OUT=ev_ranges ;
RUN;

DATA evranges;
    SET ev_ranges;
    IF EV_Range >= 40;
RUN;

PROC SGPLOT DATA=ev_range;
    vbar EV_Range;
RUN;

proc means data = project;
var EV_Range;
run;

PROC MEANS DATA=project NOPRINT;
    CLASS Make Model;
    VAR EV_Range;
    OUTPUT OUT=average_range_by_model MEAN(EV_Range)=;
RUN;

PROC SORT DATA=average_range_by_model;
    BY DESCENDING EV_Range;
RUN;

DATA top_range_models;
    SET average_range_by_model (OBS=30);
RUN;

PROC SGPLOT DATA=top_range_models;
    HBAR Model / RESPONSE=EV_Range GROUP=Make categoryorder=respdesc;
    KEYLEGEND / TITLE='Make';
RUN;


DATA years;
    SET project;
    IF Model_Year >= 2017;
    if Model_Year <= 2023;
RUN;

data newyears;
	Model_Year = 2024; /* Start year */
    do i = 1 to 11;
        Model_Year = Model_Year + 1;
        output;
    end;
    drop i;
run;

proc sort data=newyears;
by Model_Year;
run;
proc sort data=years;
by Model_Year;
run;

data merged;
merge newyears(in=a) years(in=b);
by Model_Year;
run;


proc print data=newyears;
run;

proc sgplot data=years;
    vbox Model_Year;
run;

PROC FREQ DATA=years order=freq;
    TABLES Model_Year / OUT=yearfreq (RENAME=(COUNT=Frequency)) ;
RUN;

/* Sort the data by Model_Year */
proc sort data=yearfreq;
    by Model_Year;
run;

PROC FORECAST data=yearfreq out=forecasted_data lead=12 interval=Day method=expo;
    ID Model_Year;
    VAR Frequency;
RUN;

proc print data = forecasted_data;
run;

data forecast_output;
    set forecast_all;
    if Model_Year > 2023; /* Replace '2023' with the last year in your historical data */
run;

proc sgplot data=forecasted_data;
    scatter x=Model_Year y= Frequency / datalabel=Model_Year markerattrs=(symbol=circlefilled size=7 color=blue) legendlabel="Forecasted";
    series x=Model_Year y=Frequency / datalabel= Frequency lineattrs=(color=blue thickness=2px);
    xaxis type=time;
    yaxis label="Forecast";
    keylegend / location=inside position=topright across=1;
    title "Forecasted EV Market Growth 2024-2035";
run;

proc sgplot data=yearfreq;
    scatter x=Model_Year y= Frequency / datalabel=Model_Year markerattrs=(symbol=circlefilled size=7 color=blue) legendlabel="Forecasted";
    series x=Model_Year y=Frequency / datalabel= Frequency lineattrs=(color=green thickness=2px);
    xaxis type=time;
    yaxis label="Forecast";
    keylegend / location=inside position=topright across=1;
    title "EV Market Growth from 2017-2023";
run;