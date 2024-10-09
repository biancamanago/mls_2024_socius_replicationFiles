capture log close
log using "mls-data04-sort_order", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-data04-sort_order.do
 local dte   2021-01-08 
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
 // #1 Load Data
**************************************************************** 
		
	use "Data/mls-data03-contact_recode", clear
	
**************************************************************** 
// Reorganize
****************************************************************

local demog   "age age10 cohort cohort10 born educ ed_gths degree female"
local demog   "`demog' race south size white born income region  marital wrkstat"
 
local meta    "ballot version issp formwt sampcode sample oversamp"
local meta    "`meta' phase wtss wtssnr wtssall vstrat vpsu"
 
 order _all, alpha	
 order year id form cond* vig*, first
 order `meta', last	
 order `demog', before(ballot)
 order imp* must*, before(shld_dangroth)
	
**************************************************************** 
// Save
****************************************************************

	save "Data/mls-data04-sort_order", replace	

log close
exit	
	
	
