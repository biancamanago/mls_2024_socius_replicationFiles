 use "Data/mls-data03-scales", clear
 // Trent - I (bnm) changed the order of the cleaning files to improve workflow
 // in so doing, the final file went from being names data03-missing to 03-scales
 // the variables did not change. I changed this in your file ^. I hope that's okay.
 
 // You may want to change i.south to i.south3 as I'm pretty sure this is the way
 // Martin recoded it, income to income91, and age to age10 (see basic analyses).
 
 
*******************************************************************
// Recreate Martin 2000 JHSB analyses but use all years
*******************************************************************

local cond   "i.vigdrug i.vigalc i.vigschiz i.vigdep"
local att   "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age i.female i.white i.south size income educ i.cntct_tot"

*Try for all years (main effect that appears mediated by violent_oth)
reg socdist_tot i.L_mentlillB i.year `cond' `demog' 	// no attributions
reg socdist_tot i.L_mentlillB i.year `cond' `demog' `att'
reg socdist_tot i.L_mentlillB i.violent_oth i.year `cond' `demog' `att'

*Try a traditional nearest-neighbor matching
teffects nnmatch (socdist_tot i.year `cond' `demog' `att') ///
				(L_mentlillB), metric(mahalanobis) ///
				biasadj(i.year `cond' `demog' `att')	

teffects nnmatch (socdist_tot i.year `cond' `demog') ///
				(L_mentlillB), metric(mahalanobis) ///
				biasadj(i.year `cond' `demog')	
				
				
*Try inverse probability weighting	
teffects ipw (socdist_tot) ///
		(L_mentlillB i.year `cond' `demog' `att')
teffects ipw (socdist_tot) ///
		(L_mentlillB i.year `cond' `demog')
		
*Try to come up with a good propensity score model
// Generating variables to examine the matched cases
teffects psmatch (socdist_tot) ///
				(L_mentlillB i.year `cond' `demog' `att'), ///
				caliper(0.10) gen(match)
		
*Predict propensity score for being in each group for every ob.		
predict ps0 ps1, ps		
lab var ps0 "Pr Control(t=0)"
lab var ps1 "Pr Treated(t=1)"

predict psdist*, dist 
lab var	psdist1 "Nearest Neighbor 1 PS Distance"
sum		psdist1
*Histogram nicely shows that most everyone is very closely matched
hist 	psdist1

// Check overlap of propensity scores for each group
*	(assumptions are violated if no overlaps, or all cases cluster at 0 or 1)
teffects overlap	
tebalance density	// Both original and matched; seems to have done great

// Stata 14 now has commands to check the balance - but no test stat in 
* matching estimators
tebalance summarize


// Stata commands don't have a nice way to check the balance after matching,
*	so using the user-written "psmatch2" to do this
local cond   "i.vigdrug i.vigalc i.vigschiz i.vigdep"
local att   "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog  "age i.female i.white i.south size income educ"
qui logit 	L_mentlillB i.year `cond' `demog' `att'
predict 	ps, pr

set linesize 90
psmatch2 	L_mentlillB i.year `cond' `demog' `att', ///
			outcome(socdist_tot) logit caliper(0.1) ate ties ai(1)

**Shows t-tests for whether covariates are balanced before and after matching
**"graph" option makes the nifty balance plots	
*	Tests show a lot of imbalance remains (though these tests are controversial)		
pstest 		i.year `cond' `demog' `att', ///
			both treated(_treated) graph label


				
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
	
	
