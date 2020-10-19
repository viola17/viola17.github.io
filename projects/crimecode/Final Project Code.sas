/*To run this code change the path statement in the %let below as appropriate.
Also, make sure you have files 10tbl08.csv, Oncampusarrest091011.csv,
ACS_05_EST_GCT2001.US13PR_with_ann.csv, and us_postal_codes.csv
in this file location. Finally, there are 4 infile statements to change*/

/*Read the concerns below. The output of the code gives the final codes of
crimescleaned2, oncampuscrimes2, income, and zipcodes datasets.
The crimescleaned2 has FBI crime data, oncampuscrimes2 has the on-campus data,
income has median income for each state, and zipcodes has each city in the
US and zip codes for that city. Read below about using the zipcodes data set*/

/*IMPORTANT: Also, read the comment below in the code about crimescleaned1 and
oncampuscrimes1. These data sets are not adjusted by dividing by populations.
Read my concerns about using oncampuscrimes2 for merging
(we should discuss more about it later)*/  

/*Also, the data step below reads in 10tbl08 saved as a windows .csv file,
so use the uploaded .csv files on the drive*/ 

%let path= /folders/myfolders/data;
libname orion "&path";

data crimes;
	infile "&path/10tbl08.csv" dsd firstobs = 5;
	input State :$22. City :$44. Population :comma. Violent_crime :comma. 
	Murder_and_manslaughter :comma. Rape :comma. Robbery :comma. 
	Assault :comma. Prop_crime :comma. Burglary :comma. Larceny_theft :comma.
	Motor_vehicle_theft :comma. Arson1 :comma.;
	RETAIN extraState;
	if not missing(State) then extraState = State;
	State = extraState;
	drop extraState;
	if 9311<=_n_<=9317 then delete;
	label Violent_crime = "Violent Crime" Murder_and_manslaughter = 
		  "murder and manslaughter" Prop_crime = "Property crime"
		  Larceny_theft = "Larceny theft" 
		  Motor_vehicle_theft = "Motor vehicle theft";
	format Population Violent_crime Murder_and_manslaughter Rape Robbery  
		   Assault Prop_crime Burglary Larceny_theft 
		   Motor_vehicle_theft Arson1 comma12.;
run;

/*Some cities have numbers in their names*/
proc print data = crimes (obs = 4);
	where city like "%0%" or State like "%0%"
	or city like "%1%" or State like "%1%"
	or city like "%2%" or State like "%2%"
	or city like "%3%" or State like "%3%"
	or city like "%4%" or State like "%4%"
	or city like "%5%" or State like "%5%"
	or city like "%6%" or State like "%6%"
	or city like "%7%" or State like "%7%"
	or city like "%8%" or State like "%8%"
	or city like "%9%" or State like "%9%";
run;

/*Removes numbers from City or State names*/
data crimescleaned;
	set crimes;
	State = compress(State, , "d");
	City = compress(City, , "d");
run;

/*Look at min max of dataset as well as number of missing values*/
proc means data = crimescleaned n nmiss mean min max;
	var Population Violent_Crime Rape Prop_Crime Arson1;
run;
/*Look at extreme observations of population*/
ods select ExtremeObs;
proc univariate data = crimescleaned;
	var Population;
	ID City;
run;
/*Verify that there aren't any missing Cities or States*/
proc print data = crimescleaned;
	where city is missing or State is missing;
run;

/*Make sure that there are 51 States (including district of Columbia)*/
proc sql;
	select Count(distinct State) "Number of Distinct States"
	from crimescleaned;
run; 

/*Look at missing populations and cities with small populations again*/
	/*
proc print data = crimescleaned;
	where Population < 50
	      or population = .;
run;
	*/
	
/*Look at observations with extremely high crime rates per population*/
/*Only first 4 observations shown to reduce space*/
proc print data = crimescleaned (obs = 4);
	where Population*0.25 < violent_crime 
		  or Population*0.25 < prop_crime;
run;

/*Delete observations with too high crime rates and create Violent_crime1 variable*/
/*This also deletes cities with missing populations*/
/*violent crime1 created because there are too many missing rape statistics*/

data orion.crimescleaned1;
	set crimescleaned;
	drop Arson1;
	if Population*0.25 < violent_crime 
		  or Population*0.25 < prop_crime
		  then delete;
	Violent_crime1 = Robbery + Assault + Murder_and_manslaughter;
	label Violent_crime1 = "Violent Crime Without Rape";
	
run;

/*Make sure that there are no obs. where violent crime or property crime 
do not add correctly*/
proc print data = orion.crimescleaned1;
	where Violent_crime ne Rape + Robbery + Assault + Murder_and_manslaughter
		  or Prop_Crime ne Burglary + Larceny_theft + Motor_vehicle_theft;
run;







/*Part 2 of code with oncampus crime data*/

data oncampuscrime;
	infile "&path/Oncampusarrest091011.csv" dsd firstobs = 2;
	input UNITID_P :$10. INSTNM :$93.  BRANCH :$78.  Address :$152.  City :$28.
	State :$25.  ZIP :$14.  sector_cd  Sector_desc :$38.  men_total  women_total  Total  
	WEAPON9  DRUG9  LIQUOR9  WEAPON10  DRUG10  LIQUOR10  WEAPON11  DRUG11
	LIQUOR11  FILTER09  FILTER10  FILTER11;
	INSTM = propcase(INSTM);
	City = propcase(City);
	keep UNITID_P INSTNM City State ZIP Total Weapon10 Drug10 Liquor10 Filter10;
	label UNITID_P = "Campus ID code" ZIP = "ZIP Code"
		  INSTNM = "Institution Name"
		  Total = "Total enrollment"
	      Weapon10 = "Weapons Violations: carrying, possessing, etc. in 2010"
	      Drug10 = "Drug Violations in 2010"
	      Liquor10 = "Liquor Violations in 2010";
run;

proc means data = oncampuscrime nmiss;
var Total Weapon10 Drug10 Liquor10 Filter10;
run;

/*No values of zip code missing, except when State is missing*/
proc print data = oncampuscrime;
where zip is missing and state is not missing;
run;

/*Observations with missing values for total (enrollment) or State*/
/*Only first 3 observations printed out of 31 missing enrollment, 149 missing State*/
proc print data = oncampuscrime (obs = 3);
where Total = . or  State is missing;
run;

/*Shows that all values of State (except the missing ones) are recognized 
by the stname function*/
proc print data = oncampuscrime;
	where stname(State) = ' ' and State ne ' ';
run;

/*This step (from the log) shows number of missing values for each variable
and the three variables combined

proc print data = oncampuscrime;
where Total is missing or Weapon10 is missing or State is missing;
run;*/


/*There are 59 States/ Territories*/
proc sql;
	select Count(distinct State) "Number of Distinct States/Territories"
	from oncampuscrime;
run;

/*There are 793 missing observations of Weapon/Drug/Liquor 
(the values are are all missing for the same observations), 
31 missing values of total (needed for population adjustment), 
and 149 missing values of State (needed for merging)
or 935 obs. with at least one missing. This is around 8% of the obs.
We remove these missing values.

The missing State values are from other countries, there are also
territories from Puetro Rico, etc. which we remove in the step below
and convert State Names to match State names in FBI table.
These are the excluded territories (not official US states, we
do include the territory Wishington DC though since its in the FBI data):
AMERICAN SAMOA
FED STATE MICRONESIA
GUAM
MARSHALL ISLANDS
NORTHERN MARIANA ISL
PALAU
PUERTO RICO
VIRGIN ISLANDS*/

proc freq data = oncampuscrime;
	tables state/ nocum;
	where Stname(State) in ('AMERICAN SAMOA', 'FED STATE MICRONESIA', 'GUAM'
				   			'MARSHALL ISLANDS', 'NORTHERN MARIANA ISL', 'PALAU',
							'PUERTO RICO', 'VIRGIN ISLANDS');
run;

/*This code also deletes the 4 digit extensions for the zip codes. Zip codes are 5 digits
and have 4 digits added on for a more refined location in a city. We can remove 
the line of code below that deletes extensions if we need them later*/

data orion.oncampuscrime1;
	set oncampuscrime;
	if Total = . or Weapon10 = . or Drug10 =. or Liquor10 =.
	then delete;
	if State = ' ' then delete;
	if Stname(State) in ('AMERICAN SAMOA', 'FED STATE MICRONESIA', 'GUAM'
				   			'MARSHALL ISLANDS', 'NORTHERN MARIANA ISL', 'PALAU',
							'PUERTO RICO', 'VIRGIN ISLANDS')
							then delete;
	State = upcase(stname(State));
	ZIP = substr(ZIP,1,5); /*Remove this line if need full zip code*/
run;

/*Extremely small values of total (these are schools like 
hair dressing schools, beauty college, etc.), we keep these in the data
There are 455 observations with Total students less than 50*/
ods select ExtremeObs;
proc univariate data = orion.oncampuscrime1;
	var Total;
	ID City;
run;

proc sql;
	title "Number of schools with enrollment less than 50";
	select count(*) "total number of schools"
  	from orion.oncampuscrime1
	where Total < 50;
run;
title;

/*Array step to adjust crime variables by population size
and then multiply by 100,000*/
data orion.crimescleaned2 (drop = i);
	set orion.crimescleaned1;
	array adjusted{10} Violent_crime Murder_and_manslaughter Rape Robbery  
		   Assault Prop_crime Burglary Larceny_theft 
		   Motor_vehicle_theft Violent_Crime1;
	
	do i = 1 to 10;
		adjusted{i} = adjusted{i}/Population*100000;
	end;
	format _numeric_ comma15.2;
run;

data orion.oncampuscrime2 (drop = i);
	set orion.oncampuscrime1;
	array adjusted{3} Weapon10 Drug10 Liquor10;
	
	do i = 1 to 3;
		adjusted{i} = adjusted{i}/Total*100000;
	end;
	format Total Weapon10 Drug10 Liquor10 comma12.;
run;


/*This code creates an income data set with each state and median incomes*/
data orion.income;
	infile "&path/ACS_05_EST_GCT2001.US13PR_with_ann.csv" firstobs = 4 dsd;
	input Id $ Id2 $Geography $ Target_Geo_Id $ Target_Geo_Id2
	Geographical_Area :$20. State :$20. Median_Income Margin_of_Error;
	if 1<= Target_Geo_ID2 <= 60;
	State = upcase(State);
	keep State Median_Income;
	label Median_Income = "Median Income";
	format Median_Income dollar8.;
run;
proc sort data = orion.income;
	by State;
run;


/*Finally, below is a data set of zip codes. It may be helpful to merge
this data set with the FBI data to get zip codes with each city. 
Then merge that with the zip codes in the on-campus data. (Or merge by State, City instead)
Usually zip codes are 5 digits for each town, but there is a 
4 digit extension on some of the on- campus zip codes (which I deleted above). 
There are no extensions in the zip code table below*/


/*IMPORTANT: One concern is how to deal with the cities. For example,
Galesburg might have another zip code and city listed for East Galesburg in the
zip code data set below, but in the on- campus data maybe for some universities they
write just Galesburg for the campus city instead of the technically correct East Galesburg.*/

/******MAIN CONCERN: There could be universities with multiple branches. 
I think the total for university is the total enrollment for the whole university,
however if a university has a branch in another city (like UIUC in Chicago), 
the enrollment in that branch would be much smaller.
For this reason, consider using oncampuscrime1 with
crimescleaned1 instead of the data sets ending in 2 which are adjusted for population.
This is because it might not make sense to divide by the population of the whole university
when looking at just a branch. We'll have to discuss this.*/

/*Note: all zip codes here are 5 digits*/
data orion.zipcodes;
	infile "&path/us_postal_codes.csv" dsd firstobs = 2;
	length ZIP $ 9 State $ 50 City $ 50;
	input ZIP :$9.  City :$50.  State :$25.  State_ABB $  County $  Lat  Long;
	keep ZIP State City;
	State = Upcase(State);
	label ZIP= "ZIP Code";
run;

/*There are a few zip codes that represent military bases, etc., I delete these*/
/*Only first three observations are printed*/

proc print data = orion.zipcodes (obs = 3);
	where ZIP is missing or State is missing or City is missing;
run;

data orion.zipcodes;
	set orion.zipcodes;
	if State = ' ' then delete;
run;

 


/* Create a new variable nonViolent_crime summing over non-violent crimes */
/* in FBI crimes crimescleaned2. Number of crimes are already normalized with */
/* city population in crimecleaned2.*/
data orion.crimescleaned2 (drop = i);
	set orion.crimescleaned2;
	array crime{4} Prop_crime Burglary Larceny_theft Motor_vehicle_theft;
	nonViolent_crime = 0;
	do i = 1 to 4;
		nonViolent_crime + crime{i};
	end;
	Total_crime = Violent_crime + nonViolent_crime;
	label Total_crime = "Total number of crimes"
		  nonViolent_crime = "Non-violent crimes";
	format Total_crime nonViolent_crime comma15.2;
run;

/* Create a new variable VIOLATION10 summing over thee vilations in on-campus */
/* violations because there are many 0s in each violation. */
data orion.oncampuscrime1 (drop = i);
	set orion.oncampuscrime1;
	array violation{3} Weapon10 Drug10 Liquor10;
	VIOLATION10 = 0;
	do i = 1 to 3;
		VIOLATION10 + violation{i};
	end;
	label VIOLATION10 = "Total campus violations in 2010";;
	format VIOLATION10 Total comma12.;
run;

/* Sort FBI crimes and on-campus violations. */
proc sort data=orion.crimescleaned2;
	by State City;
run;
proc sort data=orion.oncampuscrime1;
	by State City;
run;

/* Merge crime records in FBI and on-campus. */
data crime_oncampus;
	merge orion.crimescleaned2 (in = c)
		  orion.oncampuscrime1 (in = o);
	by State City;
	if c and o;
	keep UNITID_P State City ZIP INSTNM Total Population Violent_crime
		 nonViolent_crime Total_crime Violation10;
run;

/* Normalize the violations in on-campus is tricky because we only have total */
/* enrollment of all campuses of one university. Here we make a simple assumption */
/* that more city population has more enrollment in that campus (linear relation) */
proc sql;
	create table crime_oncampus as
	select *,
		   Total*Population/sum(Population) as Enroll
		   format = comma12.
		from crime_oncampus
		group by INSTNM;
quit;
data orion.crime_oncampus;
	set crime_oncampus;
	Violation10 = Violation10/Enroll*100000;
	format Violation10 comma15.2;
run;

/* Print top 20 unsafe campus. */
proc sql outobs=20;
	title "Top 20 unsafe campus with over 10000 enrollments";
	select State, City, Population, INSTNM, Total, Violent_crime,
		   nonViolent_crime, Total_crime, Violation10
		from orion.crime_oncampus
		where Total >= 10000 and Total_crime ~= .
		order by Violation10 desc, Total_crime desc;
quit;

/* Print top 20 safe campus. */
proc sql outobs=20;
	title "Top 20 safe campus with over 10000 enrollments";
	select State, City, Population, INSTNM, Total, Violent_crime,
		   nonViolent_crime, Total_crime, Violation10
		from orion.crime_oncampus
		where Total >= 10000 and Total_crime ~= .
		order by Violation10, Total_crime;
quit;

/* Sum number of crimes over state with FBI crimes crimescleaned1 and normalize */
/* with state population. */
data orion.crimescleaned1 (drop = i);
	set orion.crimescleaned1;
	array crime{4} Prop_crime Burglary Larceny_theft Motor_vehicle_theft;
	nonViolent_crime = 0;
	do i = 1 to 4;
		nonViolent_crime + crime{i};
	end;
	Total_crime = Violent_crime + nonViolent_crime;
	label Total_crime = "Total number of crimes"
		  nonViolent_crime = "Non-violent crimes";
	format Total_crime nonViolent_crime comma12.;
run;
proc sql;
	create table orion.crime_bystate as
	select State, sum(Population) as Population format=comma15.,
		   sum(Violent_crime)/sum(Population)*100000 as Violent_crime
		   label="Violent crimes" format=comma15.2,
		   sum(nonViolent_crime)/sum(Population)*100000 as nonViolent_crime
		   label="Non-violent crimes" format=comma15.2,
		   sum(Violent_crime+nonViolent_crime)/sum(Population)*100000 as Total_crime
		   label="Total number of crimes" format=comma15.2
		from orion.crimescleaned1
		group by State;
quit;

/* This is tricky for on-campus data because Total is already summed over all */
/* campuses i.e. Total is the same for all campuses of a university. So we need */
/* to first average the enrollment of each university before sum over state and */
/* normalize with total state enrollment. */
proc sql;
	create table orion.oncampuscrime_bystate as
	select State, sum(Total) as Total label="Total enrollment" format=comma12.,
		   sum(Violation10)/sum(Total)*100000 as Violation10
		   label="Total campus violations in 2010" format=comma15.2
		from (select State, sum(Violation10) as Violation10,
					 avg(Total) as Total format=comma12.
		   		from orion.oncampuscrime1
		   		group by INSTNM)
		group by State;
quit;

/* Merge FBI crimes, on-campus violations with state income. */
proc sql;
	title "FBI crime rate, on-campus violation rate and median income for every state";
	select c.State, Population, Total, Median_Income, Violent_crime,
		   nonViolent_crime, Total_crime, Violation10
		from orion.crime_bystate as c, orion.income as i,
			 orion.oncampuscrime_bystate as o
		where c.State = i.State = o.State
		order by c.State;
quit;