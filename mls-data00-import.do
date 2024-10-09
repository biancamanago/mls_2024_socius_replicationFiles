capture log close
log using "mls-data00-import", replace text
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm
 
 set seed     1234
 set sortseed 1234

 local pgm   mls-data00-import.do
 local dte   2021-01-08 
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"


****************************************************************
// #1 Load Data
****************************************************************
use "Data/GSS7218_R1", clear


	local year "year == 1996 | year == 2006 | year == 2018"	
	
	local meta    "year id ballot vigversn version form issp formwt cohort sampcode"
	local meta    "`meta' sample oversamp phase wtss wtssnr wtssall vstrat vpsu"
	local demog   "marital wrkstat age educ degree sex race born income coninc wrkstat"
	local demog   "`demog' income91 income06 income16 region  size xnorcsiz"
	local demog	  "`demog' childs srcbelt polviews"
	local contact "evmhp evbrkdwn brkddur diagnosd mhtrtoth mhtrtslf mhtreatd"
	local contact "`contact' mhdiagno  knwpatnt knwmhosp mhtrtot2 "
	local contact "`contact' mhtrtoth mhothyou mhothrel"
	local socdes  "mcsds* myprobs*"
	local att     "charactr imbalnce wayraise stresses genetics godswill"
	local att     "`att' upsdowns breakdwn mentlill physill " // omitted: viglabel
	local fear    "hurtoth hurtself dangrslf dangroth"
	local socdist "vignei vigsoc vigfrnd vigwork viggrp vigmar"
	local med     "mustdoc mustmed musthosp meddoc mentldoc"
	local med     "`med' selfhelp otcmed rxmed mentlhos"
	local med     "`med' imprvown imprvtrt"
	local vars    "`meta' `demog' `contact' `mh' `socdes' `att' `fear' `socdist' `med'"	
	
	use `vars' if `year' using "Data/GSS7218_R1", clear
	
	
// Keep Rs who received the mental health module
// In 2018, the module was included on Ballot B (form Y only) and Ballot C 
// (both forms)


	*drop if vigversn==.i
	*count
	// Both this ^ method and the one below produce 4,140. 
	// Keeping one below because it has additional detail

keep if (year == 1996 & version<=6 & version >= 4) | ///
        (year == 2006 & version<=3 & version >= 1) | ///
		(year == 2018 & version==3 | (ballot==2 & form == 2 & year == 2018))
		
	count

	la var vigversn "Vignette Version #"

	
// Set weights in case we want to use later!
	
	svyset [pw=wtssall]

	g vig_y96 = year == 1996
		la var vig_y96 "Vignette Year is 1996"
	g vig_y06 = year == 2006
		la var vig_y06 "Vignette Year is 2006"
	g vig_y18 = year == 2018	
		la var vig_y18 "Vignette Year is 2018"
		
	la val vig_y* yesno	
	
****************************************************************
// # Save and Close Out
****************************************************************

save "Data/mls-data00-import", replace

log close
exit
