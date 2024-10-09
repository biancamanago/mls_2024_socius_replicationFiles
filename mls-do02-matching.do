capture log close
log using "mls-do02-matching", replace text
 
 
**********
/// #0 Setup	
**********	

// MLS - Matching: Labeling & Stigma 
// Key causal matching analyses - multiple imputation data

 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 10000, perm

 
 local pgm   mls-do03-matching-analyses-mice.do
 local dte   2021-01-22
 local who   bianca manago - trent mize
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
 
****************************************************************
 // #1 - Load Data; descriptives
**************************************************************** 
use "Data/mls-data07-mice-cont", clear	

/*
local dv "socdistSS" 
local iv "i.L_mentlillB" 
local cvs "i.cntct_tot c.age i.female i.race i.region i.metro coninc i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"
mi est:  		mean 	`dv' `iv' `cvs' `evs'
mi est: svy: 	mean 	`dv' `iv' `cvs' `evs'
*/
tabstat 	L_mentlillB, by(cond)

*Check random assignment balance (balanced on all vars)
qui mlogit 	cond i.cntct_tot age i.female i.race i.region i.metro ///
			coninc i.degree i.year
mlogtest			
 			
			
*******************************************************************
// #2 - Nearest neighbor matching with exact matching on only
*		vignette and year
*******************************************************************		
local dv "socdistSS" 
local iv "L_mentlillB" 
local con "c.age##c.age coninc"		// Separate out continuous controls
local cvs "i.cntct_tot i.female i.metro i.race i.region i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"

*This is not for interpreting; just need to get the descriptives for the plot
qui teffects nnmatch (`dv' `evs' `cvs' `con') (`iv'), ///
						metric(mahalanobis) ///
						biasadj(`con')	
tebalance 	summarize
mat			balance = r(table)

*First, check the matching model before interpreting ATEs
* NOTE: Can't do this with the MICE data
qui teffects nnmatch (`dv' `cvs' `con') (`iv'), ///
						ematch(`evs') metric(mahalanobis) ///
						biasadj(`con')	
tebalance 	summarize
mat			balance2 = r(table)
matlist 	balance
matlist 	balance2

*Replace exact matched std diffs with zeroes
forvalues i = 1/6 {
	mat balance[`i',2] = 0
	}
matlist 	balance
*Replace mahalanobis distance matches vars with correct std diff in this model
local row2 = 1
forvalues i = 7/26 {
	mat balance[`i',2] = balance2[`row2',2]
	local ++row2
	}
	
*Figure A1
matlist balance

coefplot (matrix(balance[,1])) (matrix(balance[,2])), ///
	xline(0)  xtitle("Standardized Difference") ylab(,labsize(vsmall)) ///
	xlab(-.80(.20).80) legend(order(2 "Raw (unmatched)" 4 "Matched"))  ///
	headings(1.vigdrug = "{bf:Vignettes}" 1.cntct_tot = "{bf:Binary IVs}" ///
		age = "{bf:Continuous IVs}"  2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
		1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///
	title("") subtitle("") ///
	note("NOTES: (1) Ommitted reference categories are: normal ups and downs vignette, 1996, no contact, male," ///
		 "not a metro, white, New England, and < high school.", span)	

	graph export "Graphs/mls-do02-01-nn_match-balanceplot.png", replace			
	
	
	
/////////////////////////
// Table 2 (top panel) //	
/////////////////////////
	
local dv "socdistSS" 
local iv "L_mentlillB" 
local con "c.age##c.age coninc"		// Separate out continuous controls
local cvs "i.female i.metro i.race i.region i.degree i.cntct_tot"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"
	
	
*Nearest neighbor matching with exact match on year and vignettes
*Pooling over all four vignettes
mi est, cmdok: teffects nnmatch (`dv' `cvs' `con') (`iv'), ///
						ematch(`evs') metric(mahalanobis) ///
						biasadj(`con')	
					
						
*Separately for each vignette
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est, cmdok: teffects nnmatch (`dv' `cvs' `con') (`iv') ///
							if `v', ///
							ematch(`evs') metric(mahalanobis) ///
							biasadj(`con')	
	}	
	
	
	
*******************************************************************
// #3 - Nearest neighbor matching with exact matching on 
*		vignette, year, and contact
*******************************************************************		
	
// Also exact match on contact //
*	NOTE: Not enough overlap in data for exact matching on any additional vars
local dv "socdistSS" 
local iv "L_mentlillB" 
local con "c.age##c.age coninc"		// Separate out continuous controls
local cvs "i.female i.metro i.race i.region i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year i.cntct_tot"

*First, check the matching model before interpreting ATEs
* NOTE: Can't do this with the MICE data
qui teffects nnmatch (`dv' `cvs' `con') (`iv'), ///
						ematch(`evs') metric(mahalanobis) ///
						biasadj(`con')
tebalance 	summarize
mat			balance3 = r(table)
matlist 	balance
matlist 	balance3

*Replace exact matched std diffs with zeroes
mat 		balance[7,2] = 0
matlist 	balance
*Replace mahalanobis distance matches vars with correct std diff in this model
local row2 = 1
forvalues i = 8/26 {
	mat balance[`i',2] = balance3[`row2',2]
	local ++row2
	}
	
*Figure A2	
matlist balance

coefplot (matrix(balance[,1])) (matrix(balance[,2])), ///
	xline(0)  xtitle("Standardized Difference") ylab(,labsize(vsmall)) ///
	xlab(-.80(.20).80) legend(order(2 "Raw (unmatched)" 4 "Matched"))  ///
	headings(1.vigdrug = "{bf:Vignettes}" 1.cntct_tot = "{bf:Binary IVs}" ///
		age = "{bf:Continuous IVs}"  2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
		1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///
	title("") subtitle("") ///
	note("NOTES: (1) Ommitted reference categories are: normal ups and downs vignette, 1996, no contact, male," ///
		 "not a metro, white, New England, and < high school.", span)	

	graph export "Graphs/mls-do02-02-nn_match-balanceplot.png", replace	
	
	
/////////////////////////
// Table 2 (bottom panel) //	
/////////////////////////

local dv "socdistSS" 
local iv "L_mentlillB" 
local con "c.age##c.age coninc"		// Separate out continuous controls
local cvs "i.female i.metro i.race i.region i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year i.cntct_tot"

*Pooling over all four vignettes
mi est, cmdok: teffects nnmatch (`dv' `cvs' `con') (`iv'), ///
						ematch(`evs') metric(mahalanobis) ///
						biasadj(`con')
						
*Separately for each vignette
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est, cmdok: teffects nnmatch (`dv' `cvs' `con') (`iv') ///
							if `v', ///
							ematch(year cntct_tot) metric(mahalanobis) ///
							biasadj(`con')
	}						
		
		
*Bootstrap the cross-model difference in the schizophrenia vignette
capture program drop bs_crossmod
program define bs_crossmod, rclass
    
	mi est, cmdok: teffects nnmatch (socdistSS ///
					i.female i.race i.region i.metro i.degree ///
					c.age##c.age coninc) (L_mentlillB) ///
							if vigschiz, ///
							ematch(year) metric(mahalanobis) ///
							biasadj(c.age##c.age coninc)	
	mat 	temp1 = r(table)
	scalar 	ate_mod1 =  temp1[1,1]
	
	mi est, cmdok: teffects nnmatch (socdistSS ///
					i.female i.race i.region i.metro i.degree ///
					c.age##c.age coninc) (L_mentlillB) ///
							if vigschiz, ///
							ematch(year cntct_tot) metric(mahalanobis) ///
							biasadj(c.age##c.age coninc)
	mat 	temp2 = r(table)
	scalar 	ate_mod2 =  temp2[1,1]
	
	scalar 	diff = temp1[1,1] - temp2[1,1] 
	noisily di "Difference = " diff
	
	exit
end

*Need to only keep schizophrenia vignette for the bootstrap command
drop if vigschiz != 1

bootstrap ate_mod1 = ate_mod1 ate_mod2 = ate_mod2 diff = diff, ///
	saving(bs_ests-01-vigschiz-contact, replace) ///
	reps(1000) seed(962077) cformat(%6.4f): bs_crossmod
	

	
*Bootstrap the schizophrenia vs other illnesses ATE (H4)
use "Data/mls-data07-mice-cont", clear	

capture program drop bs_crossmod
program define bs_crossmod, rclass
    
	mi est, cmdok: teffects nnmatch (socdistSS ///
					i.female i.race i.region i.metro i.degree ///
					c.age##c.age coninc) (L_mentlillB) ///
							if vigdrug, ///
							ematch(year cntct_tot) metric(mahalanobis) ///
							biasadj(c.age##c.age coninc)
	mat 	tempdrug = r(table)
	scalar 	ate_drug =  tempdrug[1,1]

	mi est, cmdok: teffects nnmatch (socdistSS ///
					i.female i.race i.region i.metro i.degree ///
					c.age##c.age coninc) (L_mentlillB) ///
							if vigalc, ///
							ematch(year cntct_tot) metric(mahalanobis) ///
							biasadj(c.age##c.age coninc)
	mat 	tempalc = r(table)
	scalar 	ate_alc =  tempalc[1,1]
	
	mi est, cmdok: teffects nnmatch (socdistSS ///
					i.female i.race i.region i.metro i.degree ///
					c.age##c.age coninc) (L_mentlillB) ///
							if vigdep, ///
							ematch(year cntct_tot) metric(mahalanobis) ///
							biasadj(c.age##c.age coninc)
	mat 	tempdep = r(table)
	scalar 	ate_dep =  tempdep[1,1]
	
	mi est, cmdok: teffects nnmatch (socdistSS ///
					i.female i.race i.region i.metro i.degree ///
					c.age##c.age coninc) (L_mentlillB) ///
							if vigschiz, ///
							ematch(year cntct_tot) metric(mahalanobis) ///
							biasadj(c.age##c.age coninc)
	mat 	tempschiz = r(table)
	scalar 	ate_schiz =  tempschiz[1,1]
	
	scalar 	sch_v_drug = tempschiz[1,1] - tempdrug[1,1] 
	scalar 	sch_v_alc = tempschiz[1,1] - tempalc[1,1] 
	scalar 	sch_v_dep = tempschiz[1,1] - tempdep[1,1] 
	
	exit
end

*Briefly drop unincluded vignette for this analysis
drop if vignorm

bootstrap ate_drug = ate_drug ate_alc = ate_alc ate_dep = ate_dep ///
	ate_schiz = ate_schiz sch_v_drug = sch_v_drug sch_v_alc = sch_v_alc ///
	sch_v_dep = sch_v_dep, ///
	saving(bs_ests-01-vigschiz_vs_others, replace) ///
	reps(1000) seed(962077) cformat(%6.4f): bs_crossmod
	
		
		
*******************************************************************
// #4a - Sensitivity analyses with AIPW
*******************************************************************		
use "Data/mls-data07-mice-cont", clear	
	
local dv "socdistSS" 
local iv "L_mentlillB" 
local cvs "i.cntct_tot i.female i.metro i.race i.region i.degree c.age##c.age coninc"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"	
*Check the propensity score model
qui teffects aipw (`dv') (`iv' `evs' `cvs')
*tebalance overid // doesn't converge
		
teffects overlap, legend(order(1 "Did not label" 2 "Did label")) ///
	title("{bf:AIPW} Overlap plots -- Propensity score distributions by label (or not)") ///
	xtitle("Propensity score")
	
	graph export "Graphs/mls-AIPW-overlap.png", replace
	
tebalance summarize
mat	balance = r(table)
	
*Figure A3
matlist balance
	
coefplot (matrix(balance[,1])) (matrix(balance[,2])), ///
	xline(0)  xtitle("Standardized Difference") ylab(,labsize(vsmall)) ///
	xlab(-.80(.20).80) legend(order(2 "Raw (unmatched)" 4 "AIP Weighted"))  ///
	headings(1.vigdrug = "{bf:Vignettes}" 1.cntct_tot = "{bf:Binary IVs}" ///
		age = "{bf:Continuous IVs}"  2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
		1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///
	title("") subtitle("") ///
	note("NOTES: (1) Ommitted reference categories are: normal ups and downs vignette, 1996, no contact, male," ///
		 "not a metro, white, New England, and < high school.", span)	

	graph export "Graphs/mls-do02-03-AIPW-balanceplot.png", replace	

	
		
*Separately for each vignette
*	NOTE: overid test doesn't converge for vigschiz or vigdep
foreach v of varlist vignorm vigdrug vigalc {
	di _newline(1)
	di in red "Vignette is: `v'"
	qui teffects aipw (`dv') (`iv' `cvs' i.year) if `v'
	capture tebalance overid
	}
	
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	qui teffects aipw (`dv') (`iv' `cvs' i.year) if `v'

	teffects overlap, legend(order(1 "Did not label" 2 "Did label")) ///
	title("{bf:`v':} Overlap plots -- Propensity score distributions by label (or not)") ///
	xtitle("Propensity score")
	
		graph export "Graphs/mls-`v'-AIPW-overlap.png", replace

	tebalance summarize
	mat	balance = r(table)
	
	coefplot (matrix(balance[,1])) (matrix(balance[,2])), ///
	xline(0)  xtitle("Standardized Difference") ///
	xlab(-.60(.20).60) legend(order(2 "Raw (unweighted)" 4 "AIP Weighted")) ///
		sort graphregion(margin(l+5)) ///
	title("{bf:`v'}: Covariate standardized differences between labelers (and not)", span) ///
	subtitle("Raw (unweighted) vs AIP weighted data")

		graph export "Graphs/mls-`v'-AIPW-balanceplot.png", replace
	}	
	
	
local dv "socdistSS" 
local iv "L_mentlillB" 
local cvs "i.cntct_tot c.age##c.age i.female i.race i.region i.metro coninc i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"	
	
*Table A2 top panel: Augmented inverse probability weighting (doubly robust method)
mi est, cmdok: teffects aipw (`dv') (`iv' `cvs' `evs')

*Table A2 top panel: Separately for each vignette
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est, cmdok: teffects aipw (`dv') (`iv' `cvs' i.year) if `v'
	}	

	
	
*******************************************************************
// #4b - Sensitivity analyses with different contact measures
*******************************************************************	
use "Data/mls-data07-mice-cont", clear	

*Table A2 middle and bottom panels

*NOTE: Exact matching on self/other and valence contact measures not possible
*	because there are not enough exact matches. So, using AIPW for these
*	sensitivity analyses.
local dv "socdistSS" 
local iv "L_mentlillB" 
local cvs "c.age##c.age i.female i.race i.region i.metro coninc i.degree"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"	

		
*Augmented inverse probability weighting (doubly robust method)
mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_tot `cvs' `evs')
mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_so4 `cvs' `evs')
mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_val4 `cvs' `evs')

*Separately for each vignette (only works with 3-category measures)
foreach v of varlist vignorm vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_tot `cvs' i.year) if `v'
	mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_so3 `cvs' i.year) if `v'
	mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_val3 `cvs' i.year) if `v'
	}	
	
*Valence measure not in year with drug vignette	
mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_tot `cvs' i.year) if vigdrug
mi est, cmdok: teffects aipw (`dv') (`iv' i.cntct_so3 `cvs' i.year) if vigdrug
	
	
	
************************************************************
//#5 Sensitivty analysis matching on attributions
************************************************************	
// Exact matching on contact //
*	NOTE: Not enough overlap in data for exact matching on any additional vars
local dv "socdistSS" 
local iv "L_mentlillB" 
local con "c.age##c.age coninc"		// Separate out continuous controls
local cvs "i.female i.metro i.race i.region i.degree"
local att  "i.a_imbalnceR i.a_geneticsR i.a_stressesR i.a_wayraiseR i.a_charactrR i.a_godswillR"
local evs "i.vigdrug i.vigalc i.vigschiz i.vigdep i.year i.cntct_tot"

							
*Pooling over all four vignettes
mi est, cmdok: teffects nnmatch (`dv' `cvs' `con' `att') (`iv'), ///
						ematch(`evs') metric(mahalanobis) ///
						biasadj(`con')
						
*Separately for each vignette
foreach v of varlist vignorm vigdrug vigalc vigschiz vigdep {
	di _newline(1)
	di in red "Vignette is: `v'"
	mi est, cmdok: teffects nnmatch (`dv' `cvs' `con' `att') (`iv') ///
							if `v', ///
							ematch(year i.cntct_tot) metric(mahalanobis) ///
							biasadj(`con')
	}		
	
	
	
**************		
log close
exit
**************

NOTES:
				
				
/*				
*******************************************************************
// Is desired social distance affected by contact with mental illness? 
*******************************************************************

// BINARY CONTACT
local demog   "age i.degree i.female i.white i.south size income" // TDM added vars
local vig	  "i.vig_female i.vig_white"
local cont    "violent_oth violent_self"

	reg 	socdist_scl i.cntct_tot i.year
	reg   	socdist_scl i.cntct_tot i.year i.cond `demog' `vig' `cont'
	
	teffects nnmatch (socdist_tot i.year `demog' `vig' `cont') ///
				(cntct_tot), metric(mahalanobis) ///
				biasadj(i.year `demog' `vig' `cont')		

	*Try inverse probability weighting	
	teffects ipw (socdist_tot) ///
				(cntct_tot i.year `demog' `vig' `cont')		
				
	*TDM note: still need to do full diagnostics to check these matches
	teffects psmatch (socdist_tot) ///
				(cntct_tot i.year `demog' `vig' `cont'), ///
				caliper(0.10)			

	psmatch2 	cntct_tot i.year `demog' `vig' `cont', ///
				outcome(socdist_tot) logit caliper(0.1) ate ties ai(1)

	pstest 		i.year `demog' `vig' `cont', ///
				both treated(_treated) graph label			
	
*/	
