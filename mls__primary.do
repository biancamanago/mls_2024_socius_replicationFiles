
// MLS -- Matching Labeling & Stigma //
// Primary do-file //


*Data cleaning
do mls-data00-import
do mls-data01-conditions
do mls-data02-label_name_recode
do mls-data03-contact_recode
do mls-data04-sort_order
do mls-data05-missing
do mls-data06-scales
do mls-data07-sample_selection // where imputation is done
do mls-data08-contact_valence // imputation for sensitivity analyses 
                           // regarding contact valence (see notes in file)

*Analyses
do mls-do00-descriptives  // Table 1
do mls-do01-regressions   // Table B1 
do mls-do02-matching      // Table 2, Table A2, Table A3 
do mls-do04-contactBaseline // Table 3, Table 4
do mls-do05-appendixC_contact // Table C1, Table C2
