capture log close
log using "mls-do01-regressions", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-do01-regressions.do
 local dte   2023-12-26
 local who   bianca manago - trent mize
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
//#1 Load Data
**************************************************************** 
 
 use "Data/mls-data07-mice-cont", clear	
 
 codebook if year==1996, compact
 sum socdist_tot if year==1996
 

local att   "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age i.female i.white i.south xnorcsiz coninc educ"
local cond "vignorm vigdrug vigalc vigschiz vigdep"


sum 	socdist_tot socdistSS L_mentlill violent_oth ///
		cntct_tot cntct_so4 cntct_val4 `cond' `att' `demog'


****************************************************************
//#2 Regression analyses that mirror matching analyses
****************************************************************
*NOTE: Using MI est b/c lots of missing data. Not using svy weights b/c
*	we can't with the matching analyses and we want those analyses to be
*	as comparable as possible to these

local dv "socdistSS" 
local iv "i.L_mentlillB" 
local cvs "c.age##c.age i.female i.race i.region i.metro coninc i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"

*Table B1

*Sig main effect of labels pooling across all vignetes.
mi est: 		reg 	`dv' `iv' i.cntct_tot `cvs' `evs'

*Only effect of labeling is on vignorm
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est: reg `dv' `iv' i.cntct_tot `cvs' i.year if `v'
	}


*Any issues with non-normal errors? (no)
* cannot use MI data for these tests
reg 	`dv' `iv' i.cntct_tot `cvs' `evs'
estat hettest
 
predict res_sc, res
lab var res_sc "Residuals from stigma regression"
kdensity res_sc, normal title("Distribution of residuals from pooled linear regression model") ///
	subtitle("Normal distribution included in blue for comparison") ///
	xtitle("Residuals from pooled regression model") ///
	legend(order(1 "Distribution of residuals" ///
		2 "Normal distribution" "(for comparison)") pos(6) row(1))

 	graph export "Graphs/A05-kdensity_residuals.png", replace
*	graph export "Graphs/A05-kdensity_residuals.emf", replace
	

// Sensitivty analysis with robust SEs //

*Sig main effect of labels pooling across all vignetes.
mi est: 		reg 	`dv' `iv' i.cntct_tot `cvs' `evs', robust


*Only effect of labeling is on vignorm
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est: reg `dv' `iv' i.cntct_tot `cvs' i.year if `v', robust
	}
	
// close out
log close
exit

/*
****************************************************************
// #3 Recreate 2000 Martin JHSB paper
****************************************************************

local cond   "i.vigdrug i.vigalc i.vigschiz i.vigdep"
local att    "i.a_imbalnceR i.a_geneticsR i.a_stressesR i.a_wayraiseR i.a_charactrR i.a_godswillR"
local demog  "age i.female i.white income91 educ i.south3 xnorcsiz"

	reg socdist_tot L_mentlill violent_oth `cond' `demog' `att' if year==1996 
	// can't quite recreate findings even with same sample size...
	
// if they were to just use the binary version of label mental illness, 
// they wouldn't get the same results - this is what they had in their 
// demographics table
// TDM: Not same #s but same basic findings (they used one-tailed tests)

local cond   "i.vigdrug i.vigalc i.vigschiz i.vigdep"
local att   "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age i.female i.white i.south3 xnorcsiz income educ"

	reg socdist_tot i.L_mentlillB `cond' `demog' `att' if year==1996
	reg socdist_tot i.L_mentlillB violent_oth `cond' `demog' `att' if year==1996
	estat vif
	
// Try some other stuff beyond Martin 2000 JHSB
local cond   "i.vigdrug i.vigalc i.vigschiz i.vigdep"
local att   "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age i.female i.white i.south3 xnorcsiz income educ"

	*Try for all years (main effect that appears mediated by violent_oth)
	reg socdist_tot i.L_mentlillB i.year `cond' `demog' `att'
	reg socdist_tot i.L_mentlillB violent_oth i.year `cond' `demog' `att'
	reg socdist_tot i.L_mentlillB i.cntct_tot##i.year `cond' `demog' `att'
	*Changed over time? (no)
	reg socdist_tot i.L_mentlillB##i.year `cond' `demog' `att'
	margins, dydx(L_mentlillB) over(year)	
	mchange L_mentlillB
	
// Run models just for the mental illness vignettes (depression and schizophrenia)	
// TDM: From a causal perspective, don't think attributions should be in model
// TDM: Same with violent/danger as that seems a mediator

local cond   "i.vigschiz"
local demog  "age i.female i.white i.south3 xnorcsiz income educ"

	*Try for all years (no main effect)
	reg socdist_tot i.L_mentlillB i.year `cond' `demog' ///
			if vigschiz ==1 | vigdep == 1

	*Changed over time?
	reg socdist_tot i.L_mentlillB##i.year `cond' `demog' ///
			if vigschiz ==1 | vigdep == 1
	margins, dydx(L_mentlillB) over(year)	

	*Vary by depression vs schizophrenia?
	reg socdist_tot i.L_mentlillB##i.vigschiz i.year `demog' ///
			if vigschiz ==1 | vigdep == 1
	margins, dydx(L_mentlillB) over(vigschiz)		
	
	
**********
/// Is attribution to mental illness affected by contact?
**********	
local demog   "age i.degree i.female i.white income"
local vig	  "i.vig_female i.vig_white"
local cont    "violent_oth violent_self"

// This is asking them if they think X has any mental illness
// There are many attributions (emotional breakdown, bad character, genetics
// godswill, chemical imbalance, mental illness, physical illness, normal ups
// and downs, stresses, way they were raised)

	logit 	L_mentlillB  i.cntct_tot i.cond i.year `demog' `vig' `cont'

	local year    "1996 2006 2018"
		
	foreach n in `year' {
		di in red ". logit   L_mentlillB  cntct_tot i.cond  `demog' `vig' `cont' if year==`n'"
		logit  L_mentlillB  cntct_tot i.cond  `demog' `vig' `cont' if year==`n'
	}

/* This is asking them if they think X has the specific label 

	logit   lbl_vigill i.cntct_tot i.cond  `demog' `vig' `cont' i.year

	local year2    "1996 2018"	// 2006 doesn't have this question

	foreach n in `year2' {
		di in red ". logit  lbl_vigill  cntct_tot i.cond  `demog' `vig' `cont' if year==`n'"
		logit   lbl_vigill  cntct_tot i.cond  `demog' `vig' `cont' if year==`n'
		}
		*/
	
**********
/// Is desired social distance affected by attribution to mental illness? (sometimes)
**********	
	** When broken up by year we don't see much, but when we combine we do.

// BINARY LABEL
local demog   "age i.degree i.female i.white"
local vig	  "i.vig_female i.vig_white"
local cont    "violent_oth violent_self"

	reg   	socdist_scl i.L_mentlillB i.cond i.year `demog' `vig' `cont'
	estat 	vif
	ologit   socdist_scl i.L_mentlillB i.cond i.year `demog' `vig' `cont'

	* by year
	local year    "1996 2006 2018"
	foreach n in `year' {
		di in red ". ologit   socdist_scl i.L_mentlillB i.cond `demog' `vig' `cont' if year==`n'"
		reg   	 socdist_scl i.L_mentlillB i.cond `demog' `vig' `cont' if year==`n'
		ologit   socdist_scl i.L_mentlillB i.cond `demog' `vig' `cont' if year==`n'
		}

// CONTINUOUS LABEL	
local demog   "age i.degree i.female i.white"
local vig	  "i.vig_female i.vig_white"
local cont    "violent_oth violent_self"

	reg 	 socdist_scl L_mentlill i.cond i.year `demog' `vig' `cont'
	ologit   socdist_scl L_mentlill i.cond i.year `demog' `vig' `cont'

	* by year
	local year    "1996 2006 2018"
	foreach n in `year' {
		di in red ". ologit   socdist_scl i.L_mentlillB i.cond `demog' `vig' `cont' if year==`n'"
		ologit   socdist_scl i.L_mentlill i.cond `demog' `vig' `cont' if year==`n'
		}
		
		
**********
/// Is desired social distance affected by contact with mental illness? 
**********	
	** 

// BINARY CONTACT
local demog   "age i.degree i.female i.white i.south3 xnorcsiz income" // TDM added vars
local vig	  "i.vig_female i.vig_white"
local cont    "violent_oth violent_self"

	reg 	socdist_scl i.cntct_tot i.year
	reg   	socdist_scl i.cntct_tot i.year i.cond `demog' `vig' `cont'
	estat 	vif

	*Limit to just mental illness vignettes
	reg 	socdist_scl i.cntct_tot i.year ///
			if vigschiz ==1 | vigdep == 1
	reg   	socdist_scl i.cntct_tot i.year i.cond `demog' `vig' `cont' ///
				if vigschiz ==1 | vigdep == 1

				

**********
/// Adding controls
**********	
local att   "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age i.female i.white i.south3 xnorcsiz coninc educ"
local cond "vignorm vigdrug vigalc vigschiz vigdep"

local dv "socdistSS" 
local iv "i.L_mentlillB" 
local cvs "c.age##c.age i.female i.race i.region i.metro coninc i.degree"

*without contact var
mi est, post: svy: reg `dv' `iv' `cvs'  violent_oth i.year
est store 		pool_nocntct

foreach v in `cond' {
	di in red "`v'"
	mi est, post: svy: reg `dv' `iv' `cvs'  violent_oth i.year if `v'==1
	est store mod_`v'
	}		
esttab pool_nocntct mod_vignorm mod_vigdrug mod_vigalc mod_vigschiz mod_vigdep ///
	using tables-no_contact.rtf , ///
	b(3) se(3)noomit nobase compress replace

*with contact var
mi est: svy: reg `dv' `iv' `cvs'  violent_oth i.year i.cntct_tot
est store 		pool_wcntct
foreach v in `cond' {
	di in red "`v'"
	mi est, post: svy: reg `dv' `iv' `cvs'  violent_oth i.year i.cntct_tot if `v'==1
	est store mod_`v'
	}
esttab pool_wcntct mod_vignorm mod_vigdrug mod_vigalc mod_vigschiz mod_vigdep ///
	using tables-w_contact.rtf , ///
	b(3) se(3)noomit nobase compress replace
					