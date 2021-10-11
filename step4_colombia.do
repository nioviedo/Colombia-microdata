********************************************************************************
*** Set up Colombian data 1995-2016
********************************************************************************
*** Main inputs: EAM_panel
*** Additional inputs: col_ciiu2, ciiu4vciiu3
*** Output: colombia_1995_2016
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
log using "$temp_file/step4colombia.log", append

cd "$output_data"

********************************************************************************	
*** Add sector
********************************************************************************
use "$input_data/EAM_panel", clear
compress

*CIIU 2
ren industry grupo_ciiu2
merge m:m grupo_ciiu2 using col_ciiu2.dta, keepusing(sector_grupo)
replace sector = . if year > 2001
drop if _merge ==2
drop _merge

*CIIU3
ren grupo_ciiu2 clase_ciiu3
merge m:m clase_ciiu3 using col_ciiu2.dta, keepusing(sector_ciiu3)
replace sector_ciiu3 = . if year > 2011 | year < 2001
drop if _merge == 2
drop _merge

*CIIU4
ren clase_ciiu3 ciiu4
merge m:m ciiu4 using ciiu4vciiu3.dta, keepusing(sector_ciiu4)
replace sector_ciiu4 = . if year < 2012
drop if _merge == 2
replace sector_ciiu4 = 8 if year > 2011 & ciiu4 == 3315

*Sector
ren ciiu4 ciiu
gen sector = cond(missing(sector_grupo),0, sector_grupo) + cond(missing(sector_ciiu3),0, sector_ciiu3) + cond(missing(sector_ciiu4),0, sector_ciiu4)
replace sector = . if sector == 0

*Drop observations duplicated during ciiu merge
duplicates report id year
duplicates list id year
drop if id == 142024 & year == 2015 & sector == 5
drop in 179960/179961
drop in 179960
drop in 179960
********************************************************************************	
*** Investment
********************************************************************************
replace total_bookvalue     = building_bookvalue  + machequip_bookvalue  + transport_bookvalue
replace total_prebalance    = building_prebalance + machequip_prebalance + transport_prebalance
replace total_deprec        = building_deprec     + machequip_deprec     + transport_deprec
replace total_inflation     = building_inflation  + machequip_inflation  + transport_inflation
gen total_purchase      	= building_purchase   + machequip_purchase   + transport_purchase
gen total_sales        		= building_sales      + machequip_sales      + transport_sales

replace building_invest_eslava  = (building_bookvalue  - building_prebalance  + building_deprec  - building_inflation) 
replace machequip_invest_eslava = (machequip_bookvalue - machequip_prebalance + machequip_deprec - machequip_inflation)
replace transport_invest_eslava = (transport_bookvalue - transport_prebalance + transport_deprec - transport_inflation)
gen total_invest_eslava     	= (total_bookvalue     - total_prebalance     + total_deprec     - total_inflation)

replace building_invest_direct  = building_purchase  - building_sales
replace machequip_invest_direct = machequip_purchase - machequip_sales
replace transport_invest_direct = transport_purchase - transport_sales
replace total_invest_direct     = total_purchase     - total_sales

/*
rename total_prebalance  capital_i 
rename total_bookvalue   capital_f 	
*/
order id year labor total_wb total_invest_direct total_invest_eslava capital_i capital_f  

********************************************************************************	
*** Statistics and data cleansing
********************************************************************************
count
*179959 observations

****Baley - Blanco filter****

*Drop small plants with < 10 workers throughout the sample period
sort id year
by id: egen max_size = max(labor)
gen error_size = 1 if max_size < 10
tab error_size
*9036 plants

*Drop plants with more than 90% of zero total investment, or non-positive key variables
by id: egen iblank = count(total_invest_direct) if total_invest_direct==0
by id: gen maxyear = year[_N]
by id: gen minyear = year[1] //Drop at the end
gen life = maxyear - minyear + 1
gen zeroinv = iblank/life
replace zeroinv = 0 if zeroinv == .
gen error_zeroinv = 1 if zeroinv >= 0.9
tab error_zeroinv
*9598 plants

*Drop plants with less than 3 years of coverage
by id: gen count=_N
gen error_count = 1 if count<=3 
tab error_count
*7070 plants

*Drop obs with non positive value of book capital, wage bills and sales
gen error_sales=1 if valorven< 0
tab error_sales
*6 obs
gen error_total_wb = 1 if total_wb<=0
tab error_total_wb
*2583 obs
gen error_capital = 1 if capital_f<=0 & total_invest_direct<0
tab error_capital
*1917 obs

*Investment outliers
gen irate = total_invest_direct/capital_i
egen ip98 = pctile(irate), by(year) p(98)
egen ip2 = pctile(irate), by(year) p(2)
gen error_irate = 1 if irate>ip98 | irate<ip2
tab error_irate
*9460 obs

****Roberts-Tybout filter****
gen error_dep=1 if total_deprec>capital_i & year > 1995
//Exclude 1995 due to missing depreciation in that year
replace error_dep=0 if error_dep==.
tab error_dep
*723 obs

gen error_pch=1 if building_purchase<0|machequip_purchase<0|transport_purchase<0
replace error_pch=0 if error_pch==.
tab error_pch
*4 obs

gen error_rev=1 if valorven<0|total_wb<0|labor<=0
replace error_rev=0 if error_rev==.
tab error_rev
*444 observations

****Summary of plants to be dropped****
gen dumdrop = 0
foreach i in size sales total_wb capital zeroinv irate dep pch cap rev{
	replace dumdrop = dumdrop + cond(missing(error_`i'), 0, error_`i')
	table year, c(sum error_`i')
}
replace dumdrop = 1 if dumdrop > 0
tab dumdrop
*Attrition: 17.44% sample
*Now check share of investment dropped
bysort year: egen yrinvest = sum(total_invest_direct)
gen invs = total_invest_direct*dumdrop
bysort year: egen invshrerror = sum(invs)
gen invdrop = invshrerror/yrinvest
table year, c(mean invdrop)
*Max invest dropped: 53% in 2015

****Drop them****
drop if dumdrop == 1
count
*From 179959 to 151823 ---> 28136 obs deleted

drop dumdrop invdrop yrinvest invshrerror
drop ip98 ip2
drop error_*
drop iblank life zeroinv irate max_size maxyear minyear invs

qui save "$output_data/EAM_9516.dta", replace

********************************************************************************	
*** Set up to merge with master
********************************************************************************
ren building_invest_direct inv_stru
ren machequip_invest_direct inv_mach
ren transport_invest_eslava inv_vehi
ren total_invest_direct inv_total
ren total_wb wage_bill
ren nordemp id_firm
ren building_bookvalue capital_f_stru
ren machequip_bookvalue capital_f_mach
ren transport_bookvalue capital_f_vehi
ren valorven sales

order id id_firm year ciiu sector labor wage_bill sales capital_f_stru capital_f_vehi capital_f_mach capital_f inv_stru inv_mach inv_vehi inv_total

drop total_invest_eslava - total_purchase
capture drop count

save colombia_1995_2016, replace