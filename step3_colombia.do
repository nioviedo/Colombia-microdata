********************************************************************************
*** Append Colombia 1992-1994 data 
********************************************************************************
*** Main inputs: EAM_ANONIMIZADA_* (1992,1993,1994)
*** Additional inputs: col_ciiu
*** Output: EAM_9294.dta
*** Author: Nicolas Oviedo
*** Original: 04/30/2021
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
global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia/BaleyBlanco/Rawdata_19952015"
global temp_file   "$pathinit/Data/Temp"
*global figures 	   "$pathinit/Data/figures/colombia_new"

cap log close
log using "$temp_file/eam19921994.log", append

cd "$input_data"

********************************************************************************	
*** Append data for 1992, 1993 and 1994
********************************************************************************
use "$input_data/EAM - 1992/EAM_ANONIMIZADA_1992", clear

foreach jyear in 1993 1994{
	display " year: `jyear' "
	qui append using "$input_data/EAM - `jyear'/EAM_ANONIMIZADA_`jyear'.dta"	
}
/*
by nordemp nordest, sort: gen nvals = _n == 1 
by nordemp: replace nvals = sum(nvals)
by nordemp: replace nvals = nvals[_N] 
//There are firms (nordemp) with more than one plant (nordest). We take plants our statistic unit
drop nvals
*/
* Rename variables
rename nordemp id_firm
rename nordest id 
rename periodo year
rename DPTO region
rename CIIU2N4 industry

* Save and declare panel
order id year region industry
sort id year 
*xtset id year, yearly
replace year = year - 100
qui save "$output_data/EAM_9294.dta", replace

********************************************************************************	
*** Construct intermediate variables
********************************************************************************
*order id year labor total_wb inter_input total_invest_direct total_invest_eslava capital_i capital_f
gen building_purchase = C6V66R2 + C6V66R3 + C6V62R4
gen machequip_purchase = C6V67R2 + C6V69R2 + C6V67R3 + C6V69R3 + C6V67R4 + C6V69R4
gen transport_purchase = C6V68R2 + C6V68R3  + C6V68R4
gen total_purchase = building_purchase   + machequip_purchase   + transport_purchase

gen building_sales  = C6V66R9 
gen machequip_sales = C6V67R9 + C6V69R9
gen transport_sales = C6V68R9
gen total_sales = building_sales + machequip_sales + transport_sales

gen capital_i_bd  = C6V66R1 
gen capital_i_m   = C6V67R1 + C6V69R1
gen capital_i_car = C6V68R1

gen capital_f_bd  = C6V66R15
gen capital_f_m   = C6V67R15 + C6V69R15
gen capital_f_car = C6V68R15

gen building_deprec = C6V66R16
gen machequip_deprec = C6V67R16 + C6V69R16
gen transport_deprec = C6V68R16
gen total_deprec = building_deprec + machequip_deprec + transport_deprec
*C6V66R7 VALORIZACION - No va a valor libro
*C6V6613 DESVALORIZACION

*c7r5c7 
*replace total_deprec        = building_deprec     + machequip_deprec     + transport_deprec
*gen total_invest_eslava     = total_bookvalue     - total_prebalance     + total_deprec     - total_inflation

********************************************************************************	
*** Key variables
********************************************************************************
gen labor = C8V81R5 + C8V82R5 + C8V83R5 + C8V84R5 + C8V85R5 + C8V86R5
gen total_wb = SALPEYTE + PRESPYTE
ren CONSIN2 inter_input
gen total_invest_direct = total_purchase - total_sales
gen capital_i     = capital_i_bd + capital_i_m + capital_i_car
gen capital_f     = capital_f_bd + capital_f_m + capital_f_car
gen total_invest_eslava = capital_f + capital_i + total_deprec

//Use industry to fetch sector from ciiu converter file
ren industry grupo_ciiu2
merge m:m grupo_ciiu2 using "$output_data/col_ciiu2", keepusing(sector)
drop if _merge == 2
drop _merge
ren grupo_ciiu2 agrupacion_ciiu2
merge m:m agrupacion_ciiu2 using "$output_data/col_ciiu2", keepusing(sector_agrupacion)
drop if _merge == 2
drop _merge
ren agrupacion_ciiu2 division_ciiu2
merge m:m division_ciiu2 using "$output_data/col_ciiu2", keepusing(sector_division)
drop if _merge == 2
drop _merge
ren division_ciiu2 grupo_ciiu2
merge m:m grupo_ciiu2 using "$output_data/col_ciiu2", keepusing(sector_grupo)
drop if _merge == 2
drop _merge
//We merge several times because there are firms cliassified under differents levels of aggregation of ciiu classification
//Now, we generate a unique sector variable
ren grupo_ciiu2 ciiu
foreach var in sector sector_division sector_agrupacion sector_grupo{
	replace `var' = 0 if `var' == .
}
replace sector = sector + sector_division + sector_agrupacion + sector_grupo
drop sector_*

order id year labor total_wb inter_input total_invest_direct total_invest_eslava capital_i capital_f ciiu sector
qui save "$output_data/EAM_9294.dta", replace
/*
********************************************************************************	
*** Construct a price index consistent with Roberts and Tybout
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
keep if year > 1990 & year < 1995
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

use "$output_data/EAM_9294.dta", clear
merge m:1 year using `priceindex', keepusing(iprice)
drop if _merge == 2
drop _merge
qui save "$output_data/EAM_9294.dta", replace
*/
********************************************************************************	
*** Drop observations
********************************************************************************
count
*Full sample = 23561 obs

****Baley - Blanco filter****

*Drop small plants with < 10 workers throughout the sample period
sort id year
by id: egen max_size = max(labor)
gen error_size = 1 if max_size < 10
tab error_size
*639 plants

*Drop plants with more than 90% of zero total investment, or non-positive key variables
sort id year
by id: egen iblank = count(total_invest_direct) if total_invest_direct==0
by id: gen maxyear = year[_N]
by id: gen minyear = year[1] //Drop at the end
gen life = maxyear - minyear + 1
gen zeroinv = iblank/life
replace zeroinv = 0 if zeroinv == .
gen error_zeroinv = 1 if zeroinv >= 0.9
tab error_zeroinv
*2252 plants

*Drop obs with non positive value of book capital, wage bills and sales
gen error_sales=1 if VALORVEN<= 0
tab error_sales
*855 obs
gen error_total_wb = 1 if total_wb<=0
tab error_total_wb
*55 obs
gen error_capital = 1 if capital_f<=0 & total_invest_direct<=0
tab error_capital
*176 obs

*Drop investment outliers
gen irate = total_invest_direct/capital_i
egen ip98 = pctile(irate), by(year) p(98)
egen ip2 = pctile(irate), by(year) p(2)
gen error_irate = 1 if irate>ip98 | irate<ip2
tab error_irate
*1365 obs

****Roberts-Tybout filter****
*Drop observations with nominal dep>book value, negative pch and sell

/*
gen error_sale=1 if mchsell+carsell+bdsell>mchby+carby+bldgby
replace error_sale=0 if error_sale==.
*/
gen error_dep=1 if total_deprec>capital_i
replace error_dep=0 if error_dep==.
tab error_dep
*208 obs

gen error_pch=1 if building_purchase<0|machequip_purchase<0|transport_purchase<0
replace error_pch=0 if error_pch==.
tab error_pch
*0 obs
/*
*drop ones with negative capital stocks in equipment
gen error_cap=1 if qk<=0
replace error_cap=0 if error_cap==.
tab error_cap
*/

*drop ones with negative total revenue, total material, total labor costs
gen error_rev=1 if VALORVEN<=0|total_wb<=0|labor<=0
replace error_rev=0 if error_rev==.
tab error_rev
*906 obs

****Summary of plants to be dropped****
gen dumdrop = 0
foreach i in size sales total_wb capital zeroinv irate dep pch cap rev{
	replace dumdrop = dumdrop + cond(missing(error_`i'), 0, error_`i')
}
replace dumdrop = 1 if dumdrop > 0
tab dumdrop
*Attrition: 20.07% sample
*Now check share of investment dropped
bysort year: egen yrinvest = sum(total_invest_direct)
bysort year: egen invshrerror = sum(total_invest_direct*dumdrop)
gen invdrop = invshrerror/yrinvest
table year, c(mean invdrop)
*Max invest dropped: 2% in 1993

****Drop them****
drop if dumdrop == 1
count
*From 76094 to 18468 ---> 4638 obs deleted

drop dumdrop invdrop yrinvest invshrerror
drop ip98 ip2
drop error_*
drop iblank life zeroinv irate max_size maxyear minyear

qui save "$output_data/EAM_9294.dta", replace

********************************************************************************	
*** Set up to merge with Chile master
********************************************************************************
*Investment per asset type
gen inv_stru = (building_purchase - building_sales)
gen inv_mach = (machequip_purchase - machequip_sales)
gen inv_vehi = (transport_purchase - transport_sales)

*Rename and order
ren total_wb wage_bill
ren VALORVEN sales
ren capital_f_bd capital_f_stru
ren capital_f_car capital_f_vehi
ren capital_f_m capital_f_mach
ren total_invest_direct inv_total

order id id_firm year ciiu sector labor wage_bill sales capital_f_stru capital_f_vehi capital_f_mach capital_f inv_stru inv_mach inv_vehi inv_total
drop inter_input - total_deprec

save "$output_data/colombia_1992_1994.dta", replace
