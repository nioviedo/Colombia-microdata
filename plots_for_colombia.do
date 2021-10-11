********************************************************************************
*** Plots for Colombia 1981-2016
********************************************************************************
*** Main inputs: colombia_master (1981-2016), col_data_clean (1981-1991), EAM_9294(1992-1994) & EAM_9516.dta (1995-2016)
*** Additional inputs: 1.3.1.3 IPP_Segun uso o destino economico_anual_IQY.xlsx, Deflactor's comparison.xlsx, ciiu4vciiu3
*** Output: colombia19812016.dta
*** Author: Nicolas Oviedo
*** Original: 05/03/2021
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
global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia/BaleyBlanco"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/plotsforcolombia.log", append

cd "$output_data"

********************************************************************************	
*** Append data
********************************************************************************
*Prepare 81-91 data
use col_data_clean, clear
keep id-capital_f
replace year = year + 1900

*Append 92-94 data
append using EAM_9294.dta, nonotes
*Append 95-16 data
append using EAM_9516.dta, nonotes
bysort year: egen number = count(id)

*Check if panel
xtset id year
duplicates report id year

drop C2V23R1 - count
compress
save colombia19812016, replace

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

use colombia19812016, clear
merge m:1 year using `priceindex', keepusing(iprice)
drop if _merge == 2
drop _merge

save colombia19812016, replace

*Compare with a national accounts price index
tempfile deflator8116
save `deflator8116', emptyok
import excel using "$pathinit/Data/inputs/microdata/survey/Colombia/aux_doc/1.3.1.3 IPP_Segun uso o destino economico_anual_IQY.xlsx", clear
drop in 1/9
drop in 52/58
compress
drop B
ren A year
ren C ipricecb_ic
ren D ipricecb_cpi
ren E ipricecb_k
ren F ipricecb_bd
destring year-ipricecb_bd, replace
sort year
drop if year > 2016 | year < 1981
foreach var in ic cpi k bd{
	gen ip_`var'= ipricecb_`var'/ipricecb_`var'[1]
}
save `deflator8116', replace
merge 1:m year using colombia19812016, keepusing(iprice)

collapse (firstnm) ip_* iprice, by(year)
lab var ip_ic "Intermediate consumption"
lab var ip_cpi "CPI"
lab var ip_k "Capital goods"
lab var ip_bd "Construction"
lab var iprice "Roberts-Tybout"

#delim ;
line ip_* iprice year,
lwidth(vthin vthin thick vthin thick) 
name(deflators,replace) 
legend(ring(0) col(1) bmargin(-20 0 55 0)  region(lpattern(blank)))  
xscale(range(1981 2016)) 
yscale(range(0 80)) 
xlabel(1980(4)2016) 
ylabel(0(8)80);
#delim cr

gr export "$figures/colm_iprice.png", replace
********************************************************************************	
*** Variables in real terms
********************************************************************************
use colombia19812016, clear

foreach var in total_wb inter_input capital_i capital_f{
	replace `var' = `var'/iprice
}
replace total_invest_direct = total_invest_direct/iprice if year > 1991
drop total_invest_eslava

save colombia19812016, replace
********************************************************************************	
*** Plots
********************************************************************************
use colombia19812016, clear

collapse(sum) labor total_wb inter_input total_invest_direct capital_i capital_f number, by(year)
replace number = number/sqrt(number) // Recover number of plants per year
lab var number "Number of plants"

***Plots***
*Plants per year
twoway bar number year
gr export "$figures/colm_firms.png", replace

*Capital, investment, salaries and intermediate consumption per plant
foreach var in labor total_wb inter_input total_invest_direct capital_i capital_f{
	gen c_`var' = log(`var'/number)
}
lab var c_labor "Workers per plant"
lab var c_total_wb "Average salary per plant"
lab var c_inter_input "Intermediate consumption"
lab var c_total_invest_direct "Real investment"
lab var c_capital_i "Capital BOY"
lab var c_capital_f "Capital EOY"

local varlist "labor total_wb inter_input total_invest_direct capital_i capital_f"
local colores "olive navy maroon teal cyan orange"
forvalues t = 1/6{
	 local color = word("`colores'", `t')
	 local var = word("`varlist'", `t')
	 #delim;
	 twoway line c_`var' year,
	 lwidth(thick) lcolor(`color')
	 name(`var', replace);
	 #delim cr
	 gr export "$figures/colm_`var'.png",replace
}

********************************************************************************	
*** Capital and investment per asset type
********************************************************************************
use "$pathinit/Data/outputs/microdata/surveys/master/colombia_master", clear

bysort year: egen number = count(id)

ds year, not
collapse (sum) `r(varlist)', by (year)
replace number = number/sqrt(number) // Recover number of plants per year
lab var number "Number of plants"


foreach var in stru vehi mach{
	gen capital_c_`var' = log(capital_f_`var'/number)
	gen inv_c_`var' = log(inv_`var'/number)
}
lab var capital_c_stru "Capital per plant in structures"
lab var capital_c_vehi "Capital per plant in vehicles"
lab var capital_c_mach "Capital per plant in machinery"
lab var inv_c_stru "Investment per plant in structures" 
lab var inv_c_vehi "Investment per plant in vehicles"
lab var inv_c_mach "Investment per plant in machinery"

#delim ;
line capital_c_* year,
name(capital_c,replace) 
legend(ring(0) col(1) bmargin(55 0 12 0)  region(lpattern(blank)))  
xscale(range(1981 2016)) 
yscale(range(6 13)) 
xlabel(1980(4)2016) 
ylabel(6(1)12);
#delim cr

gr export "$figures/colm_capital_type.png", replace

#delim ;
line inv_c_* year,
name(inv_c,replace) 
legend(ring(0) col(1) bmargin(40 0 2 0)  region(lpattern(blank)))  
xscale(range(1981 2016)) 
yscale(range(4 10)) 
xlabel(1980(4)2016) 
ylabel(4(1)10);
#delim cr

gr export "$figures/colm_inv_type.png", replace
