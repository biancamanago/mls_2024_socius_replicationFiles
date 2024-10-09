capture log close
log using "mls-data07-sample_selection", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-data07-sample_selection.do
 local dte   2021-01-22
 local who   trent mize
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
 // #1 Load Data; Examine # of missing
**************************************************************** 
use "Data/mls-data06-scales", clear

count
 
local cond   "vigdrug vigalc vigschiz vigdep"
local att    "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age ageQ female race white south region region4 metro"
local demog  "`demog' anychild childs xnorcsiz coninc conincQ educ degree"

sum 	socdistSS L_mentlillB violent_oth cntct_tot ///
		`cond' `att' `demog'
		
misstable patterns 	socdistSS L_mentlillB violent_oth cntct_tot ///
		`cond' `att' `demog'
		
		
****************************************************************
 // #2 Create a listwise deletion dataset
**************************************************************** 
******
// Drop for missing on DV
******
count
local N `r(N)'
drop if missing(socdistSS)
local ndrop `r(N_drop)'
di `ndrop'
di `ndrop'/`N' // 3.28% of sampled dropped

******
// Drop for missing on income (by far most missing data)
******
count
local N `r(N)'
drop if missing(coninc, conincQ)
local ndrop `r(N_drop)'
di `ndrop'
di `ndrop'/`N'	// ~10.91% of sample dropped

******
// Drop for missing on other model vars
******
count
local N `r(N)'
drop if missing(L_mentlillB, cntct_tot, vigdrug, vigalc, vigschiz, ///
				vigdep, age, ageQ, female, race, region, metro, coninc, degree)
local ndrop `r(N_drop)'	
di `ndrop'			
di `ndrop'/`N'	// 6.33% of sample dropped

count
** Label and save data **
compress
label data "MLS - GSS Data | Matching Labeling Stigma | Listwise Deletion | `tag'"
datasignature set, reset
save	 "Data/mls-data07-listwise",  replace	
 
 
****************************************************************
 // #3A Create a multiple imputation dataset.
 // 	- Continuous age and income
**************************************************************** 
use "Data/mls-data06-scales", clear

******
// Drop for missing on DV
******
count
local N `r(N)'
drop if missing(socdistSS)
local ndrop `r(N_drop)'
di `ndrop'
di 		`ndrop'/`N' // 3.28% of sampled dropped


******
// Imputation
******

local mvs "L_mentlillB cntct_tot cntct_so4 cntct_val4 cntct_so3 cntct_val3"
local mvs "`mvs' vigdrug vigalc vigschiz vigdep"
local mvs "`mvs' age ageQ female race region metro coninc conincQ degree year"
local mvs "`mvs' a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
misstable summarize `mvs'
misstable patterns 	`mvs'

*MI impute won't impute the "soft missings" that are >.
local miss "age degree L_mentlillB cntct_tot cntct_so4 cntct_val4 cntct_so3 cntct_val3"
local miss "`miss' a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local miss "`miss' cntct_so96 cntct_slf96 cntct_oth96 cntct_so06 cntct_slf06 cntct_oth06"
local miss "`miss' cntct_so18 cntct_slf18 cntct_oth18"
foreach v in `miss' {
	replace `v' = . if `v' >= .
	}
	
mi 	set wide
mi  register imputed 	age degree L_mentlillB cntct_tot cntct_so4 cntct_val4 ///
						cntct_so3 cntct_val3 coninc a_imbalnceR 
*						a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR
mi 	register regular 	female race region srcbelt wrkstat

*Trial run to see all is OK and how many imputations to make

*	(logit) a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR ///

set seed 912663
mi 	impute chained ///
	(pmm, knn(5)) age coninc ///	
	(ologit) L_mentlillB degree ///
	(logit, omit(i.cntct_so3 i.cntct_so4 i.cntct_val3 i.cntct_val4)) cntct_tot ///
	(mlogit, omit(i.cntct_tot i.cntct_val3 i.cntct_val4 i.cntct_so3)) cntct_so4 ///
	(mlogit, omit(i.cntct_tot i.cntct_so3 i.cntct_so4 i.cntct_val3)) cntct_val4 ///
	(mlogit, omit(i.cntct_tot i.cntct_val3 i.cntct_val4 i.cntct_so4)) cntct_so3 ///
	(mlogit, omit(i.cntct_tot i.cntct_so3 i.cntct_so4 i.cntct_val4)) cntct_val3 ///	
	= female i.race i.region i.srcbelt i.wrkstat, ///
	add(20) force augment dots rseed(912663)

*Examine imputations (all look reasonable)
foreach imp of numlist 1 20 {
	fre 	_`imp'_L_mentlillB 		if L_mentlillB == .	
	fre 	_`imp'_degree 			if degree == .	
*	fre 	_`imp'_a_imbalnceR		if a_imbalnceR == .
	fre 	_`imp'_cntct_tot 		if cntct_tot == .	
	fre 	_`imp'_cntct_so4 		if cntct_so4 == .	
	fre 	_`imp'_cntct_val4 		if cntct_val4 == .	
	sum 	_`imp'_age 				if age == ., d
	sum 	_`imp'_coninc			if coninc == ., d
	}

list year id if _1_age >= .
drop if year == 2006 & id == 231	
	
*How many imputations? (based on von Hippel 2018)
*	Need to first estimate model
mi est: reg socdistSS	i.L_mentlillB i.year i.cntct_tot ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree
how_many_imputations

* Set sample weights *
mi svyset sampcode [pw = wtssnr]
	
** Label and save data **
compress
label data "MLS - GSS Data | Matching Labeling Stigma | Multiple Imputation CE | `tag'"
datasignature set, reset
save	 "Data/mls-data07-mice-cont",  replace	


/* 
****************************************************************
 // #3A Create a multiple imputation dataset.
 // 	- Quartile (ordinal) age and income
**************************************************************** 
use "Data/mls-data06-scales", clear

*Drop for missing on DV
drop if missing(socdistSS)
di 		66/3958 	// ~1.67% of sampled dropped

local mvs "L_mentlillB cntct_tot vigdrug vigalc vigschiz vigdep"
local mvs "`mvs' age ageQ female race region metro coninc conincQ degree year"
misstable summarize `mvs'
misstable patterns 	`mvs'

*MI impute won't impute the "soft missings" that are >.
local miss "age degree L_mentlillB cntct_tot"
foreach v in `miss' {
	replace `v' = . if `v' >= .
	}
	
mi 	set wide
mi  register imputed ageQ degree L_mentlillB cntct_tot conincQ
mi 	register regular female race region srcbelt wrkstat

*Trial run to see all is OK and how many imputations to make
mi 	impute chained ///
	(ologit) ageQ conincQ L_mentlillB degree ///
	(logit) cntct_tot ///
	= female i.race i.region i.srcbelt i.wrkstat, ///
	add(5) force augment dots rseed(912663)

*Examine imputations (all look reasonable)
fre 	*L_mentlillB 	if L_mentlillB == .	
fre 	*degree 		if degree == .	
fre 	*cntct_tot 		if cntct_tot == .	
fre 	*ageQ 			if ageQ == .
fre 	*conincQ		if conincQ == .


*How many imputations? (based on von Hippel 2018)
*	Need to first estimate model
mi est: reg socdistSS 	i.L_mentlillB i.year i.cntct_tot ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						i.ageQ i.female i.race i.region i.metro i.conincQ i.degree
how_many_imputations

*Adding 15 as larger # required across two imputations
mi 	impute chained ///
	(ologit) ageQ conincQ L_mentlillB degree ///
	(logit) cntct_tot ///
	= female i.race i.region i.srcbelt i.wrkstat, ///
	add(15) force augment dots rseed(912663)
	

* Set sample weights *
mi svyset sampcode [pw = wtssnr]
	
** Label and save data **
compress
label data "MLS - GSS Data | Matching Labeling Stigma | Multiple Imputation CE | `tag'"
datasignature set, reset
save	 "Data/mls-data07-mice-ordinal",  replace	
*/


************* 
log close
exit
*************

NOTES:
 
  
