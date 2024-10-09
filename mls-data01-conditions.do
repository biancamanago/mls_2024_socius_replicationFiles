capture log close
log using "mls-data01-conditions", replace text
 
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

 local pgm   mls-data01-conditions.do
 local dte   2023-10-06
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"

****************************************************************
// #1 Load Data
****************************************************************
use "Data/mls-data00-import", clear

****************************************************************
// #2 Vignette Labeling/Recoding Based on Illness
****************************************************************

	g cond96 = vigversn if year == 1996
	recode cond96 (1/18=4) (19/36=2) (37/54=3) (73/90=1) (55/72=5)
		la var cond96 "1996 vig illness"
		la de  cond96 1 "Daily Troubles" 2 "Depression" ///
					  3 "Schizophrenia"  4  "Alcohol Addiction"  ///
					  5 "Drug Addiction" 
		la val cond96 cond96
	ta cond96 , m

	g cond06 = vigversn if year == 2006
	recode cond06 (1/18=4) (19/36=2) (37/54=3) (73/90=1) (55/72=.)
		la var cond06 "2006 vig illness"
		la de  cond06 1 "Daily Troubles" 2 "Depression" ///
					  3 "Schizophrenia"  4  "Alcohol Addiction" 
		la val cond06 cond06
	ta cond06 , m

	g cond18 = vigversn if year == 2018
	recode   cond18 (1/18=4) (19/36=2) (37/54=3) (73/90=1) (55/72=5)
		la var cond18 "2018 vig illness"
		la val cond18 cond96
	ta cond18 , m

	g cond = .
	replace cond = cond96 if year == 1996
	replace cond = cond06 if year == 2006
	replace cond = cond18 if year == 2018
	la val  cond cond96
	la var  cond "Vig: Illness (all years)"

// Recode vignettes into dummies

	ta cond, gen(vig)
	rename vig1     vignorm
		la var  vignorm  "Vig: Daily Troubles"
		lab def	normlab 0 "Other vignette" 1 "Daily troubles"
		lab val vignorm normlab
	
	rename vig2    vigdep
		la var  vigdep   "Vig: Depression"
		lab def	deplab 0 "Other vignette" 1 "Depression"
		lab val vigdep deplab
	
	rename vig3    vigschiz
		la var  vigschiz "Vig: Schizophrenia"
		lab def	schizlab 0 "Other vignette" 1 "Schizophrenia"
		lab val vigschiz schizlab
	
	rename vig4    vigalc
		la var  vigalc   "Vig: Alcohol"
		lab def	alclab 0 "Other vignette" 1 "Alcohol"
		lab val vigalc alclab
	
	rename vig5    vigdrug
		la var  vigdrug  "Vig: Drug Problem"
		lab def	druglab 0"Other vignette" 1"Drug"
		lab val vigdrug druglab

******
// Check to see if done correctly
******			
	unab vars: vignorm-vigdrug
	
	foreach v in `vars' {
		ta vigver `v' , m
	}
	
******
//  Year
******
	fre year
	*Add labels for plots
	lab def yearlab 1996 "1996" 2006 "2006" 2018 "2018"
	lab val year yearlab	
	
**************************************************************** 
//  Charateristics of person in the vignette
****************************************************************

// Categories include:
// Female (male), white (non-white), greater than HS (HS or less).

// In 2006, no respondents received the drug vignette 
// so we replaced 2006 vignettes with missing	

******
// Sex
******
	g vig_female = 0
	replace vig_female = 1 if (vigversn >= 10 & vigversn <= 18) | ///
							  (vigversn >= 28 & vigversn <= 36) | ///
							  (vigversn >= 46 & vigversn <= 54) | ///
							  (vigversn >= 82 & vigversn <= 90)
							  
	    la var vig_female "Female Vignette Character?"
		la val vig_female yesno						  
							  
// 2006 missing drug vignette						  
	replace vig_female = . if vigversn >= 55 & vigversn <= 72 & year==2006

******
// Race
******

	g vig_white = 0
	
// every third vignette is white	
	
	forval n=1(3)88{
		replace vig_white = 1 if vigversn==`n'
	}
	 						 
		la var vig_white "White Vignette Character?"
		la val vig_white yesno
	
	replace vig_white = . if vigversn >= 55 & vigversn <= 72 & year==2006
	
	tab vigversn vig_white, m
		
******
// Education
******		
	g vig_gths = 0 
	replace vig_gths = 1 if  vigversn == 7/9   | vigversn == 16/18 |  ///
							 vigversn == 25/27 | vigversn == 34/36 | ///
							 vigversn == 43/45 | vigversn == 52/54 | ///
							 vigversn == 61/63 | vigversn == 70/72 | ///
							 vigversn == 79/81 | vigversn == 88/90 
		
		la var vig_gths "Vignette Ed > High School?"
		la val vig_gths yesno
		
	replace vig_gths = . if vigversn >= 55 & vigversn <= 72 & year==2006
	
****************************************************************
// # Save and Close Out
****************************************************************

save "Data/mls-data01-conditions", replace

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
	

