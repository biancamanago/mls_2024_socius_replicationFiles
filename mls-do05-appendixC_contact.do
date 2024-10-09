capture log close
log using "mls-do05-appendixC_contact", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-do05-appendixC_contact.do
 local dte   2023-12-26
 local who   bianca manago - trent mize
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
//#1 Load Data
**************************************************************** 
 
 use "Data/mls-data08-mice-contact_valence", clear	
 
 
 /* 
Using a different dataset because we didn't need all of these measures
in the main dataset and we'd need to re-do all the bootstrap analyses
which take hours.
*/
 
****************************************************************
//#4 Baseline effects of different forms of contact
****************************************************************

// C1 Combined Table

local c_val "cntct_val4_DER_max cntct_val4_D_max"
local c_val "`c_val' cntct_val4_DER_avg cntct_val4_D_avg"	

foreach v in `c_val' {
// Table A3: Effects of Contact on Rates of Labeling //	
*valence of contact
mi est, post: 	logit L_mentlillB i.`v'
est store   `v'
mimrgns		`v', predict(pr)
mimrgns		`v', predict(pr) pwcompare(pve)

mi est, post: 	logit L_mentlillB i.`v'  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree 

mimrgns		`v', predict(pr)
mimrgns		`v', predict(pr) pwcompare(pve)
}

*Coefs (note Table C1 shows the MEs from above)
esttab cntct_val4_DER_max cntct_val4_D_max cntct_val4_DER_avg cntct_val4_D_avg ///
        using "Tables/c1_labeling_by_contact.rtf", replace /// 
		b(3) se(3) label ///
		keep(1.cntct_val4_DER_max 2.cntct_val4_DER_max 3.cntct_val4_DER_max       ///
			 1.cntct_val4_D_max   2.cntct_val4_D_max   3.cntct_val4_D_max   ///
		     1.cntct_val4_DER_avg 2.cntct_val4_DER_avg 3.cntct_val4_DER_avg       ///
			 1.cntct_val4_D_avg   2.cntct_val4_D_avg   3.cntct_val4_D_avg)   ///
		star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
title("Table #: Effects of contact on stigma, with different measures of contact (N = 3,920)")
		
// C2 combined table
			
local c_val "cntct_val4_DER_max cntct_val4_D_max"
local c_val "`c_val' cntct_val4_DER_avg cntct_val4_D_avg"			
			
foreach v in `c_val' {		
*separate out by valence of contact
mi est (diff: _b[1.`v'] - _b[2.`v']): ///
		reg socdistSS 	i.`v' i.year
mi testtransform diff
	
mi est (diff: _b[1.`v'] - _b[2.`v']), post: ///
		reg socdistSS 	i.`v' i.L_mentlillB i.year  ///
						i.vigdrug i.vigalc i.vigschiz i.vigdep ///
						age i.female i.race i.region i.metro coninc i.degree	
est store s`v'
mi testtransform diff
}	
	
*Table C2	
esttab scntct_val4_DER_max scntct_val4_D_max scntct_val4_DER_avg scntct_val4_D_avg ///
        using "Tables/c2_stigma_by_contact.rtf", replace ///
		b(3) se(3) label  ///
		keep(1.cntct_val4_DER_max 2.cntct_val4_DER_max 3.cntct_val4_DER_max       ///
			 1.cntct_val4_D_max   2.cntct_val4_D_max   3.cntct_val4_D_max   ///
		     1.cntct_val4_DER_avg 2.cntct_val4_DER_avg 3.cntct_val4_DER_avg       ///
			 1.cntct_val4_D_avg   2.cntct_val4_D_avg   3.cntct_val4_D_avg)   ///
		star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
title("Table #: Effects of contact on stigma, with different measures of contact (N = 3,920)")
		
	
	
// close out
log close
exit
