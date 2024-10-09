capture log close
log using "mls-data08-contact_valence", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 17.0
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-data08-contact_valence.do
 local dte   2024-09-25 
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
 // #1 Load Data
**************************************************************** 	
	
use "Data/mls-data06-scales", clear	

****************************************************************
// #2
****************************************************************

/* 
Didn't need these variables in the main dataset. Re-doing all of the
bootstrapping takes hours, so we created a subset of the data for these
analyses for Appendix C.
*/

	sum myprobs*			
	
	egen myprob_max = rowmax(myprobs*)
	egen myprob_avg = rowmean(myprobs*)
	
	sum myprob*
	
	recode myprob_max (1=0 "None") (1.000001/10=1 "Some"), gen(c_effect_any)
	
	la var c_effect_any "Any distress from any friends with MH"
	
	recode myprob_max (0/4.181818=0 "Low") ///
	                  (4.181819/10=1 "High"), gen(c_effect_gtmaxavg)
					  
	la var c_effect_gtmaxavg "GT max avg distress from friends with MH"				  
	
	recode myprob_avg (0/3.07514=0 "Low") ///
	                  (3.07515/10=1 "High"), gen(c_effect_gtavg)
					  
	la var c_effect_gtavg "GT avg distress from friends with MH"					  
					  
	fre c_effect_any
	fre c_effect_gtmaxavg
	fre c_effect_gtavg
	
	tab c_effect_gtavg c_effect_gtmaxavg, cell
	
	
	la var c_effectR "Relationship Consequences of MI"
	
	fre c_*
	
	replace c_effectR=.y if year!=2006
	replace c_effectY=.y if year!=2006
	
						  
	replace c_effect_any=.y if year!=2018
	replace c_effect_gtmaxavg=.y if year!=2018
	replace c_effect_gtavg=.y if year!=2018
	
	// var for the valence of contact (only in 06 survey). Ccoding it as 
*	bad contact if it caused distress and/or had neg relationship consequences


lab def cv4lab 0"No Contact" 1"Any Contact" 2"Bad Contact" 3"Good Contact", replace

gen 	cntct_val4_DER_max = cntct_tot
lab var cntct_val4_DER_max "Contact with valence - max/avg 2018 measure"
replace cntct_val4_DER_max = 3 if cntct_tot == 1 & year == 2006
replace cntct_val4_DER_max = 2 if c_effectY == 3 | c_effectY == 4
replace cntct_val4_DER_max = 2 if c_effectR == 3 
replace cntct_val4_DER_max = 2 if c_effect_gtmaxavg == 1 
replace cntct_val4_DER_max = 3 if c_effect_gtmaxavg == 0 
lab val cntct_val4_DER_max cv4lab
fre 	cntct_val4_DER_max
tab 	cntct_val4_DER_max cntct_tot, miss


gen 	cntct_val4_D_max = cntct_tot
lab var cntct_val4_D_max "Distress and Contact w/ valence - max/avg 2018 measure"
replace cntct_val4_D_max = 3 if cntct_tot == 1 & year == 2006
replace cntct_val4_D_max = 2 if c_effectY == 3 | c_effectY == 4
replace cntct_val4_D_max = 2 if c_effect_gtmaxavg == 1 
replace cntct_val4_D_max = 3 if c_effect_gtmaxavg == 0
lab val cntct_val4_D_max cv4lab
fre 	cntct_val4_D_max
tab 	cntct_val4_D_max cntct_tot, miss


gen 	cntct_val4_DER_avg = cntct_tot
lab var cntct_val4_DER_avg "Contact with valence - mean/avg 2018 measure"
replace cntct_val4_DER_avg = 3 if cntct_tot == 1 & year == 2006
replace cntct_val4_DER_avg = 2 if c_effectY == 3 | c_effectY == 4
replace cntct_val4_DER_avg = 2 if c_effectR == 3 
replace cntct_val4_DER_avg = 2 if c_effect_gtavg == 1 
replace cntct_val4_DER_avg = 3 if c_effect_gtavg == 0
lab val cntct_val4_DER_avg cv4lab
fre 	cntct_val4_DER_avg
tab 	cntct_val4_DER_avg cntct_tot, miss


gen 	cntct_val4_D_avg = cntct_tot
lab var cntct_val4_D_avg "Distress and Contact w/ valence - mean/avg 2018 measure"
replace cntct_val4_D_avg = 3 if cntct_tot == 1 & year == 2006
replace cntct_val4_D_avg = 2 if c_effectY == 3 | c_effectY == 4
replace cntct_val4_D_avg = 2 if c_effect_gtavg == 1 
replace cntct_val4_D_avg = 3 if c_effect_gtavg == 0 
lab val cntct_val4_D_avg cv4lab
fre 	cntct_val4_D_avg
tab 	cntct_val4_D_avg cntct_tot, miss

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

*MI impute won't impute the "soft missings" that are >.
local miss "age degree L_mentlillB cntct_tot cntct_so4"  
local miss "`miss' cntct_val4_DER_max cntct_val4_D_max"
local miss "`miss' cntct_val4_DER_avg cntct_val4_D_avg"
local miss "`miss' a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
foreach v in `miss' {
	replace `v' = . if `v' >= .
	}
	
mi 	set wide
mi  register imputed 	age degree L_mentlillB cntct_tot cntct_val4_DER_max cntct_val4_D_max ///
						cntct_val4_DER_avg cntct_val4_D_avg coninc a_imbalnceR
*						a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR
mi 	register regular 	female race region srcbelt wrkstat

*Trial run to see all is OK and how many imputations to make
	
	
set seed 912663
mi 	impute chained ///
	(pmm, knn(5)) age coninc ///	
	(ologit) L_mentlillB degree ///
	(logit,  omit(i.cntct_val4_DER_max i.cntct_val4_DER_avg i.cntct_val4_D_avg i.cntct_val4_D_max )) cntct_tot  ///
	(mlogit, omit(i.cntct_tot i.cntct_val4_DER_avg i.cntct_val4_D_avg i.cntct_val4_D_max)) cntct_val4_DER_max  ///
	(mlogit, omit(i.cntct_tot i.cntct_val4_DER_max i.cntct_val4_D_avg i.cntct_val4_D_max)) cntct_val4_DER_avg  ///
	(mlogit, omit(i.cntct_tot i.cntct_val4_DER_avg i.cntct_val4_DER_max i.cntct_val4_D_avg)) cntct_val4_D_max  ///
	(mlogit, omit(i.cntct_tot i.cntct_val4_DER_avg i.cntct_val4_DER_max i.cntct_val4_D_max)) cntct_val4_D_avg   ///
	= female i.race i.region i.srcbelt i.wrkstat, ///
	add(20) force augment dots rseed(912663)


*Examine imputations (all look reasonable)
foreach imp of numlist 1 20 {
	fre 	_`imp'_L_mentlillB 		    if L_mentlillB == .	
	fre 	_`imp'_degree 			    if degree == .	
*	fre 	_`imp'_a_imbalnceR		    if a_imbalnceR == .
	fre 	_`imp'_cntct_tot 		    if cntct_tot == .	
	fre 	_`imp'_cntct_val4_DER_max  	if cntct_val4_DER_max == .	
	fre 	_`imp'_cntct_val4_DER_avg 	if cntct_val4_DER_avg == .	
	fre 	_`imp'_cntct_val4_D_max 	if cntct_val4_D_max == .	
	fre 	_`imp'_cntct_val4_D_avg	    if cntct_val4_D_avg == .	
	sum 	_`imp'_age 				    if age == ., d
	sum 	_`imp'_coninc			    if coninc == ., d
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
save	 "Data/mls-data08-mice-contact_valence",  replace	

log close
exit

