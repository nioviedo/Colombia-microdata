********************************************************************************
*** Alternative ways to construct investment 
********************************************************************************
*** Main inputs: col_data_clean
*** Additional inputs: 
*** Output: 
*** Author: Nicolas Oviedo
*** Original: 04/28/2021
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
global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/alternativecolombia.log", append

cd "$output_data"
use col_data_clean, clear

********************************************************************************	
*** Investment Eslava using book values            
********************************************************************************
*First, construct book values
gen total_prebalance =  ecap_b
sort id year
by id: gen total_bookvalue = ecap_b[_n+1] if year ~= maxyear

gen eslava = (total_bookvalue - total_prebalance + i22 - i17)/iprice + eret
*gen eslavan = total_bookvalue - total_prebalance + eret*iprice

preserve
collapse (sum) eslava ecap_b total_bookvalue total_prebalance i22 i17 eret, by(year)
drop if year == 91
gen logeslava = log(eslava)
*line eslava year
*line logeslava year
twoway line total_bookvalue total_prebalance year
*twoway line i22 i17 year
*line eret year

*Now, compare with total investment
preserve
collapse (sum) eslava total_invest_direct, by(year)
drop if year == 91
gen logeslava = log(eslava)
gen loginv= log(total_invest_direct)
twoway line logeslava loginv year

* replace total_invest_direct = total_purchase - total_sales // No need to correct. In Baley and Blanco is nominal.

********************************************************************************	
*** Data issues     
********************************************************************************
*Panel data
xtset id year

*Empty asset revalue
gen revalue = i22 - i17
count if revalue == 0
*We see that 88% of reappraisals are null

*Same data for diferent id
gen same = year + labor + total_wb + inter_input + total_invest_direct + capital_i + capital_f
duplicates report same
*201
duplicates report labor capital_i capital_f year
*0
duplicates report labor total_wb capital_i year
*0
*All in all, no evidence of duplicated observations under different ids
