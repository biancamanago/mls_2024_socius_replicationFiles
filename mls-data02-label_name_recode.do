capture log close
log using "mls-data02-label_name_recode", replace text
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm
 
 set seed     1234
 set sortseed 1234

 local pgm   mls-data02-label_name_recode.do
 local dte   2023-10-06
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"


****************************************************************
// #1 Load Data
****************************************************************
use "Data/mls-data01-conditions", clear

**************************************************************** 
// Labeling & Recoding Into Binary to Mirror Previous GSS Papers
****************************************************************	
	
**********
/// LABEL
**********	

	revrs  mentlill // higher numbers more likely to be mental illness
	rename revmentlill L_mentlill

// recode but maintain missingness	
	recode L_mentlill (3/4=1 "Lab MntlIllness") ///
			(1/2=0 "NoLab MntlIllness ") ///
			(.d=.d) (.i=.i) (.n=.n), gen(L_mentlillB)
		label var L_mentlillB "Very Likely/Likely Mental Illness"
		
	tab L_mentlill L_mentlillB, m
	tab mentlill L_mentlillB, m
		

**********
/// SOCIAL DISTANCE	
**********		

	rename vignei    s_nextdoor
	rename vigsoc    s_social 
	rename vigfrnd   s_friends 
	rename vigwork   s_work 
	rename vigmar    s_marry 
	rename viggrp    s_grphome
			
	unab vars: s_nextdoor s_social s_friends s_work s_marry s_grphome
	
// creating binary as created in other GSS papers (namely Martin)	
	foreach v in `vars' {
		recode `v' (1/2=0) (3/4=1) (.d=0), gen(`v'B)
		la val `v'B unwilling
		local varlbl : variable label `v' 
		la var `v'B "Bin: `varlbl'" 
		ta `v' `v'B, m
	   }  	
		
**********
///  ATTRIBUTIONS	
**********	

	unab vars:  upsdowns breakdwn physill imbalnce genetics ///
				stresses wayraise charactr godswill 
	
	la def likely 0 "UnLikely" 1 "Likely"
		
	foreach v in `vars' {
		g a_`v'R = `v'
		recode a_`v'R (1/2=1) (3/4=0)
		la value a_`v'R likely
		local varlbl : variable label `v' 
		la variable a_`v'R "Bin: `varlbl'"  
		ta `v' a_`v'R, m
	   } 
	   
	   
	unab vars:  upsdowns breakdwn physill imbalnce genetics ///
				stresses wayraise charactr godswill 
	
	la def Vlikely 0 "UnLikely" 1 "VeryLikely"
		
	foreach v in `vars' {
		g a_`v'RV = `v'
		recode a_`v'RV (1=1) (2/4=0)
		la value a_`v'RV Vlikely
		local varlbl : variable label `v' 
		la variable a_`v'RV "Bin: `varlbl'"  
		ta `v' a_`v'RV, m
	   } 
	   
// rename attribution variables so all begin with a_

	local att     "charactr imbalnce wayraise stresses genetics godswill"
	local att     "`att' upsdowns breakdwn physill"
	
	foreach v in `att' {
		rename `v' a_`v'
		}	   
	   

******
// TREATMENT ENDORSEMENT 
******

	unab vars: meddoc mentldoc mentlhos rxmed dangrslf dangroth otcmed selfhelp
	foreach v in `vars' {
		g shld_`v' = `v'
		g shld_`v'R = shld_`v'
		recode shld_`v'R (1=1) (2=0) (.d=0)
		local varlbl : variable label `v' 
		la var shld_`v'R "Bin: `varlbl'" 
		la val shld_`v'R yesno
		}
		
**********
// FEAR	
**********
		
	revrs  hurtoth
	rename revhurtoth violent_oth
	
	revrs  hurtself
	rename revhurtself violent_self
	
	unab vars: violent_oth violent_self
	
	foreach v in `vars' {
		fre `v'
		g `v'R = `v'
		recode `v'R (3/4=1) (1/2=0) (.d=0)
		la var `v'R "Bin: `varlbl'" 
		}

		
	rename must* must_*
	rename imprv* imp_*
	
**********
/// SOCIAL DESIRABILITY		
**********	
	
	rename mcsds1 d_mistake
	rename mcsds2 d_forgive
	rename mcsds3 d_myway
	rename mcsds4 d_diffideas
	rename mcsds5 d_hurt
	rename mcsds6 d_gossip
	rename mcsds7 d_advantage
	
	fre d_*
		
**************************************************************** 
// RESPONDENT DEMOGRAPHICS
****************************************************************	
	
// Sex
	fre sex
	recode sex (2=1 "female") (1=0 "male"), gen(female)
	la   var female "Female? (vs. male)"
	ta   sex female, m
	drop sex
  
// Race
	fre  race
	lab def racelab 1 "white" 2 "black" 3 "other race"
	lab val race racelab
	
	g    white = (race == 1) if race < .
	la   var  white "White? (vs non-white)"
	la   val  white yesno
	ta   race white, m

// Age and cohort 
	label var age "age in years"
	
	      g age10 = .
	replace age10 = 1 if age >= 18 & age < 28
	replace age10 = 2 if age >= 28 & age < 38
	replace age10 = 3 if age >= 38 & age < 48
	replace age10 = 4 if age >= 48 & age < 58
	replace age10 = 5 if age >= 58 & age < 68
	replace age10 = 6 if age >= 68 & age < .
		la var age10 "Age Ordinal 18/28 - 68+"
		
	tabstat age, by(age10) m

	      g cohort10 = 1 if cohort >= 1907 & cohort < 1927
	replace cohort10 = 2 if cohort >= 1927 & cohort < 1937
	replace cohort10 = 3 if cohort >= 1937 & cohort < 1947
	replace cohort10 = 4 if cohort >= 1947 & cohort < 1957
	replace cohort10 = 5 if cohort >= 1957 & cohort < 1967
	replace cohort10 = 6 if cohort >= 1967 & cohort < 1977
	replace cohort10 = 7 if cohort >= 1977 & cohort < 1987
	replace cohort10 = 8 if cohort >= 1987 & cohort < .
		la var cohort10 "Cohort Ordinal" 
 
	lab def quartlab 1 "1st quartile" 2 "2nd quartile" 3 "3rd quartile" 4 "4th quartile"
	sum 	age, d
	xtile 	ageQ = age, nq(4)
	sum 	age ageQ
	polychoric age ageQ
	lab var ageQ "Age Quartiles"
	lab val ageQ quartlab
	fre 	ageQ
	
	
	
// Education 
// The piece in AJPH is a bit vague on the coding (in one place it says
// "at least a high school degree" and in another it says "greater than
// a high school degree"). The descriptives suggest the latter is correct.
  
	g ed_gths = 1 if degree > 1 & degree <= 4 
	replace ed_gths = 0 if degree <= 1 & degree >= 0
		la var ed_gths "R ed > HS"
		
	la var educ "Years Education"

// Region/area

	fre region
	recode region (1/4 7/9 =0 "Non-South") (5/6=1 "South"), gen(south) 
	label var south "Lives in South?"
	
	gen			metro = 0
	lab var		metro "Metropolitan Area?"
	replace		metro = 1 if srcbelt == 1 | srcbelt == 2
	replace		metro = 0 if srcbelt == 3 | srcbelt == 4 | srcbelt == 5 | ///
							 srcbelt == 6
	lab def 	metrolab 0 "NonMetro" 1 "MetroArea"
	lab val 	metro metrolab
	tab 		srcbelt metro, m

	gen 		region4 = region
	lab var		region4 "Region of US"
	lab define	regionlab 1 "Northeast" 2 "Midwest" 3 "South" 4 "West"
	recode		region4 1 2 = 1		3 4 = 2		5/7 = 3		8 9 = 4
	lab values	region4 regionlab

	
// Size

	la var xnorcsiz "Size of MSA/County"
	
// Income

	sum income
	la var income "Total Family Income"
		
	sum income91
	la var income91 "Total Family Income (1991)"
			
	sum income06
	la var income06 "Total Family Income (2006)"
	
	sum income16
	la var income16 "Total Family Income (2018)"
	
	*TDM note: Using coninc b/c fewer missing values
	sum 	coninc, d
	replace coninc = coninc / 1000
	lab var coninc "income in 1000s"
	sum 	coninc, d
	
	sum 	coninc, d
	xtile 	conincQ = coninc, nq(4)
	sum 	coninc conincQ
	polychoric coninc conincQ
	
	lab var conincQ "Income Quartiles"
	lab val conincQ quartlab
	fre 	conincQ
	
// Parent
	gen			numchild = childs
	lab var		numchild "Children Count"

	gen 		anychild = numchild
	lab var		anychild "Any Children"
	recode		anychild 0=0	1/10 = 1
	lab val		anychild yesno
	tab 		numchild anychild, m	
	
****************************************************************
// # Save and Close Out
****************************************************************

	drop __POLY*

save "Data/mls-data02-label_name_recode", replace

log close
exit

// Generate indicator of NEUROBIOLOGICAL CONCEPTION of mental illness
// As per the 2010 paper: "Coded 1 if the respondent labeled the problem 
// as mental illness and attributed cause to a chemical imbalance or a 
// genetic problem, coded 0 otherwise"
 
 /*
	gen     a_neurob = 1 if L_mentlill == 1 & (a_imbalnceR == 1 | a_geneticsR == 1)
	replace a_neurob = 1 if L_mentlill == 2 & (a_imbalnceR == 1 | a_geneticsR == 1)
	replace a_neurob = 0 if L_mentlill == 3 |  L_mentlill == 4
		
	la var  a_neurob "Neurobiological conception" */
