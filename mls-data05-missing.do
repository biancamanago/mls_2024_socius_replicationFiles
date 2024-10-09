capture log close
log using "mls-data05-missing", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-data05-missing.do
 local dte   2021-01-08 
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
 // #1 Load Data
**************************************************************** 
 local data "Data/mls-data04-sort_order"
 
**************************************************************** 
// Examine Missingness
**************************************************************** 
 
******
// 1996
****** 
 use `data', clear
 count
 
 // drop variables not in 1996
 drop *06 *18 phase d_* c_mh* c_diagnosd income16 c_effectR c_effectY
 
 keep if year==1996
 
 	missings report, percent
	missings table
	
	mi  set wide  
	
	mi  misstab patterns
	
******
// 2006
****** 
 use `data', clear
 
 // drop variables not in 2006
 drop *96 *18 d_*  income16 issp cntct_slf06 cntct_so06 income91 ///
      c_mhtreatd c_mhtrtot2 c_mhtrtslf  c_knwmhosp ///
	  c_knwpatnt c_mhdiagno c_brk* c_ev* 
                                            
 keep if year==2006                      
                                      
 	missings report, percent             
	missings table                       
	
	mi  set wide  
	
	mi  misstab patterns	
	
******
// 2018
****** 
 use `data', clear
 
 drop *96 *06 income91 c_effectR c_effectY c_brk* c_ev*  c_knwmhosp ///
	  c_knwpatnt c_mhtrtot2 c_mhtrtoth c_mhtrtslf c_mhothrel c_mhothyou
 
 // drop variables not in 2018
 keep if year==2018
 
 	missings report, percent
	missings table
	
	mi  set wide  
	
	mi  misstab patterns
	
	
**************************************************************** 
// Examine overall missingness for planned variables in analysis
****************************************************************	

 use `data', clear
 count
 
******
// If we were to look at each scale variable separately
****** 

 local vars "L_mentlillB cntct_tot vigdrug vigalc vigschiz vigdep vig_*"
 local vars "`vars' age ageQ female race region metro coninc degree"
 local sdvars " s_nextdoor s_social s_friends s_work s_marry s_grphome"
 
	missings report `vars' `sdvars', percent
	missings table  `vars' `sdvars'
	
	mi  set wide  
	
	mi  misstab patterns `vars' `sdvars'
	
**************************************************************** 
// DROP MISSING ON SCALE ITEMS
****************************************************************

  egen SD_miss = rowmiss(s_nextdoor s_social s_friends s_work s_marry s_grphome)
 
  fre SD_miss
 
 // BNM: Is it appropriate to drop 86 individuals who were 
 // missing (inapplicable) on all socdist items and consider them as incomplete?
 // TDM: I would exclude anyone missing on half or more of the items.
 *	doing so in the data07-sample_selection.do
 
*	drop if SD_miss >= 4 & SD_miss < .
	fre s_*
	
	count
	
 // Examine 221 individuals missing on some socdist items (incomplete)	
	
	local vars "L_mentlillB cntct_tot a_charactr a_genetics a_godswill a_imbalnce"
	local vars "`vars' a_stresses a_wayraise shld_dangroth shld_dangrslf"
	local vars "`vars' shld_meddoc shld_mentldoc shld_mentlhos shld_otcmed"
	local vars "`vars' shld_rxmed shld_selfhelp violent_oth violent_self"
 
	missings report `vars' if SD_miss != 0, percent
	missings table  `vars' if SD_miss != 0
 
	mi  misstab patterns `vars' if SD_miss != 0
	
	count

/* TDM: Ok to impute for these 221 as most are only missing on a few vars */
	
**************************************************************** 
// EXAMINE POSSIBLE SCALE PRORATION
****************************************************************	
 
 count if SD_miss<=3
 
 local vars "L_mentlillB cntct_tot vigdrug vigalc vigschiz vigdep vig_*"
 local vars "`vars' age ageQ female race region metro coninc degree"
 
	missings report `vars' if SD_miss<=3, percent
	missings table  `vars' if SD_miss<=3
 
	mi  misstab patterns `vars' if SD_miss<=3
	count
**************************************************************** 
// Create DK version of variables to mirror previous papers
// and for alternative and/or sensitivity analyses
****************************************************************
	
// Doing the following to mirror Martin 2000 JHSB \\
 
   	local socdist "s_nextdoor s_social s_friends s_work s_marry s_grphome"
	local att     "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
	local demog   "age female white income educ south size"
	
	*local vars "`socdist' `att' `demog'"
	
	fre `socdist'
	
	foreach v in `socdist' {
		gen     `v'DK0 = `v'
		replace `v'DK0=0 if `v'==.d
		la var `v'DK0 "DK=0"
		}

	fre s_*DK0
	
	foreach v in `socdist' {
		gen     `v'DK1 = `v'
		replace `v'DK1=1 if `v'==.d
		drop if `v'DK1==.i
		la var `v'DK1 "DK=1"
		}

	fre s_*DK1	
	
	foreach v in `socdist' {
		gen     `v'DK2 = `v'
		replace `v'DK2=2 if `v'==.d
		drop if `v'DK2==.i
		la var `v'DK2 "DK=2"
		}

	fre s_*DK2	
	
	foreach v in `socdist' {
		gen     `v'DK3 = `v'
		replace `v'DK3=3 if `v'==.d
		drop if `v'DK3==.i
		la var `v'DK3 "DK=3"
		}

	fre s_*DK3
	
	
	foreach v in `socdist' {
		gen     `v'DK4 = `v'
		replace `v'DK4=4 if `v'==.d
		drop if `v'DK4==.i
		la var `v'DK4 "DK=4"
		}

	fre s_*DK4
	
	
**************************************************************** 
// Close out
****************************************************************	
count
	save "Data/mls-data05-missing", replace

	log close
	exit
