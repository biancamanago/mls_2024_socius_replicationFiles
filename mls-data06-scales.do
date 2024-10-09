capture log close
log using "mls-data06-scales", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-data06-scales.do
 local dte   2021-01-08 
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
// #1 Load Data
**************************************************************** 
 
 use "Data/mls-data05-missing", clear
 
****************************************************************
// #2 STIGMA SCALES
****************************************************************
 
// examine scale

	local socdist "s_nextdoor s_social s_friends s_work s_marry s_grphome"
	fre `socdist'
	factor `socdist', factor(4) blanks(.4) pcf
		rotate, oblique quartimin blanks(.4)
	
	alpha `socdist', item label asis 
 
 
******
/// Scale as created in past GSS papers
****** 
	local socdist "s_nextdoor s_social s_friends s_work s_marry s_grphome"

	egen socdist_scl=rowmean(`socdist')
	egen socdist_tot=rowtotal(s_*DK1), missing
 
**********
/// PRIMARY/TDM
**********	

* PRIMARY/TDM version
*	Leaving "don't know" as missing. Using anyone who answered >= half the
*	items. Taking mean of answered items as score
alpha 	s_nextdoor s_social s_friends s_work s_marry s_grphome, ///
		item gen(socdistSS) min(3)
lab var socdistSS "Social distance sum scale"
lab val socdistSS LABHJ
fre 	socdistSS

	
**************************************************************** 
// OTHER
****************************************************************	
	
**********
/// Social Desirability
**********	
sum 	d_mistake d_forgive d_myway d_diffideas d_hurt d_gossip d_advantage
	
pwcorr 	d_mistake d_forgive d_myway d_diffideas d_hurt d_gossip d_advantage
	     
alpha   d_mistake d_forgive d_myway d_diffideas d_hurt d_gossip d_advantage, ///
	    item gen(socdesSS) min(4)
   	   						  
lab var socdesSS "Social Desirability: Scale"	
	
	sum socdesSS, d	
	
	
****************************************************************
// #3 Close
**************************************************************** 
	
save "Data/mls-data06-scales", replace
	

log close
exit	
