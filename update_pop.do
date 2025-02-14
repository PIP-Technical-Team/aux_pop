
// Date: 13 February 2025
cd "C:\Users\wb537472\OneDrive - WBG\Documents\Projects\PIP Update\April 2025\aux_pop.git"

// Population data in PIP 
pip tables, table(pop) clear 
tempfile pop 
save `pop'

// Load data
import excel "pop.xlsx", sheet("Sheet1") cellrange(A2:BQ671) firstrow clear
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
br // these are the same data in PIP except that rural/urban India are different


// Update the data set "pop.xlsx"
// Old


*import excel "pop.xlsx", sheet("Sheet1") cellrange(A2:BQ671) firstrow clear
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
import excel "Pop estimates and projections from DCS as of 2025.2.3.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB765)  firstrow clear
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
replace pop_new = pop_old if missing(pop_new) & !missing(pop_old) 

gen double d_pop_abs = abs(pop_new - pop_old)
gen double d_pop = (pop_new - pop_old)
gsort -d_pop_abs 
br 

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
keep if _merge==3
rename pop_new YR
keep country_code country_name series_code series_name YR year
reshape wide YR, i(country_code series_code) j(year)
order country_code country_name series_code series_name
sort country_code series_code 

// Save data
export excel using "pop.xlsx", sheet("Sheet2") sheetreplace firstrow(variables)

///////// Compare latest population data to that in PIP ////////////

// Population data in PIP 
pip tables, table(pop) clear
rename value pop_old 
sum 
tempfile pop 
save `pop'

import excel "Pop estimates and projections from DCS as of 2025.2.3.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB765)  firstrow clear
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

// Get rural/urban population from WDI
import excel "pop.xlsx", sheet("Sheet1") cellrange(A2:BQ671) firstrow clear
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
keep if country_code=="IND" 
rename YR pop_IND 
tempfile IND 
save `IND'


import excel "spop.xlsx", sheet("spop") cellrange(A2:DB653) firstrow clear
rename A country_code 
rename B country_name 
rename C series_code 
rename D series_name 
drop in 1 
drop Time 
drop if country_code==""

forvalues j = 2023/2050{
gen double YR`j'_ = real(YR`j')
drop YR`j'
rename YR`j'_ YR`j'
} 
reshape long YR, i(country_code series_code) j(year) 
gen data_level = "national" if series_name=="Population, total"
replace data_level = "rural" if series_name=="Rural population"
replace data_level = "urban" if series_name=="Urban population" | series_name=="Urban Population"
rename YR pop_old 
tempfile old 
save `old'

br if country_code=="AIA"

// New
import excel "Pop estimates and projections from DCS as of 2025.2.3.xlsx", ///
	sheet("Sheet1") cellrange(A2:DB765)  firstrow clear
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
merge 1:1 country_code year data_level using `IND', gen(merge_IND)

replace pop_new = pop_old if missing(pop_old)
replace pop_new = pop_IND if !missing(pop_IND) 
replace pop_new = pop_old if country_code=="PSE" & year<1990
replace pop_new = pop_old if country_code=="GRL"
keep if inrange(year,1950,2050) & merge==3
gen double d_pop_abs = abs(pop_new - pop_old)
gen double d_pop = (pop_new - pop_old)
gsort -d_pop_abs 
br
rename pop_new YR
keep country_code country_name series_code series_name YR year
reshape wide YR, i(country_code series_code) j(year)
order country_code country_name series_code series_name
sort country_code series_code 

// Save data
export excel using "spop.xlsx", sheet("spop1") sheetreplace firstrow(variables)

1463076	1507100	1554141	1603922	1656381	1711402	1769550	1832270	1901413
1463076	1507100	1554141	1603922	1656381	1711402	1769550	1832270	1901413
