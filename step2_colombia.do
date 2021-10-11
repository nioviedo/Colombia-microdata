********************************************************************************
*** Clean Colombian investment data 
********************************************************************************
*** Main inputs: col_raw
*** Additional inputs: 
*** Output: col_data_clean
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
global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/step2colombia.log", append

cd "$output_data"
use col_raw, clear

********************************************************************************	
*** Generate key variables
********************************************************************************
****Intermediate consumption and value added****
*Construct new measures more consistent with data beginning in 1995
gen ic_new = viexp + vm + epur_v + econ_v + (bdrent + mchrent + c11 + c12)
*ic_new = c7 + s10 + e5 + e7 + (c8 + c10 + c11 + c12)
gen pg_new = tsales + n7 - n3 + esold_v - n2 + t6 + t9
*pg_new = s5 + n7 - n3 + e6 + n6 - n2 + t6 + t9
gen va_new = (pg_new - ic_new)
*Nominal variables
lab var ic_new "Intermediate consumption under new methodology"
lab var pg_new "Gross production under new methodology"
lab var va_new "VA under new methodology, computed as diff btw pg_new and ic_new"
*Significant no. of missing values for t6 and t9 in 1990

****Book value of capital EOY****
sort plant year
by plant: gen capital_f = ecap_b[_n+1] if year ~= maxyear
replace capital_f = . if year == 91

/*gen capital_f =.
sort plant year
by plant: replace capital_f=ecap_p[_n+1] if year~=maxyear
by plant: replace capital_f=ecap_p + einv + eret if year==maxyear
*gen total_invest_eslava = capital_f - ecap_b + eret
*/

****Investment following Eslava****
sort plant year
gen total_invest_eslava = (capital_f - ecap_b)/iprice + eret
lab var total_invest_eslava "Gross investment following Eslava"

gen total_invest_eslava_r = (capital_f - ecap_b +i22 - i17)/iprice + eret
lab var total_invest_eslava_r "Gross investment by Eslava including reappraisals"

****Rename, label and reorder****
ren plant id
ren twkr labor
ren vl total_wb
ren ic_new inter_input
ren einv total_invest_direct
ren ecap_b capital_i
*ren ecap_p cpaital_i
*ecap_p=ecap_p[_n-1]+einv[_n-1]-eret[_n-1] if year~=minyear

label var total_wb "total salaries + total benefits"
lab var total_invest_direct "Gross Investment: capital purchases net of sales"
lab var capital_f "Book value of capital EOY"
lab var capital_i "Book value of capital BOY"

order id year labor total_wb inter_input total_invest_direct total_invest_eslava capital_i capital_f

save col_data_clean, replace

********************************************************************************	
*** Drop observations
********************************************************************************
count
*Full sample = 76094 obs

****Baley - Blanco filter****

*Drop small plants with < 10 workers throughout the sample period
by id: egen max_size = max(labor)
gen error_size = 1 if max_size < 10
tab error_size
*2786 plants

*Drop plants with more than 90% of zero total investment, or non-positive key variables
by id: egen iblank = count(total_invest_direct) if total_invest_direct==0
gen life = maxyear - minyear + 1
gen zeroinv = iblank/life
replace zeroinv = 0 if zeroinv == .
gen error_zeroinv = 1 if zeroinv >= 0.9
tab error_zeroinv
*6144 plants

*Drop plants with less than 3 years of coverage
by id: gen count=_N
gen error_count = 1 if count<=3 
tab error_count
*12064 plants

*Drop obs with non positive value of book capital, wage bills and sales
gen error_sales=1 if tsales<= 0
tab error_sales
*55 obs
gen error_total_wb = 1 if total_wb<=0
tab error_total_wb
*512 obs
gen error_capital = 1 if capital_f<=0 & total_invest_direct<=0
tab error_capital
*283 obs

*Drop investment outliers
gen irate = total_invest_direct/capital_i
egen ip98 = pctile(irate), by(year) p(98)
egen ip2 = pctile(irate), by(year) p(2)
gen error_irate = 1 if irate>ip98 | irate<ip2
tab error_irate
*3701 obs

****Roberts-Tybout filter****
*Drop observations with nominal dep>book value, negative pch and sell

/*
gen error_sale=1 if mchsell+carsell+bdsell>mchby+carby+bldgby
replace error_sale=0 if error_sale==.
*/
gen error_dep=1 if mchdep+cardep+bddep>mchby+carby+bldgby
replace error_dep=0 if error_dep==.
tab error_dep
*691 obs

gen error_pch=1 if mchpch<0|carpch<0|bdpch<0|mchsell<0|carsell<0|bdsell<0
replace error_pch=0 if error_pch==.
tab error_pch
*0 obs

*drop ones with negative capital stocks in equipment
gen error_cap=1 if qk<=0
replace error_cap=0 if error_cap==.
tab error_cap
*369 obs

*drop ones with negative total revenue, total material, total labor costs
gen error_rev=1 if q<=0|vm<=0|total_wb<=0|labor<=0
replace error_rev=0 if error_rev==.
tab error_rev
*1207 obs

****Summary of plants to be dropped****
gen dumdrop = 0
foreach i in size sales total_wb capital zeroinv count irate dep pch cap rev{
	replace dumdrop = dumdrop + cond(missing(error_`i'), 0, error_`i')
}
replace dumdrop = 1 if dumdrop > 0
tab dumdrop
*Attrition: 24.65% sample
*Now check share of investment dropped
bysort year: egen yrinvest = sum(total_invest_direct)
bysort year: egen invshrerror = sum(total_invest_direct*dumdrop)
gen invdrop = invshrerror/yrinvest
table year, c(mean invdrop)
*Max invest dropped: 23.8% in 1981

****Drop them****
drop if dumdrop == 1
count
*From 76094 to 57338 ---> 18756 obs deleted

drop dumdrop invdrop yrinvest invshrerror
drop ip98 ip2
foreach i in size sales total_wb capital zeroinv count irate dep pch cap rev{
	drop error_`i'
}

corr ecap_p capital_i
*corr = 0.78

save col_data_clean, replace
********************************************************************************	
*** Time consistency
********************************************************************************
/*
***Discontinuous plants***
sort id year
gen yrc = 1 
by id: replace yrc = year[_n] - year[_n - 1] if _n > 1
preserve
keep if yrc > 1
by id, sort: gen nvals  = _n == 1
count if nvals
*1222 obs, 1078 plants

****Detect plants with inconsistent birth year****
sort id year
egen mborn=mean(yborn), by (id)
gen dborn=(yborn-mborn)^2
egen vborn=sum(dborn), by (id)
sum vborn, d

replace vborn = 1 if vborn > 0

*Drop them
replace yborn=. if vborn>0
drop if yborn==.
*3315 observations deleted

*Define first year that a plant is in sample
egen miny=min(year), by (id)
egen maxy=max(year), by (id)

*Define cohorts -> this loop gives a quick outlook on the evolution of each cohort
foreach y in 81 82 83 84 85 86 87 88 89 90 91{
	gen cohort`y'=1 if yborn==`y'
	replace cohort`y'=0 if yborn==.
	gen scohort`y'=1 if yborn==`y'&miny==`y'
	replace scohort`y'=0 if yborn==`y'&miny>`y'
}

foreach y in 81 82 83 84 85 86 87 88 89 90 91{
	table scohort`y' year, c(sum vq)
	table scohort`y' year, c(n vq)
}
*/
********************************************************************************	
*** Consistency checks
********************************************************************************
use col_data_clean, clear

****1. Construct inputted capital using fixed depreciation rates****
preserve
local rate_mch = 0.11
local rate_off= 0.11 
local rate_bd = 0.03
local rate_car = 0.15
gen kapital = 0
ren bldgby bdby
foreach type in mch car bd off{
	gen einv_`type'= (`type'pch  + o`type'pch - `type'sell)/iprice
	gen kapital_`type' = `type'by
	sort id year
	by id: replace kapital_`type' = (1-`rate_`type'')*kapital_`type'[_n-1] + einv_`type'[_n-1] if year~=minyear
replace kapital = kapital + kapital_`type'
}
ren bdby bldgby
corr ecap_p kapital
*corr = 0.99

****2. Reported book value vs perpetual inventory****

*Construct inputted capital stock per asset type
preserve
ren bldgby bdby
foreach type in mch car bd off{
	gen einv_`type'= (`type'pch  + o`type'pch - `type'sell)/iprice //Investment per asset category
	gen ecap_p_`type' = `type'by 
	sort id year
	by id: replace ecap_p_`type' = ecap_p_`type'[_n-1] + einv_`type'[_n-1] - `type'dep[_n-1]/iprice[_n-1] if year~=minyear
	//Inputted capital capital stock per type using perpetual inventory method
}
gen ecap_p_m = ecap_p_mch + ecap_p_off
gen mby = (mchby + offby)/iprice
replace bdby = bdby/iprice
replace carby = carby/iprice

collapse (sum) ecap_p_m ecap_p_car ecap_p_bd mby bdby carby ecap_p capital_i, by(year)
//Log scale with 0 in 1981
foreach var in ecap_p_m ecap_p_car ecap_p_bd mby bdby carby ecap_p capital_i{
	gen `var'_idx = `var'/`var'[1]
	replace `var'_idx = log(`var'_idx)
	lab var `var'_idx "Perpetual inventory"
}
lab var mby_idx       "Real reported value"
lab var bdby_idx      "Real reported value"
lab var carby_idx     "Real reported value"
lab var capital_i_idx "Real reported value"
/*
*Plot reported book value vs perpetual inventory
foreach cat in m car bd{
	#delim ;
	line ecap_p_`cat'_idx `cat'by_idx year, 
	lpattern(dash solid) lwidth(vthin vthin) lcolor(black red)
	name(f`cat',replace) 
	legend(ring(0) col(1) bmargin(-20 0 51 0)  region(lpattern(blank)))  
	xscale(range(80 92)) 
	yscale(range(0 3)) 
	xlabel(80(1)91) 
	ylabel(0(.5)3);
	#delim cr
	gr export "$figures/capital_consistency_`cat'.png", replace
}
*/
#delim ;
line capital_i_idx ecap_p_idx year, 
lpattern(solid dash) lwidth(vthin vthin) lcolor(red black)
name(ftotal,replace) 
legend(ring(0) col(1) bmargin(-20 0 51 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(0 3)) 
xlabel(80(1)91) 
ylabel(0(.5)3);
#delim cr

gr export "$figures/capital_consistency_total.png", replace

****3.Broad measure of investment****
use col_data_clean, clear

preserve
gen inv_broad = total_invest_direct + i16 + c1/iprice + (i22 - i17)/iprice
corr inv_broad total_invest_direct
//corr = .92
collapse(sum) inv_broad total_invest_direct, by(year)
//Log scale with 0 in 1981
foreach var in inv_broad total_invest_direct{
	gen `var'_idx = `var'/`var'[1]
	replace `var'_idx = log(`var'_idx)
}
lab var inv_broad_idx "Investment (broad measure)"
lab var total_invest_direct_idx "Investment"
//Plot
#delim ;
line inv_broad_idx total_invest_direct_idx year, 
name(invb,replace) 
legend(ring(0) col(1) bmargin(-32 0 70 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
xlabel(80(1)91);
#delim cr

gr export "$figures/invest_consistency_total.png", replace

****4. Payments due****
//We try to identify anomalies by looking plants with low investment volatility
use col_data_clean, clear

bysort id: egen inv_avg = mean(total_invest_direct)
bysort id: egen inv_sd = sd(total_invest_direct)
gen inv_cv = abs(inv_sd/inv_avg)
br id year total_invest_direct inv_avg inv_sd inv_cv if inv_cv < 0.03001
//Max. 40 obs., less than 3 years
drop inv_cv inv_avg inv_sd

****5. Deflators****
tempfile deflator8091
save `deflator8091', emptyok
import excel using "$input_data/aux_doc/1.3.1.3 IPP_Segun uso o destino economico_anual_IQY.xlsx", clear
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
drop if year > 1991 | year < 1981
replace year = year - 1900
foreach var in ic cpi k bd{
	gen ip_`var'= ipricecb_`var'/ipricecb_`var'[1]
}
save `deflator8091', replace
merge 1:m year using "$output_data/col_data_clean", keepusing(iprice)

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
legend(ring(0) col(1) bmargin(2 0 55 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(0 10)) 
xlabel(80(1)91) 
ylabel(0(1)10);
#delim cr
gr export "$figures/colombia_deflators.png", replace

****6.Penn World Table****
use "$pathinit/Data/inputs/pwt100.dta", clear
keep if countrycode == "COL" & year > 1980 & year < 1992
replace year = year - 1900
merge 1:m year using col_data_clean, keepusing(iprice capital_f capital_i)

*Deflator
foreach var in c i g x m n k{
	gen opl_`var'= pl_`var'/pl_`var'[1]
}
preserve
collapse (firstnm) opl_i opl_n iprice, by(year)
lab var opl_i "Price level of capital formation"
lab var opl_n "Price level of capital stock"
lab var iprice "Price index R-T"
#delim;
line opl_n opl_i iprice year,
name(pwt,replace) 
legend(ring(0) col(1) bmargin(-10 0 55 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(0 10)) 
xlabel(80(1)91) 
ylabel(1(1)10);
#delim cr

gr export "$figures/col_deflators_pwt.png", replace

*Capital stock
bysort year: egen capital_i_sum = total(capital_i)
collapse(firstnm) rnna capital_i_sum iprice, by(year)
gen real_capital_i = capital_i_sum/iprice
corr real_capital_i rnna

replace real_capital_i = real_capital_i/1000
gen l1 = log(rnna)
lab var l1 "Capital stock at 2017 prices"
gen l2 = log(real_capital_i)
lab var l2 "Real capital stock R-T data"

#delim;
line l* year,
name(pwtk,replace) 
legend(ring(0) col(1) bmargin(2 0 20 0)  region(lpattern(blank)))  
xscale(range(80 92)) 
yscale(range(10 14)) 
xlabel(80(1)91)
ylabel(10(1)14);
#delim cr

gr export "$figures/col_capital_pwt.png", replace

****7. GDP****
import excel using "$input_data/aux_doc/pib_1975.xlsx", clear
drop in 1/8
drop in 28/54
compress
drop C D E G H I J
ren A year
ren B gdp
ren F real_gdp
destring year-real_gdp, replace
keep if year > 1980 & year < 1992
replace year = year - 1900
merge 1:m year using "$output_data/col_data_clean", keepusing(v va tsales)
//Generate total by year
foreach x in va tsales v{
	bysort year: egen agr_`x' = sum(`x')
}
collapse (firstnm) agr* real_gdp gdp, by(year)
drop if year == 81
//Transform into index
foreach var in agr_va agr_tsales agr_v real_gdp gdp{
	gen i_`var'= `var'/`var'[1]
}

lab var i_agr_va "Value added RT index"
lab var i_agr_v "Real value added RT index"
lab var i_gdp "Nominal GDP"
lab var i_real_gdp "Real GDP"
lab var i_agr_tsales "Firm sales"

line i_agr_va i_gdp year
gr export "$figures/col_nominalgdp.png", replace

line i_agr_v i_real_gdp year
gr export "$figures/col_realgdp.png", replace

line i_agr_tsales i_gdp year
gr export "$figures/col_nominalsales.png", replace

****8. Check value added per firm****
use col_data_clean, clear
preserve
gen contador = 1
collapse (sum) v va contador, by(year)
gen va_firm = log(va/contador)
lab var va_firm "Nominal value added per firm (log scale)"
gen v_firm = log(v/contador)
lab var v_firm "Real value added per firm (log scale)"
drop if year == 81 //Because va = 0
*line va_firm year
*gr export "$figures/col_logva.png", replace
line v_firm year, name(l, replace)
gr export "$figures/col_logv.png", replace

****9. Investment rate****
tempfile investnaa
save `investnaa', emptyok
//Clean national accounts data
import excel using "$input_data/aux_doc/pib_anual_Base1975/Cuentas Consolidadas y Resultados Generales/ctas_nles_agregados macroeconómicos a precios constantes de 1975, 1970-95.xls", clear
drop in 1/3
drop in 15/17
ren A conceptos
local yr = 1970
forvalues i = 2/26{
	local letter : word `i' of `c(ALPHA)' 
	ren `letter' inc_`yr'
	local yr = `yr' + 1	
}
ren AA inc_1995
destring(inc_1995), replace
drop in 1
drop if inc_1970 == .
reshape long inc_, i (conceptos) j(year)
ren inc_ value
compress
replace conceptos = "I" if conceptos == "Inversión nacional (FBK)"
replace conceptos = "PBI" if conceptos == "Producto interno bruto"
replace conceptos = "K" if conceptos == "    Formación bruta de capital fijo"
keep if conceptos == "I" | conceptos == "PBI" | conceptos == "K"
//Construct and keep investment rates
gen sorter = _n
replace sorter = sorter * 100 if conceptos == "K"
sort sorter year
gen irate = .
local j = 27
forvalues x=1/26{
	replace irate = value[`x']/value[`j'] in `x'
	local j = `j' + 1
}
gen krate = .
local j = 27
forvalues y = 53/78{
	replace krate = value[`y']/value[`j'] in `y'
	local j = `j' + 1
}
drop sorter
collapse (firstnm) irate krate, by(year)
drop if year > 1991 | year < 1981
save `investnaa', replace
//Merge with master
use col_data_clean, clear
preserve
replace year = year + 1900
merge m:1 year using `investnaa', keepusing(irate krate)
bysort year: egen number = count(id)
replace irate = irate/number // So collapse to recover total rate per year
replace krate = krate/number
replace capital_i = capital_i/iprice // Capital BOY in real terms
replace capital_f = capital_f/iprice // Capital EOY in real terms
//Collapse to plot
collapse (sum) total_invest_eslava total_invest_direct capital_i capital_f irate krate, by (year)
gen total_investrate_eslava = total_invest_eslava/(0.5*(capital_i + capital_f))
gen total_investrate_direct = total_invest_direct/(0.5*(capital_i + capital_f))
//Label variables
lab var total_investrate_eslava "Total investment rate by Eslava"
lab var total_investrate_direct "Total investment rate"
lab var irate "National Investment/GDP"
lab var krate "National Investment net of inventories/GDP"
drop if year == 1991 // Because capital_f = 0
twoway line total_investrate_eslava total_investrate_direct irate krate year, legend(size(vsmall))
gr export "$figures/col_irates.png", replace

********************************************************************************	
*** Set up to merge with Chile master
********************************************************************************
*CIIU sector
use col_data_clean, clear

ren sic grupo_ciiu2
merge m:m grupo_ciiu2 using col_ciiu2, keepusing(sector_grupo)
drop if _merge == 2
drop _merge
ren sector_grupo sector

*Investment per asset type
ren bldgby bdby
foreach type in mch car bd off{
	gen inv_`type'= (`type'pch  + o`type'pch - `type'sell)/iprice //Investment per asset category
}
gen inv_mach = inv_mch + inv_off
ren inv_bd inv_stru
ren inv_car inv_vehi
gen inv_total = inv_mach + inv_vehi + inv_stru

*Capital EOY per asset type
sort id year
by id: gen capital_f_stru = bdby[_n+1] if year ~= maxyear
by id: gen capital_f_mach = mchby[_n+1] + offby[_n+1] if year ~= maxyear
by id: gen capital_f_vehi = carby[_n+1] if year ~= maxyear

foreach k in stru mach vehi{
	replace capital_f_`k' = . if year == 91
}

*Rename and order
gen id_firm = .
ren grupo_ciiu2 ciiu
ren total_wb wage_bill
ren tsales sales
replace year = year + 1900

order id id_firm year ciiu sector labor wage_bill sales capital_f_stru capital_f_vehi capital_f_mach capital_f inv_stru inv_mach inv_vehi inv_total

drop inter_input - inv_off
save colombia_1981_1991, replace
