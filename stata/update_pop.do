


// Date: 6 August 2025
cd "C:\Users\wb537472\OneDrive - WBG\Global Poverty and Inequality Data Team - WB Group - September 2025\Data\_aux\aux_pop"

// Population data in PIP 
pip tables, table(pop) clear 
tempfile pop 
save `pop'

// Load data
import excel "pop.xlsx", sheet("Sheet1") cellrange(A2:BQ653) firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""
reshape long YR, i(country_code series_code) j(year)
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
rename YR pop 
merge 1:1 country_code year data_level using `pop'

sum year if _merge==1 
sum year if _merge==2
br if _merge==2 

gen double d_pop = abs(pop-value)
sum d_pop
gsort - d_pop
br // these are the same data in PIP except that Greenland is different

br if !missing(value) & missing(pop)
// Update the data set "pop.xlsx"
// Old


import excel "pop.xlsx", sheet("Sheet1") cellrange(A2:BQ653) firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""
reshape long YR, i(country_code series_code) j(year)
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
rename YR pop_old 
tempfile old 
save `old'

// New
import excel "Pop estimates and projections from DCS as of 2025.8.5.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB759)  firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""
reshape long YR, i(country_code series_code) j(year)
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
rename YR pop_new 
merge 1:1 country_code year data_level using `old'
keep if inlist(_merge,1,3) 
sum if _merge==3

br if missing(pop_new) & !missing(pop_old)
br if country_code=="PSE"
replace pop_new = pop_old if missing(pop_new) & !missing(pop_old) 
br if country_code=="PSE"
gen double d_pop_abs = abs(pop_new - pop_old)
gen double d_pop = (pop_new - pop_old)
gsort -d_pop_abs 
br 

br if country_code=="IND"
br if country_code=="CHN"
br if country_code=="NGA"
br if country_code=="USA"

/*
gen lpop_old = ln(pop_old)
gen lpop_new = ln(pop_new)


preserve 
scatter lpop_new lpop_old, mlab(country_code) || function y =x, ra(lpop_old)
replace country_code="" if !(inlist(country_code,"IND","PAK"))
scatter lpop_new lpop_old, mlab(country_code) || function y =x, ra(lpop_old)
restore 
*/

br if !missing(pop_new) & missing(pop_old) & _merge==3
keep if _merge==3 | year==2024
rename pop_new YR
keep country_code country_name series_code series_name YR year
reshape wide YR, i(country_code series_code) j(year)
order country_code country_name series_code series_name
sort country_code series_code 

br if country_code=="PSE"

// Keep only 218 economies in WDI
egen row =  rowmiss(YR*)
drop if row == 64 | row==65
egen id = group(country_code)
sum id 
assert `r(max)'==218
drop id row

// Save data
export excel using "pop.xlsx", sheet("Sheet2") sheetreplace firstrow(variables)

///////// Compare latest population data to that in PIP ////////////

// Population data in PIP 
pip tables, table(pop) clear
rename value pop_old 
sum 
tempfile pop 
save `pop'

import excel "Pop estimates and projections from DCS as of 2025.8.5.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB759)  firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""
reshape long YR, i(country_code series_code) j(year)
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
rename YR pop_new 
merge 1:1 country_code year data_level using `pop'

sum year if _merge==1 
sum year if _merge==2
br if _merge==2 


gen double d_pop = (pop_new - pop_old)
gen double d_pop_abs = abs(pop_new - pop_old)
gsort -d_pop_abs
br 

keep if year>1976
drop if year>2025 

count if missing(pop_new) & !missing(pop_old)
br if missing(pop_new) & !missing(pop_old)
br if country_code=="PSE"
br if country_code=="GRL"
br if country_code=="GHA"
sort country_code year data_level 


/// Update projections

// Old 
import excel "spop.xlsx", sheet("spop") cellrange(A2:DB653) firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""


reshape long YR, i(country_code series_code) j(year) 
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" | series_name=="Urban Population"
rename YR pop_old 
tempfile old 
save `old'

br if country_code=="AIA"

// New
import excel "Pop estimates and projections from DCS as of 2025.8.5.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB759)  firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""
reshape long YR, i(country_code series_code) j(year)
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
rename YR pop_new 
br if country_code=="IND"
merge 1:1 country_code year data_level using `old', gen(merge)
// merge 1:1 country_code year data_level using `IND', gen(merge_IND)

br if country_code=="TWN" | country_code=="GRL"
br if missing(pop_old)
replace pop_new = pop_old if missing(pop_old) ///
  & !(country_code=="TWN" | country_code=="GRL")
 replace pop_new = pop_old if missing(pop_new) ///
	& !missing(pop_old) & country_code=="GRL"
replace pop_new = pop_old if country_code=="PSE" & year<1990
// replace pop_new = pop_old if country_code=="GRL"
keep if inrange(year,1950,2050) & merge==3
gen double d_pop_abs = abs(pop_new - pop_old)
gen double d_pop = (pop_new - pop_old)
gsort -d_pop_abs 
br
br if country_code=="GHA" & inlist(year,2023,2024,2025)
rename pop_new YR
replace YR = . if year<2024 



keep country_code country_name series_code series_name YR year
reshape wide YR, i(country_code series_code) j(year)
order country_code country_name series_code series_name
sort country_code series_code 

// Keep only 218 economies in WDI
egen row =  rowmiss(YR*)
drop if row == 100 | row==101
egen id = group(country_code)
sum id 
assert `r(max)'==218
drop id row

// Save data
export excel using "spop.xlsx", sheet("spop1") sheetreplace firstrow(variables)



// Check the values for 2024 
import excel using "spop.xlsx", sheet("spop1") firstrow clear 
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
reshape long YR, i(country_code series_code) j(year)
keep if year==2024 
rename YR pop1 
keep country_code country_name pop1 data_level year
tempfile pop 
save `pop'



import excel using "pop.xlsx", sheet("Sheet2") firstrow clear
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
reshape long YR, i(country_code series_code) j(year)
keep if year==2024 
rename YR pop2 
keep country_code country_name pop2 data_level year

merge 1:1 country_code year data_level using `pop'


gen double d_pop_abs = abs(pop1 - pop2)
gsort -d_pop_abs 
br


// Checks with original data set 
import excel using "pop.xlsx", sheet("Sheet1") firstrow clear cellrange(A2:BR653) 

rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""

gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
reshape long YR, i(country_code series_code) j(year)
rename YR pop_own
tempfile df 
save `df'

 
import excel "spop.xlsx", sheet("spop1") cellrange(A1:DA645) firstrow clear
reshape long YR, i(country_code series_code) j(year) 
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" | series_name=="Urban Population"
drop if missing(YR)
rename YR pop_own  
append using `df'
drop series_name series_code
duplicates drop
isid country_code year data_level 

tempfile own 
save `own'

// New
import excel "Pop estimates and projections from DCS as of 2025.8.5.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB759)  firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""
reshape long YR, i(country_code series_code) j(year)
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" 
rename YR pop_target  
drop series_code series_name
isid country_code year data_level 

merge 1:1 country_code year data_level using `own'  

gen double d_pop = abs(pop_target - pop_own)
gsort - d_pop
br 

 


