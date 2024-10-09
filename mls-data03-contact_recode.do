capture log close
log using "mls-data03-contact_recode", replace text
 
 
**********
/// #0 Setup	
**********	
 
 version 15.1
 set linesize 80
 clear all
 macro drop _all
 set matsize 100, perm

 
 local pgm   mls-data03-contact_recode.do
 local dte   2024-09-25 
 local who   bianca manago
 local tag   "`pgm'.do `who' `dte'"
 
 di "`tag'"
 
****************************************************************
 // #1 Load Data
**************************************************************** 
 
 use "Data/mls-data02-label_name_recode", clear
 
****************************************************************
// #2
****************************************************************

fre mhtrtoth mhothyou mhothrel


	local contact "evmhp evbrkdwn brkddur"
	local contact "`contact' diagnosd mhtrtoth mhtrtot2 mhtrtslf mhtreatd"
	local contact "`contact' knwpatnt knwmhosp mhdiagno"
	
	foreach v in `contact' {
		di in red ". tab `v' year, m"
		tab `v' year, m
		}
		
	/* All of the different GSS versions
	   use wildly different measures of contact...
	   in 2006 there is no measure of self contact,
	   however, in 1996 only 44 people, or 1% of the sample
	   reported having mental illness without knowing anyone
	   else with mental illness. (Another 32 people, or .77% 
	   of the sample, reported having mental illness
	   and knowing others with mental illness. There is another
	   ballot in 2006 that has measures of individuals' own mental
	   illness, but they weren't asked */
	   
	  **  if not sure - counted as no
	
**********
/// 1996	
**********	
/* From Codebook
Long-term
1. Long-term reaction (severe) -- extensive period mentioned in which R elaborates on a severe nervous feeling state. for months, I cried almost all the time
2. Long-term reaction (no very severe) -- extensive period mentioned in which R elaborates a minor nervous feeling state. In have felt blue every so often during the past ten years.
3. Long-term reaction (severity NA) -- extensive period mentioned in which R does not give enough elaborations to allow coder to code 1 or 2.. I’ve been overworking for years.
Short-term
4. Short-term reaction (severe) -- a short period mentioned in which R elaborates on a severe nervous feeling state. I was in a state of shock the week after my parents died.
5. Short-term reaction (not very severe) -- A short period mentioned in which R elaborates a minor nervous feeling state. When we had tornado warnings, I was a little concerned
6. Short-term reaction (severity NA). -- a short period mentioned in which R does not give enough elaboration to allow coder to code 4 or 5. when my mother died, I was upset.
NA Duration
7. Severe reaction, NA how long.
8. Not very severe reaction, NA how long. 
9. NA severity and Length. BK R said no breakdown. */

// Creating variable for breakdown severity that'll be used to create the contact variable
fre evbrkdwn	
recode brkddur (1 4 7 = 1) (2 3 5 6 8 9 .i .n = 0) if year==1996, gen(brkdsev)
	label var brkdsev "Severity Breakdown 1=severe"
	
	fre brkdsev
	
	tab brkddur brkdsev if year==1996, m
	tab brkddur evbrkdwn if year==1996, m

// also creating a variable for breakdown length	
	recode brkddur (1/3 = 1) (4/9 = 0), gen(brkdlong)
	label var brkdlong "Length Breakdown 1=Long"
	
	tab brkddur brkdlong, m
	
**************************************************************** 
// 1996
****************************************************************	

******
// Contact Self Variable
******	

fre evbrkdwn
count if evmhp==1 | brkdsev==1	
		
	gen cntct_slf96 = .
	replace cntct_slf96=.y if year==2006 | year==2018
	replace cntct_slf96=.m if evmhp==.a | evmhp==.d
	
	replace cntct_slf96=0  if evbrkdwn==2
	replace cntct_slf96=0  if brkdsev==0 & evmhp!=1
	replace cntct_slf96=1  if evmhp==1 
	replace cntct_slf96=1  if brkdsev==1
	
		la var cntct_slf96 "Contact w/ Self 96"
		la val cntct_slf96 yesno
		
	fre cntct_slf96  if year==1996
	tab evmhp brkdsev if year==1996, m
	
	local vars "evbrkdwn brkdsev evmhp"
	foreach v in `vars' {
		tab cntct_slf96 `v' if year==1996, m
		}
		
	list evmhp evbrkdwn brkdsev if cntct_slf96==.
		
	fre evmhp evbrkdwn brkdsev if year==1996	
	fre cntct_slf96  if year==1996	
	
******
//  Contact other variable	
******

	sort year
	list ballot if evmhp==.i & year==1996 in 1/20
	list ballot if evmhp==.i & year==1996 in 1/20

	gen cntct_oth96 =.
	replace cntct_oth96=.y if year==2006 
	replace cntct_oth96=.y if year==2018
	
	replace cntct_oth96=.m if knwmhosp==.d | knwmhosp==.n | knwmhosp==.a | ///
	                          knwpatnt==.d | knwpatnt==.n | knwpatnt==.a
							  
	replace cntct_oth96=.i if knwmhosp==.i & year==1996 | ///
	                          knwpatnt==.i & year==1996 
							  
	replace cntct_oth96=1  if knwmhosp==1 
	replace cntct_oth96=1  if knwpatnt==1
	replace cntct_oth96=0  if knwpatnt==2 & knwmhosp!=1
	replace cntct_oth96=0  if knwmhosp==2 & knwpatnt!=1
 
		la var cntct_oth96 "Contact w/ Other 96"
		la val cntct_oth96 yesno
		
	
    list knwmhosp knwpatnt form if cntct_oth96==.i in 1/200
	
	fre knwmhosp knwpatnt if year==1996
	fre cntct_oth96	 if year==1996
	
	tab knwmhosp knwpatnt, m			
	local vars "knwmhosp knwpatnt"
	foreach v in `vars' {
		fre `v'
		tab cntct_oth96 `v', m
		}
	
******
// Contact Self or Other
******

tab cntct_oth96 cntct_slf96 if year==1996, m
	
	gen cntct_so96 = .
	replace cntct_so96=.y if year==2006 | year==2018
	replace cntct_so96=.i if knwmhosp==.i & year==1996 | ///
	                         knwpatnt==.i & year==1996 
							 
	replace cntct_so96=0  if cntct_slf96==0 & cntct_oth96==0						 
	replace cntct_so96=1  if cntct_slf96==1 & cntct_oth96==0
    replace cntct_so96=2  if cntct_oth96==1 & cntct_slf==0
	replace cntct_so96=3  if cntct_slf96==1 & cntct_oth96==1
		la var cntct_so96 "Contact w/ Slf&/Othr 96"
		la def cntct_so 0 "No" 1 "Self Only" 2 "Other Only" 3 "Both"
		la val cntct_so96 cntct_so
	
	fre cntct_so96  if year==1996
	
	tab cntct_so96 cntct_slf96 if year==1996, m
	tab cntct_so96 cntct_oth96 if year==1996, m
	
	
*******
//  Any contact	
******
	gen cntct_any96 = 0
	replace cntct_any96=.y if year==2006   | year==2018
	replace cntct_any96=.m if evmhp==.a    | evmhp==.n    | ///
	                          knwmhosp==.d | knwmhosp==.n | ///
	                          knwpatnt==.d | knwpatnt==.n
	replace cntct_any96=.i if knwmhosp==.i & evmhp==.i & year==1996 | ///
	                          knwpatnt==.i & evmhp==.i & year==1996 
	replace cntct_any96=1  if cntct_slf96==1 
	replace cntct_any96=1  if cntct_oth96==1 
		la var cntct_any96 "Contact w/ Slf&/Othr 96"
		la val cntct_any96 yesno
	fre cntct_any96  if year==1996
	
	local vars "cntct_slf96 cntct_oth96"
	foreach v in `vars' {
		fre `v'
		tab cntct_any96 `v', m
		}
	
	count if cntct_slf96==.i & cntct_oth96==.i
	
**********
/// 2006	
**********
	
	gen cntct_any06 = 0
	replace cntct_any06=.y if year==1996   | year==2018
	replace cntct_any06=.i if mhtrtoth==.i & year==2006
	replace cntct_any06=.m if mhtrtoth==.d & year==2006 | mhtrtoth==.n & year==2006
	replace cntct_any06=1  if mhtrtoth==1 & year==2006
		la var cntct_any06 "Contact w/ Slf&/Othr 06"
		la val cntct_any06 yesno
	fre cntct_any06
	
	tab cntct_any06 mhtrtoth, m
	
	gen cntct_oth06 = 0
	replace cntct_oth06=.y if year==1996  | year==2018
	replace cntct_oth06=.i if mhtrtoth==.i & year==2006
	replace cntct_oth06=.m if mhtrtoth==.d & year==2006 | mhtrtoth==.n & year==2006
	replace cntct_oth06=1  if mhtrtoth==1 & year==2006
		la var cntct_oth06 "Contact w/ Other 06"
		la val cntct_oth06 yesno
	fre cntct_oth06	

	gen cntct_slf06 = .y
		la var cntct_slf06 "No 06 measure of self in ballots"
		
	gen cntct_so06 = .y
		la var cntct_so06 "No 06 measure of self in ballots"

**********
/// 2018	
**********	
   
	gen cntct_any18 = 0
	replace cntct_any18=.y if year==2006   | year==1996
	replace cntct_any18=.i if diagnosd==.i & year==2018 | ///
	                          mhdiagno==.i & year==2018
	replace cntct_any18=.m if diagnosd==.d | mhdiagno==.d | ///
							  diagnosd==.n | mhdiagno==.n 
	replace cntct_any18=1  if diagnosd==1  | mhdiagno==1
		la var cntct_any18 "Contact w/ Slf&/Othr 18"
		la val cntct_any18 yesno
	fre cntct_any18 if year==2018
	
	tab cntct_any18 diagnosd if year==2018, m
	tab cntct_any18 mhdiagno if year==2018, m
	
	gen cntct_oth18 = .
	replace cntct_oth18=.y if year==2006   | year==1996  
	replace cntct_oth18=.i if mhdiagno==.i & year==2018
	replace cntct_oth18=.m if mhdiagno==.d | mhdiagno==.n
	
	replace cntct_oth18=1  if mhdiagno==1 
	replace cntct_oth18=0  if mhdiagno==2 
		la var cntct_oth18 "Contact w/ Other 18"
		la val cntct_oth18 yesno
	fre cntct_oth18	if year==2018
	
	tab cntct_oth18 mhdiagno if year==2018, m
		
	gen cntct_slf18 = .
	replace cntct_slf18=.y if year==2006   | year==1996
	replace cntct_slf18=.i if diagnosd==.i & year==2018
	replace cntct_slf18=.m if diagnosd==.d
	replace cntct_slf18=.m if diagnosd==.n
	replace cntct_slf18=1  if diagnosd==1
	replace cntct_slf18=0  if diagnosd==2
		la var cntct_slf18 "Contact w/ Self 18"
		la val cntct_slf18 yesno	
	fre cntct_slf18 if year==2018
	fre diagnosd if year==2018
	
	gen cntct_so18 = .
	replace cntct_so18=.y if year==2006   | year==1996
	replace cntct_so18=.i if diagnosd==.i  & year==2018 | ///
	                         mhdiagno==.i  & year==2018
	replace cntct_so18=.m if diagnosd==.d | mhdiagno==.d | ///
							 diagnosd==.n | mhdiagno==.n 
	replace cntct_so18=1 if cntct_slf18==1
	replace cntct_so18=2 if cntct_oth18==1
	replace cntct_so18=3 if cntct_slf18==1 & cntct_oth18==1
	replace cntct_so18=0 if cntct_slf18==0 & cntct_oth18==0
		la var cntct_so18 "Contact w/ Slf&/Othr 18"
		la val cntct_so18 cntct_so
	fre cntct_so18

**********
/// Combined Measure	
**********	
	gen cntct_tot = .
	replace cntct_tot=1  if cntct_any96==1  | cntct_any06==1   | cntct_any18==1
	replace cntct_tot=0  if cntct_any96==0 & !missing(cntct_any96) | ///
	                        cntct_any06==0 & !missing(cntct_any06) | ///
							cntct_any18==0 & !missing(cntct_any18)

		la var cntct_tot "Contact: Self and/or Other"
		lab def contlab 0"no contact" 1"contact with mental illness"
		lab val cntct_tot contlab
		
	fre cntct_tot
	
	
// check work	
	local any "cntct_any96 cntct_any06 cntct_any18"
	
	foreach v in `any' {
		tab cntct_tot `v' if !missing(`v'), m
		}
		
		
	list cntct_slf18 cntct_so18 cntct_oth18 if missing(cntct_so18) & !missing(cntct_oth18)
		
*all summary measures
fre 	cntct_tot

local y "cntct_any96 cntct_oth96 cntct_slf96 cntct_so96"
local y "`y' cntct_any06 cntct_oth06 cntct_slf06 cntct_so06"
local y "`y' cntct_any18 cntct_oth18 cntct_slf18 cntct_so18"

foreach v in `y' {
	di in red ". tab    `v' cntct_tot, m"
	tab    `v' cntct_tot if `v'!=.y, m
}		
		
// should be no observations
local year "96 06 18"

foreach y in `year' {
	 di in red "Year is `y'"
	 list cntct_slf`y' cntct_oth`y' cntct_so`y' cntct_tot if ///
          cntct_tot==1 & cntct_slf`y'==0 & cntct_oth`y'==0	
		  
	 list cntct_slf`y' cntct_oth`y' cntct_so`y' cntct_tot if ///
          cntct_tot==1 & missing(cntct_slf`y') & missing(cntct_oth`y'==0) ///
		  & cntct_slf`y'!=.y & cntct_oth`y'!=.y
		
	list cntct_slf`y' cntct_oth`y' cntct_so`y' cntct_tot if ///
          cntct_tot==0 & cntct_slf`y'==1 & cntct_slf`y'!=.y & cntct_oth`y'!=.y | ///
		  cntct_tot==0 & cntct_oth`y'==1 & cntct_slf`y'!=.y & cntct_oth`y'!=.y	  
}
		
		
**************************************************************** 
// Valence of contact
****************************************************************		
		
	fre mhothrel mhothyou	
	recode mhothyou (1=4 "A great deal") (2=3 "Quite a bit") ///
                (3=2 "A little") (4=1 "Not at all") ///
				(.i=0 "No Contact") if year==2006, gen(c_effectY)	 
				
	la var c_effectY "Personal Distress from Contact"				
  
	recode mhothrel (1=1 "Stronger") (3 .d=2 "No Change") ///
                (2 4=3 "Worse") (.i=0 "No Contact") if year==2006, gen(c_effectR)	
	
	la var c_effectR "Relationship Consequences of MI"
	
	fre c_*
	
	replace c_effectR=.y if year!=2006
	replace c_effectY=.y if year!=2006
	
	
**************************************************************** 
// TDM: Addiitonal summary measures with diff types of contact
****************************************************************	
fre 	cntct_tot cntct_so* c_effectY c_effectR	

// var for whether contact is with other, self, both, or none
gen 	cntct_so4 = cntct_tot
lab var cntct_so4 "Contact with self or others"
lab def cso4lab 0"No Contact" 1"Other Contact" 2"Self Contact" 3"Both"
fre		cntct_oth06	// no self measure in 06
*break out self or both when avaialble
replace cntct_so4 = 1 if cntct_so96 == 2 | cntct_so18 == 2
replace cntct_so4 = 2 if cntct_so96 == 1 | cntct_so18 == 1 
replace cntct_so4 = 3 if cntct_so96 == 3 | cntct_so18 == 3
lab val cntct_so4 cso4lab
fre 	cntct_so4
tab 	cntct_so4 cntct_tot, miss

*3 category version collapsing self and both
clonevar 	cntct_so3 = cntct_so4
recode 		cntct_so3 2 3 = 2
tab 		cntct_so4 cntct_so3, miss


local y "cntct_any96 cntct_oth96 cntct_slf96 cntct_so96"
local y "`y' cntct_any06 cntct_oth06 cntct_slf06 cntct_so06"
local y "`y' cntct_any18 cntct_oth18 cntct_slf18 cntct_so18"

foreach v in `y' {
	di in red ". tab    `v' cntct_so4, m"
	tab    `v' cntct_so4 if `v'!=.y, m 	
}


// var for the valence of contact (only in 06 survey). Ccoding it as 
*	bad contact if it caused distress and/or had neg relationship consequences 
gen 	cntct_val4 = cntct_tot
lab var cntct_val4 "Contact with valence"
lab def cv4lab 0"No Contact" 1"Any Contact" 2"Bad Contact" 3"Good Contact"
replace cntct_val4 = 3 if cntct_tot == 1 & year == 2006
replace cntct_val4 = 2 if c_effectY == 3 | c_effectY == 4
replace cntct_val4 = 2 if c_effectR == 3 
lab val cntct_val4 cv4lab
fre 	cntct_val4
tab 	cntct_val4 cntct_tot, miss

*3 category version collpasing good and any
clonevar 	cntct_val3 = cntct_val4
recode 		cntct_val3 2 3 = 2
tab 		cntct_val4 cntct_val3, miss
	
**********
/// Examining Contact	
**********		

	fre cntct_*
	
	local contact "evmhp evbrkdwn brkddur brkdsev brkdlong"
	local contact "`contact' diagnosd mhtrtoth mhtrtot2 mhtrtslf mhtreatd"
	local contact "`contact' knwpatnt knwmhosp mhdiagno mhothyou mhothrel" 
	
	foreach v in `contact' {
		rename `v' c_`v'
		}

	// should be no observations
local year "96 06 18"

foreach y in `year' {
	 di in red "Year is `y'"
	 list cntct_slf`y' cntct_oth`y' cntct_so`y' cntct_tot if ///
          cntct_so4!=0 & cntct_slf`y'==0 & cntct_oth`y'==0	
		  
	 list cntct_slf`y' cntct_oth`y' cntct_so`y' cntct_tot if ///
          cntct_so4!=0 & !missing(cntct_so4) /// 
		  & missing(cntct_slf`y') & missing(cntct_oth`y') ///
		  & cntct_slf`y'!=.y & cntct_oth`y'!=.y
		
	list cntct_slf`y' cntct_oth`y' cntct_so`y' cntct_tot if ///
          cntct_tot==0 & cntct_slf`y'==1 & cntct_slf`y'!=.y & cntct_oth`y'!=.y | ///
		  cntct_tot==0 & cntct_oth`y'==1 & cntct_slf`y'!=.y & cntct_oth`y'!=.y	  
}	
		
**********
/// 	
**********	
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
 // #3 Saving data here and doing further 
 //    examinations on a different dataset below
****************************************************************
		
	save "Data/mls-data03-contact_recode", replace	
/*	
****************************************************************
 // #2
****************************************************************

	 **----------------------------------------------**
	 ** Because the ballots are wonky, and questions **
	 ** about contact are not asked consistently 	 **
	 ** in 2006, I'm looking into patterns of 		 **
	 ** contact w/ mental illness for self and other **
	 ** in other parts of the 2006 data. This allows **
	 ** us to estimate how many people with mental   **
	 ** illness we are missing in the sample bc it	 **
	 ** was not asked.								 **
	 **----------------------------------------------**

	local meta    "year id ballot vigversn version form issp formwt cohort sampcode"
	local meta    "`meta' sample oversamp phase wtss wtssnr wtssall vstrat vpsu"
	local demog   "marital wrkstat age educ degree sex race born income region"
	local contact "evmhp mhp* mhtreat* diagnosd mhtrtoth mhtrtot2 mhtrtslf mhtreatd"
	local contact "`contact' knwpatnt knwmhosp knwnproz  disabld5 mhdiagno hlthmntl"

	local vars    "`meta' `demog' `contact'"
	
	use `vars' if year == 2006 using "Data/GSS7218_R1", clear

	fre disabld5 mhtrtot2 mhtrtslf if mhtrtot2!=.i
	
	tab mhtrtot2 disabld5 if mhtrtot2!=.i, col row
		* ~84% of people with a mental illness also know someone with a mental illness
		* only 15 people, ~16% of those with a mental illness and ~1% of the total sample
		* know have a mental illness but don't know anyone with a mental illness
		
	tab mhtrtot2 mhtrtslf if mhtrtot2!=.i, col row
		* Of those who've received treatment for a mental illness, 90% know someone
		* with a mental illness. Only 21 people, ~1.4% of total have received treatment, 
		* but don't know someone who's received treatment.
		
	tab disabld5 mhtrtslf if mhtrtot2!=.i, col row
		* Of those who report having an emotional or mental disability, ~74% report
		* having had treatment for their mental illess. Of those who've received
		* treatment, ~11% reported not having an emotional or mental disability 
		* this may be attributal to recovery (i.e., they no longer have) or 
		* identity, they don't identify as having a "disability" - more research
		* would be needed to sort out these differences.

log close
exit	
	
	
