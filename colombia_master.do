********************************************************************************
*** Generate Colombian master panel
********************************************************************************
*** Main inputs: colombia_1981_1991, colombia_1992_1994, colombia_1995_2016
*** Additional inputs: 1.3.1.3 IPP_Segun uso o destino economico_anual_IQY.xlsx, Deflactor's comparison.xlsx, ciiu4vciiu3
*** Output: colombia_master.dta
*** Author: Nicolas Oviedo
*** Original: 05/10/2021
********************************************************************************
*** Set up
********************************************************************************
cls
query memory
set more off
********************
*User Settings
********************
*User: andres
//global who = "A" 

*User: Nicolas
global who = "N" 

*User: Isaac
//global who = "I"
********************************************************************************	
*** Paths and Logs            
********************************************************************************
if "$who" == "A"  global pathinit "/Users/jablanco/Dropbox (University of Michigan)/papers_new/LumpyTaxes"
if "$who" == "N"  global pathinit "C:\Users\Ovi\Desktop\R.A"

global output_data "$pathinit/Data/outputs/microdata/surveys/Colombia"
global input_data  "$pathinit/Data/inputs/microdata/surveys/Colombia/BaleyBlanco"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/colombiamaster.log", append

cd "$output_data"

********************************************************************************	
*** Append data
********************************************************************************
*Prepare 81-91 data
use colombia_1981_1991, clear
*Append 92-94 data
append using colombia_1992_1994.dta, nonotes
*Append 95-16 data
append using colombia_1995_2016.dta, nonotes

cd "$pathinit/Data/outputs/microdata/surveys/master"

save colombia_master, replace

********************************************************************************	
*** Construct a price index consistent with Robert and Tybout data 
********************************************************************************
tempfile ipp
save `ipp', emptyok
import excel using "$pathinit/Data/inputs/microdata/survey/Colombia/aux_doc/1.3.1.3 IPP_Segun uso o destino economico_anual_IQY.xlsx", clear
drop in 1/8
drop in 53/59
compress
drop B C D F
ren A year
ren E IPP
drop in 1
destring (year IPP), replace
keep if year > 1980 & year < 2017
sort year
tsset year
gen var_ipp = (IPP/L.IPP-1)
save `ipp', replace

tempfile priceindex
save `priceindex', emptyok
import excel using "$pathinit/Data/inputs/microdata/survey/Colombia/Roberts-Tybout/supp data/Deflactor's comparison.xlsx", clear
drop G-K
drop C-E
drop in 1/4
ren B year
ren F iprice
drop in 12/13
destring(year iprice), replace
replace year = year + 1900
append using `ipp'
collapse (firstnm) iprice IPP var_ipp, by(year)
tsset year
replace iprice = L.iprice*(1+var_ipp) if year > 1991
save `priceindex', replace

use colombia_master, clear
merge m:1 year using `priceindex', keepusing(iprice)
drop if _merge == 2
drop _merge

save colombia_master, replace

********************************************************************************	
*** Variables in real terms
********************************************************************************
use colombia_master, clear

foreach var in wage_bill sales capital_f_stru capital_f_vehi capital_f_mach capital_f inv_stru inv_mach inv_vehi inv_total{
	replace `var' = `var'/iprice
}
compress
drop iprice
save colombia_master, replace

********************************************************************************	
*** Merge with Chile master
********************************************************************************
gen country = "COL"
append using CHILEmaster, nonotes
replace country = "CHL" if country == ""
compress
save invest_master, replace