capture log close
log using "mls-do04-contactBaseline", replace text
 
 
**********
//#0 Setup	
**********	
 
 version 17
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-do04-contactBaseline.do
 local dte   2021-03-03
 local who   bianca manago - trent mize
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
//#1 Load Data
**************************************************************** 
 
use "Data/mls-data07-mice-cont", clear	
	
****************************************************************
//#4 Baseline effects of different forms of contact
****************************************************************

// Table 3: Effects of Contact on Rates of Labeling //	

mi est, post: 	logit L_mentlillB i.cntct_tot 
est store c_tot
mimrgns, 	dydx(cntct_tot) predict(pr)

mi est, post: 	logit L_mentlillB i.cntct_tot i.year  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree
mimrgns, 	dydx(cntct_tot) predict(pr)


*self vs other contact
mi est, post: 	logit L_mentlillB i.cntct_so4
est store c_so
mimrgns		cntct_so4, predict(pr)
mimrgns		cntct_so4, predict(pr) pwcompare(pve)

mi est, post: 	logit L_mentlillB i.cntct_so4 i.year  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree 

mimrgns		cntct_so4, predict(pr)
mimrgns		cntct_so4, predict(pr) pwcompare(pve)


*valence of contact
mi est, post: 	logit L_mentlillB i.cntct_val4
est store c_val
mimrgns		cntct_val4, predict(pr)
mimrgns		cntct_val4, predict(pr) pwcompare(pve)

mi est, post: 	logit L_mentlillB i.cntct_val4  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree 

mimrgns		cntct_val4, predict(pr)
mimrgns		cntct_val4, predict(pr) pwcompare(pve)


*Coefs (note Table A3 shows the MEs from above)
esttab c_tot c_so c_val, b(3) se(3) label ///
		keep(1.cntct_tot 1.cntct_so4 2.cntct_so4 3.cntct_so4 ///
			 1.cntct_val4 2.cntct_val4 3.cntct_val4) ///
		star(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
		
esttab c_tot c_so c_val using "Tables/mls-do04-labeling_by_contact_2024-09-26.rtf", replace ///
		b(3) se(3) label ///
		keep(1.cntct_tot 1.cntct_so4 2.cntct_so4 3.cntct_so4 ///
			 1.cntct_val4 2.cntct_val4 3.cntct_val4) ///
		star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
		title("Table 3: Effects of contact on labeling")


// Table 4: Effects on Stigma //

*binary any contact
mi est: reg socdistSS 	i.cntct_tot
		
mi est, post: reg socdistSS 	i.cntct_tot i.L_mentlillB i.year  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree		
est store sc_tot
	
*separate out self vs other contact	
mi est (diff: _b[1.cntct_so4] - _b[2.cntct_so4]): ///
		reg socdistSS i.cntct_so4 i.year
mi testtransform diff

mi est (diff: _b[1.cntct_so4] - _b[2.cntct_so4]), post: ///
		reg socdistSS 	i.cntct_so4 i.L_mentlillB i.year  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree	
est store sc_so
mi testtransform diff

*separate out by valence of contact
mi est (diff: _b[1.cntct_val4] - _b[2.cntct_val4]): ///
		reg socdistSS 	i.cntct_val4 i.year
mi testtransform diff
	
mi est (diff: _b[1.cntct_val4] - _b[2.cntct_val4]), post: ///
		reg socdistSS 	i.cntct_val4 i.L_mentlillB i.year  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree	
est store sc_val
mi testtransform diff
	
*Table A4	
esttab sc_tot sc_so sc_val, b(3) se(3) ///
		keep(1.cntct_tot 1.cntct_so4 2.cntct_so4 3.cntct_so4 ///
			 1.cntct_val4 2.cntct_val4 3.cntct_val4) ///
		star(+ 0.10 * 0.05 ** 0.01 *** 0.001)
esttab sc_tot sc_so sc_val using "Tables/mls-do04-stigma_by_contact_2024-09-26.rtf", replace ///
		b(3) se(3) label nogaps ///
		keep(1.cntct_tot 1.cntct_so4 2.cntct_so4 3.cntct_so4 ///
			 1.cntct_val4 2.cntct_val4 3.cntct_val4) ///
		star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
title("Table 4: Effects of contact on stigma, with different measures of contact (N = 3,920)")
		

*****************	
	log close
	exit
*****************	
			
