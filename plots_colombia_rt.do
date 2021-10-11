********************************************************************************
*** Some time series plots for Colombia 1981-1991
********************************************************************************
*** Main inputs: col_data_clean
*** Additional inputs: 
*** Output: various .png
*** Author: Nicolas Oviedo
*** Original: 04/16/2021
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
*global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia/Roberts-Tybout"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/plotscolombiart.log", append

cd "$output_data"

use col_data_clean, clear

********************************************************************************	
*** Investment
********************************************************************************
preserve
collapse (sum) total_invest_direct total_invest_eslava total_invest_eslava_r, by(year)

gen log_tid = log(total_invest_direct)
lab var log_tid "log of real gross estimated investment net of sales"
summ log_tid

gen log_tie = log(total_invest_eslava)
lab var log_tie "log of real gross investment following Eslava"
summ log_tie

gen log_ier = log(total_invest_eslava_r)
lab var log_ier "log of real gross investment following Eslava with reappraisal"
summ log_ier
/*
*Three measures of investment
#delim ;
line log_tid log_tie log_ier year, 
lwidth(thick thick thick thick) lcolor(navy olive maroon cyan)
name(f5,replace) 
title(Gross real investment - various methods) 
legend(ring(0) col(1) bmargin(2 0 51 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(15 25)) 
xlabel(80(1)91) 
ylabel(15(1)25)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_invest_global.png", replace

*Total investment by Eslava with reaprraisals
#delim ;
line log_ier year, 
lwidth(thick) lcolor(cyan)
name(f4,replace) 
title(Gross investment following Eslava with reappraisals) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(17 19)) 
xlabel(80(1)91) 
ylabel(17(.4)19)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_invest_eslava_r.png", replace

*Total investment by Eslava
#delim ;
line log_tie year, 
lwidth(thick) lcolor (olive)
name(f2,replace) 
title(Gross investment following Eslava) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(17 19)) 
xlabel(80(1)91) 
ylabel(17(.4)19)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_total_invest_eslava.png", replace
*/

*Total investment as measured by Roberts-Tybout
#delim ;
line log_tid year, 
lwidth(thick) lcolor(navy)
name(f1,replace) 
title(Gross investment) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(17 18)) 
xlabel(80(1)91) 
ylabel(17(.2)18)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_total_invest_direct.png", replace

********************************************************************************	
*** Capital stock
********************************************************************************
preserve
replace capital_i = capital_i/iprice
replace capital_f = capital_f/iprice
collapse (sum) ecap_p capital_i capital_f, by(year)

gen log_ecap = log(ecap_p)
lab var log_ecap "log of book value of inputted capital stock"
summ log_ecap

gen log_capital_i = log(capital_i)
lab var log_capital_i "log of book value of capital stock at beginning of year"
summ log_capital_i

gen log_capital_f = log(capital_f)
lab var log_capital_f "log of book value of capital stock at the end of year"
summ log_capital_f
/*
*Three measures of capital stock
#delim ;
line log_ecap log_capital_i log_capital_f year, 
lwidth(thick thick thick) lcolor(navy purple lime)
name(k4,replace) 
title(Capital stock) 
legend(ring(0) col(1) bmargin(2 0 20 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(17 20)) 
xlabel(80(1)91) 
ylabel(17(.5)20)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_capital_global.png", replace

*Log of book value of capital EOY
#delim ;
line log_capital_f year, 
lwidth(thick) lcolor(lime)
name(k3,replace) 
title(Capital stock) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(18 20)) 
xlabel(80(1)91) 
ylabel(18(.4)20)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_capital_f.png", replace

*Log of real value capital BOY
#delim ;
line log_capital_i year, 
lwidth(thick) lcolor(purple)
name(k2,replace) 
title(Capital stock) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(18 20)) 
xlabel(80(1)91) 
ylabel(18(.4)20)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_capital_i.png", replace
*/

*Log of real and inputted value of capital
#delim ;
line log_ecap year, 
lwidth(thick) lcolor(navy)
name(k1,replace) 
title(Capital stock) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(18 20)) 
xlabel(80(1)91) 
ylabel(18(.4)20)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_capital.png", replace

********************************************************************************	
*** Labor
********************************************************************************
preserve
replace total_wb = total_wb/iprice
collapse (sum) labor total_wb, by(year)
summ labor

gen log_wb = log(total_wb)
lab var log_wb "log total workers benefits"
lab var labor "Number of workers"
summ log_wb
/*
*Total payment
#delim ;
line log_wb year, 
lwidth(thick) lcolor(orange)
name(l2,replace) 
title(Workers benefits) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(18 19)) 
xlabel(80(1)91) 
ylabel(18(.2)19)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_labor_pay.png", replace
*/

*Total number of workers
#delim ;
line labor year, 
lwidth(thick) lcolor(navy)
name(l1,replace) 
title(Total labor) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(400000 440000)) 
xlabel(80(1)91) 
ylabel(400000(20000)440000)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_labor.png", replace

********************************************************************************	
*** Number of firms
********************************************************************************
preserve
bysort year: egen number = count(id)
collapse (firstnm) number, by(year)
lab var number "Number of plants"
twoway bar number year

gr export "$figures/col_firms.png", replace

********************************************************************************	
*** Real value added
********************************************************************************
use col_data_clean, clear

replace va_new = va_new/iprice

preserve
bysort year: egen number = count(id)
bysort year: egen va_total = sum(va_new)
bysort year: egen vas = sum(v)

collapse (firstnm) vas va_total number, by(year)
summ va_total

gen log_va = log(va_total)
lab var log_va "log value added"
lab var number "Number of plants"
summ log_va

gen log_vas = log(vas)
lab var log_vas "log value added R-T"
/*
*Own measure of value added and number of firms
twoway bar number year, yaxis(2) ||line log_va year, yaxis(1)
gr export "$figures/col_va_plants.png", replace

*Log of own measure of value added
#delim ;
line log_va year, 
lwidth(thick) lcolor(navy)
name(l1,replace) 
title(Value added) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(18 20)) 
xlabel(80(1)91) 
ylabel(18(.4)20)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_va.png", replace

//note: t6 explains valley

*Compare own measure of value added vs. Roberts-Tybout
#delim ;
line log_vas log_va year, 
lwidth(thick thick) lcolor(olive navy)
name(l2,replace) 
title(Value added) 
legend(ring(0) col(1) bmargin(-35 0 50 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(19 22)) 
xlabel(80(1)91) 
ylabel(19(.4)22)
note("Source: Roberts and Tybout data");
#delim cr

gr export "$figures/col_va_vas.png", replace
*/

*Unpacking value added new (nominal)
collapse (sum) tsales n7 n3 esold_v n6 n2 t6 t9, by(year)
lab var tsales "Total sales"
lab var n7 "Inventory EOY"
lab var n3 "Inventory BOY"
lab var esold_v "Energy sold"
lab var n6 "Goods in process EOY"
lab var n2 "Goods in process BOY"
lab var t6 "Indirect taxes"
lab var t9 "Subsidies"
line n7 n3 esold_v n2 t6 t9 year, title("Components of gross value of production")

gr export "$figures/col_pg_new.png", replace