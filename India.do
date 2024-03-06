// Introduction
/* This .do-file prepares the Indian urban/rural population data such that they match the urban/rural shares from four surveys where we have microdata and from the Ministry of Health from 2013 onwards.
The Minstry of Health data was received from the Indian team, see email saved in this repo. */

cd "C:\Users\WB514665\OneDrive - WBG\PovcalNet\Lining-up\aux_pop"

// Get urban/rural data from WDI
wbopendata, indicator(SP.POP.TOTL;SP.URB.TOTL;SP.RUR.TOTL) country(IND) long clear
gen double ruralshare_wdi = sp_rur_totl/sp_pop_totl
ren sp* sp*_wdi
keep year sp* ruralshare_wdi
tempfile wdi
save    `wdi'

// Get Ministry of Health rural shares
import excel "Population_Projections_MoH.xlsx", sheet("MoH_population") firstrow clear
gen double ruralshare_moh = Rural/Total
keep Year ruralshare
rename Year year
drop if year>2022
tempfile moh
save    `moh'

// Get survey rural shares from datalibweb
foreach year in 1993 2004 2009 2011 {
dlw, coun(IND) y(`year') t(GMD) mod(GPWG) 
collapse (sum) weight, by(urban)
gen year = `year'
cap append using `datasofar'
tempfile datasofar
save    `datasofar'
}
bysort year (urban): gen double ruralshare_surv = weight[1]/(weight[1]+weight[2]) 
keep year ruralshare
duplicates drop
// Change year to reflect that these are decimal years, which for these surveys are 0.5
replace year = year + 0.5

// Append three soruces
append using `wdi'
merge 1:1 year using `moh', nogen
sort year

// Infer WDI data for survey time 
replace sp_pop_totl     = (sp_pop_totl[_n-1]+sp_pop_totl[_n+1])/2         if missing(sp_pop_totl)
replace sp_urb_totl_wdi = (sp_urb_totl_wdi[_n-1]+sp_urb_totl_wdi[_n+1])/2 if missing(sp_urb_totl_wdi)
replace sp_rur_totl_wdi = (sp_rur_totl_wdi[_n-1]+sp_rur_totl_wdi[_n+1])/2 if missing(sp_rur_totl_wdi)
replace ruralshare_wdi  = sp_rur_totl_wdi/sp_pop_totl                     if missing(ruralshare_wdi)

// Create blank urban/rural series to be populated with the final numbers to be used
gen double sp_urb_totl_final = .
gen double sp_rur_totl_final = .
gen double ruralshare_final  = .

// Urban/rural shares for surveys should be consistent with the survey estimates
replace sp_rur_totl_final = sp_pop_totl_wdi*ruralshare_surv     if !missing(ruralshare_surv)
replace sp_urb_totl_final = sp_pop_totl_wdi*(1-ruralshare_surv) if !missing(ruralshare_surv)
replace ruralshare_final  = sp_rur_totl_final/sp_pop_totl       if !missing(ruralshare_surv)

// From 2013 onwards, urban/rural pop is decided by the rural share from MoH
replace sp_rur_totl_final = sp_pop_totl_wdi*ruralshare_moh     if year>=2013
replace sp_urb_totl_final = sp_pop_totl_wdi*(1-ruralshare_moh) if year>=2013
replace ruralshare_final  = sp_rur_totl_final/sp_pop_totl_wdi  if year>=2013
// We can't use MoH for 2012 as this would create a non-monotonically increasing trend (becase with 2011.5 and 2012 set, 2011 is mechanically fixed at a level, which turns out would be non-credible)
// MoH data no longer needed
drop *moh

// For 2010 and 2011 use the interpolation formala we use for national accounts
forvalues yr=2010/2011 {
replace ruralshare_final = ruralshare_final[_n-(`yr'-2009)]-(ruralshare_wdi[_n-(`yr'-2009)]-ruralshare_wdi)/(ruralshare_wdi[_n-(`yr'-2009)]-ruralshare_wdi[_n+(2012-`yr')])*(ruralshare_final[_n-(`yr'-2009)]-ruralshare_final[_n+(2012-`yr')]) if year==`yr'
}
replace sp_rur_totl_final = sp_pop_totl_wdi*ruralshare_final     if inrange(year,2010,2011)
replace sp_urb_totl_final = sp_pop_totl_wdi*(1-ruralshare_final) if inrange(year,2010,2011)

// To keep 2011.5 share equal to the survey, we back out what 2012 must be
replace sp_rur_totl_final = 2*sp_rur_totl_final[_n-1]-sp_rur_totl_final[_n-2] if year==2012
replace sp_urb_totl_final = 2*sp_urb_totl_final[_n-1]-sp_urb_totl_final[_n-2] if year==2012
replace ruralshare_final  = sp_rur_totl_final/sp_pop_totl_wdi                 if year==2012

// Similar for 2009.5 and 2009
replace sp_rur_totl_final = 2*sp_rur_totl_final[_n+1]-sp_rur_totl_final[_n+2] if year==2009
replace sp_urb_totl_final = 2*sp_urb_totl_final[_n+1]-sp_urb_totl_final[_n+2] if year==2009
replace ruralshare_final  = sp_rur_totl_final/sp_pop_totl_wdi                 if year==2009

// Between 2005 and 2008, use interpolation formula
forvalues yr=2005/2008 {
replace ruralshare_final = ruralshare_final[_n-(`yr'-2004)]-(ruralshare_wdi[_n-(`yr'-2004)]-ruralshare_wdi)/(ruralshare_wdi[_n-(`yr'-2004)]-ruralshare_wdi[_n+(2009-`yr')])*(ruralshare_final[_n-(`yr'-2004)]-ruralshare_final[_n+(2009-`yr')]) if year==`yr'
}
replace sp_rur_totl_final = sp_pop_totl_wdi*ruralshare_final     if inrange(year,2005,2008)
replace sp_urb_totl_final = sp_pop_totl_wdi*(1-ruralshare_final) if inrange(year,2005,2008)

// Back out 2004
replace sp_rur_totl_final = 2*sp_rur_totl_final[_n+1]-sp_rur_totl_final[_n+2] if year==2004
replace sp_urb_totl_final = 2*sp_urb_totl_final[_n+1]-sp_urb_totl_final[_n+2] if year==2004
replace ruralshare_final  = sp_rur_totl_final/sp_pop_totl_wdi                 if year==2004

// Between 1994 and 2003, use interpolation formula
forvalues yr=1994/2003 {
replace ruralshare_final = ruralshare_final[_n-(`yr'-1993)]-(ruralshare_wdi[_n-(`yr'-1993)]-ruralshare_wdi)/(ruralshare_wdi[_n-(`yr'-1993)]-ruralshare_wdi[_n+(2004-`yr')])*(ruralshare_final[_n-(`yr'-1993)]-ruralshare_final[_n+(2004-`yr')]) if year==`yr'
}
replace sp_rur_totl_final = sp_pop_totl_wdi*ruralshare_final     if inrange(year,1994,2003)
replace sp_urb_totl_final = sp_pop_totl_wdi*(1-ruralshare_final) if inrange(year,1994,2003)

// Back out 1993
replace sp_rur_totl_final = 2*sp_rur_totl_final[_n+1]-sp_rur_totl_final[_n+2] if year==1993
replace sp_urb_totl_final = 2*sp_urb_totl_final[_n+1]-sp_urb_totl_final[_n+2] if year==1993
replace ruralshare_final  = sp_rur_totl_final/sp_pop_totl_wdi                 if year==1993

// Use change in WDI share prior to 1993
gsort -year
replace ruralshare_final = ruralshare_final[_n-1]+(ruralshare_wdi-ruralshare_wdi[_n-1]) if year<1993
replace sp_rur_totl_final = sp_pop_totl_wdi*ruralshare_final     if year<1993
replace sp_urb_totl_final = sp_pop_totl_wdi*(1-ruralshare_final) if year<1993
sort year
format  sp* %12.0f

// Plot rural share over time
twoway line ruralshare_final year 
twoway line sp_rur_totl_final year || line sp_urb_totl_final year

// Check urban+rural equals total
gen check1 = sp_urb_totl_final+sp_rur_totl_final-sp_pop_totl_wdi
sum check1

// Check that rural share matches survey shares
gen check2 = ruralshare_surv - (sp_rur_totl_final[_n-1]+sp_rur_totl_final[_n+1])/(sp_pop_totl_wdi[_n-1]+sp_pop_totl_wdi[_n+1]) if !missing(ruralshare_surv)
sum check2

drop check*

// Prepare for aux file
drop if !missing(ruralshare_surv)
keep year sp*final sp_pop_totl
reshape long sp_, i(year) j(type) string
rename sp YR
reshape wide YR, i(type) j(year)
gen Country = "IND"
gen Country_Name = "India"
rename type Series
replace Series = "SP.POP.TOTL" if Series=="pop_totl_wdi"
replace Series = "SP.RUR.TOTL" if Series=="rur_totl_final"
replace Series = "SP.URB.TOTL" if Series=="urb_totl_final"
gen     Series_Name = "Population, total" if Series == "SP.POP.TOTL" 
replace Series_Name = "Rural population"  if Series == "SP.RUR.TOTL" 
replace Series_Name = "Urban Population"  if Series == "SP.URB.TOTL" 
gen SCALE = 0
forvalues yr=1950/1959 {
gen YR`yr' = .
}
order *, alpha
order Country Country_Name Series Series_Name SCALE
// Here I copy paste the data into the csv file