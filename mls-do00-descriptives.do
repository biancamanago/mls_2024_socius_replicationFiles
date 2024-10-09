capture log close
log using "mls-do00-descriptives", replace text
 
 
**********
//#0 Setup	
**********	
 
 version 17
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-do00-descriptives.do
 local dte   2021-03-03
 local who   bianca manago - trent mize
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
//#1 Load Data
**************************************************************** 
 
use "Data/mls-data07-mice-cont", clear	

 
****************************************************************
//#2 Descriptives + tables
****************************************************************

*Figure A4: DV distribution
hist socdistSS, percent xlab(1(.5)4) ///
	ytitle("Percent of sample") ///
	xtitle("Social distance summated (and averaged) scale")

	graph export "Graphs/mls-do00-hist_socdistSS.png", replace
*	graph export "Graphs/mls-do00-hist_socdistSS.emf", replace
	
	
*Table 1: Desctable can calculate MI stats
local dv "socdistSS" 
local iv "i.L_mentlillB" 
local cvs "i.cntct_tot i.cntct_so4 i.cntct_val4"
local cvs "`cvs' age i.female i.race i.region i.metro coninc i.degree"
local evs "i.vignorm i.vigdrug i.vigalc i.vigschiz i.vigdep i.year"

sum 	`dv' `iv' `evs' `cvs'
desctable `dv' `iv' `evs' `cvs', file("Tables/mls-do00-descriptives-ALL_2024-09-26") ///
	stat(mimean misemean)



*Year specific tables
local cond      "i.vigdrug i.vigalc i.vigschiz i.vigdep"
local att       "a_imbalnceR a_geneticsR a_stressesR a_wayraiseR a_charactrR a_godswillR"
local demog     "age i.female i.white i.south xnorcsiz educ "
local demog1996 "`demog' income91"
local demog2006 "`demog' income06"
local demog2018 "`demog' income16"


local year "1996 2006 2018"
foreach y in `year' {	
	di ". sum `demog`y'' `cond' socdist_tot cntct_tot if year==`y'"
	sum `demog`y'' `cond' socdist_tot cntct_tot if year==`y'
	}

local year "1996 2006 2018"
foreach y in `year' {	
	desctable `demog`y'' `cond' socdist_tot cntct_tot if year==`y',  ///
		filename("Tables/mls-do00-descriptives-`y'") ///
		notes("The 'south' includes Delaware, Maryland, West Virginia," ///
		      "Virginia, North Carolina, South Carolina, Georgia, Florida,"  ///
			  "District of Columbia, Kentucky, Tennessee, Alabama, Mississippi." ///
			  "Income measured categeorically and accounts for inflation, by year." ///
			  "In 1996, ranges from <1k (1) to 75k+ (21)." ///
			  "In 2006, ranges from <1k (1) to 150k+ (25)." ///
			  "In 2018, ranges from <1k (1) to 170k+ (27).")
}	
	
	
// contact descriptives
mi est: prop cntct_tot

fre cntct_so4 if year != 2006

fre cntct_val4 if year == 2006

	
****************************************************************
****************************************************************	
tabstat L_mentlillB if year==1996, by(cond)
tabstat L_mentlillB if year==2006, by(cond)
tabstat L_mentlillB if year==2018, by(cond)
*MICE estimates of mean all but identical
mi est: mean L_mentlillB if vignorm
mi est: mean L_mentlillB if vigdep
mi est: mean L_mentlillB if vigschiz
mi est: mean L_mentlillB if vigalc
mi est: mean L_mentlillB if vigdrug

mi est: svy: logit L_mentlillB i.cond
mimrgns cond, predict(pr)
mimrgns cond, pwcompare(pve) predict(pr)


forval n=1/5 {
	local label : label (cond) `n'
	di in red "Condition is `label'"
	qui mi est: svy: logit L_mentlillB i.year if cond==`n'
	mimrgns year, predict(pr)
	mimrgns year, pwcompare(pve) predict(pr)
}

*Rates of labeling pooling across years
cibar L_mentlillB, over1(cond) ///
	graphop(ylab(0(.2)1) ytitle("Pr(Labeled as Mental Illness)") ///
	legend(pos(6) row(1))) bargap(10)
	
	*graph export "Graphs/mls-do00-01A-pr_labeled_by_vignette.emf", replace
	graph export "Graphs/mls-do00-01A-pr_labeled_by_vignette.png", replace

	
*Figure 2: Rates of labeling broken out by year
cibar L_mentlillB, over1(year) over2(cond) ///
	graphop(ylab(0(.2)1) ytitle("Pr(Labeled as Mental Illness)") ///
	legend(pos(6) row(1)) note("NOTE: Drug addiction vignette not included in 2006.", span)) ///
	bargap(10)
	
	*graph export "Graphs/mls-do00-01B-pr_labeled_by_vignette.emf", replace
	graph export "Graphs/mls-do00-01B-pr_labeled_by_vignette.png", replace

	
*Balanceplots (Figure 1)
local dv "socdistSS" 
local iv "L_mentlillB" 
local cvs "i.cntct_tot i.female i.metro age coninc i.race i.region i.degree i.year "
local vvs "i.vigdrug i.vigalc i.vigschiz i.vigdep"

*Figure 1: Version for talks with titles
balanceplot `dv' `cvs', group(`iv')	nosort ///
	graphop( xtitle("% Standardized Difference") ///
	xlab(-60(20)60)  ///
	headings(1.cntct_tot = "{bf:Binary IVs}" age = "{bf:Continuous IVs}" ///
			 2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
			 1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///
	title("{bf:Figure 1}: Standardized differences in rates of labeling behavior as a mental illness", span) ///
	subtitle("Positive differences indicate higher rates of labeling as a mental illness") ///
	note("NOTES: (1) Ommitted reference categories are: no contact, male, not a metro, white, New England, < high school, and 1996.", span))

*	graph export "Graphs/mls-do00-02A-balanceplot_pooled_labeling.emf", replace
	graph export "Graphs/mls-do00-02A-balanceplot_pooled_labeling.png", replace
	
*Figure 1: Version for manuscript with titles removed		 
balanceplot `dv' `cvs', group(`iv')	nosort ///
	graphop( xtitle("% Standardized Difference") ///
	xlab(-60(20)60)   ///
	headings(1.cntct_tot = "{bf:Binary IVs}" age = "{bf:Continuous IVs}" ///
			 2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
			 1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///
	title("") subtitle("") ///
	note("NOTES: (1) Positive differences indicate higher rates of labeling as a mental illness." ///
		 "(2) Ommitted reference categories are: no contact, male, not a metro, white, New England, < high school, and 1996.", span))

*	graph export "Graphs/mls-do00-02B_balanceplot_pooled_labeling.emf", replace	
	graph export "Graphs/mls-do00-02B_balanceplot_pooled_labeling.png", replace
	

*Separately by vignette (Figure 3)
local dv "socdistSS" 
local iv "L_mentlillB" 
local cvs "i.cntct_tot i.female i.metro age coninc i.race i.region i.degree i.year "
	
foreach v of numlist 1(1)5 {
	balanceplot `dv' `cvs' if cond == `v', group(`iv')
	mat 		vig`v' = r(bias1)
	}	

*Figure 3: Version for talks with titles	
coefplot (matrix(vig1[,4])) (matrix(vig2[,4])) ///
	(matrix(vig3[,4])) (matrix(vig4[,4])) (matrix(vig5[,4])), ///
	xline(0) drop(socdistSS) xtitle("% Standardized Difference") ///
	xlab(-60(20)60) legend(order(2 "Normal Troubles" 4 "Depression" ///
		6 "Schizophrenia" 8 "Alcohol Addiction" 10 "Drug Addiction") pos(6) row(1)) /// 
	headings(1.cntct_tot = "{bf:Binary IVs}" age = "{bf:Continuous IVs}" ///
			 2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
			 1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///	
	ysize(4) xsize(6.5) ///
	title("{bf:Figure 2}: Standardized differences in rates of labeling behavior as a mental illness", span) ///
	note("NOTES: (1) Positive differences indicate higher rates of labeling as a mental illness." ///
		 "(2) Ommitted reference categories are: no contact, male, not a metro, white, New England, < high school, and 1996." ///
		 "(3) There was no drug addiction vignette in 2006.", span)

	* graph export "Graphs/mls-do00-03A-balanceplot_pooled_labeling.emf", replace

	
*Figure 3: Version for manuscript with titles removed	
coefplot (matrix(vig1[,4])) (matrix(vig2[,4])) ///
	(matrix(vig3[,4])) (matrix(vig4[,4])) (matrix(vig5[,4])), ///
	xline(0) drop(socdistSS) xtitle("% Standardized Difference") ///
	xlab(-60(20)60) legend(order(2 "Normal Troubles" 4 "Depression" ///
		6 "Schizophrenia" 8 "Alcohol Addiction" 10 "Drug Addiction")) /// 
	headings(1.cntct_tot = "{bf:Binary IVs}" age = "{bf:Continuous IVs}" ///
			 2.race = "{bf:Race}" 2.region = "{bf:Region}" ///
			 1.degree = "{bf:Education}" 2006.year = "{bf:Survey Year}") ///	
	title("") subtitle("") ysize(4) xsize(6.5) ///
	note("NOTES: (1) Positive differences indicate higher rates of labeling as a mental illness." ///
		 "(2) Ommitted reference categories are: no contact, male, not a metro, white, New England, < high school, and 1996." ///
		 "(3) There was no drug addiction vignette in 2006.", span)

*	graph export "Graphs/mls-do00-03B-balanceplot_pooled_labeling.emf", replace
	graph export "Graphs/mls-do00-03B-balanceplot_pooled_labeling.png", replace



*****************	
	log close
	exit
*****************	
	
	
