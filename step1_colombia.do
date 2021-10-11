********************************************************************************
*** Colombian investment data 
********************************************************************************
*** Main inputs: col81.dta - col91.dta
*** Additional inputs: 
*** Output: col_data_clean
*** Author: Nicolas Oviedo
*** Original: 03/23/2021
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
global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia/Roberts-Tybout"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/step1colombia.log", append

cd "$input_data/raw data"

********************************************************************************	
*** Compile Colombian Manufacturing Survey Data from 1980 to 1991
********************************************************************************
clear matrix
*set mem 800m

*****read in the raw data set
foreach y in 81 82 83 84 85 86 87 88 89 90 91{
 
 use col`y'.dta, clear
 *Baseline firm info
 rename x6 yborn
 rename x4 city
 
 *Labor 
 rename l1 twkr
 label var twkr "total employment"
 gen owner=l2+l10
 label var owner "number of owners not paid on fixed wage"
 gen wkr_m=l3+l11
 label var wkr_m "number of management staff"
 gen wkr_s=l4+l12
 label var wkr_s "number of skilled worker"
 gen wkr_u=l7+l15
 label var wkr_u "number of unskilled worker"
 gen wkr_th=l5+l13
 label var wkr_th "number of local technician"
 gen wkr_tf=l6+l14
 label var wkr_tf "number of foreign technician"
 gen wkr_a=l8+l16
 label var wkr_a "number of apprentice"
 
 rename w1 wage_m
 rename w2 wage_s
 rename w3 wage_th
 rename w4 wage_tf
 rename w5 wage_u
 rename w6 wage_a
 rename w7 twage
 label var twage "total salaries"
 
 rename w8 welf_m
 rename w9 welf_s
 rename w10 welf_th
 rename w11 welf_tf
 rename w12 welf_u
 rename w13 welf_a
 rename w14 twelf
 label var twelf "total benefits"
 
 *Energy
 rename e1 epur_q
 label var epur_q "energy purchased quantity"
 rename e2 egen_q
 label var egen_q "energy generated quantity"
 rename e3 esold_q
 label var esold_q "energy sold quantity"
 rename e4 econ_q
 label var econ_q "energy consumed quantity"
 rename e5 epur_v
 label var epur_v "energy purchased value"
 rename e6 esold_v
 label var esold_v "energy sold value"
 rename e7 econ_v
 label var econ_v "energy consumed value"
 
 *Sales
 rename s4 esales 
 rename s5 tsales
 
 *Total production
 rename pe vq     
 label var vq "value of production"
 
*Total value-added
 label var va "value-added"
  
 *Intermediate consumption
 *raw material
 rename s10 vm
 label var vm "raw material consumption"
 rename s11 vfm  
 label var vfm "foreign raw material consumption"
 
 *all other expenditure
 rename c7 viexp /*industrial expenditure*/ 
 label var viexp "industrial expenditure - note- intermediate is viexp+vm"
 *rename c17 vgexp /*general expenditure - NOT included in intermediates*/

*Capital 
*rental capital
 rename c8 bdrent
 rename c10 mchrent
*purchase/sell
 rename i1 bdpch
 rename i7 obdpch
 rename i2 mchpch
 rename i8 omchpch
 rename i3 carpch
 rename i9 ocarpch
 rename i4 offpch
 rename i10 ooffpch
 rename i24 bdsell
 rename i25 mchsell
 rename i26 carsell
 rename i27 offsell
 rename i29 bddep
 rename i30 mchdep
 rename i31 cardep
 rename i32 offdep
 rename i35 bldgby
 rename i36 mchby
 rename i37 carby
 rename i38 offby
 *reappraisal of fixed assets: i17 to i22
 
 *Keep key variables
 #delimit;
 keep plant year yborn city sic  twkr owner wkr_m wkr_s wkr_u wkr_th wkr_tf wkr_a twage wage_m wage_s wage_u wage_th wage_tf wage_a
 twelf welf_m welf_s welf_u welf_th welf_tf welf_a epur_q egen_q esold_q econ_q epur_v esold_v econ_v esales tsales vq va vm vfm ic viexp 
 bdrent mchrent bdpch obdpch mchpch omchpch carpch ocarpch offpch ooffpch bdsell mchsell carsell offsell bddep mchdep cardep offdep bldgby mchby carby offby
 i16 i17 i18 i19 i20 i21 i22 c1 c11 c12 n7 n6 n3 n2 t1 t3 t5 t6 t9;
 #delimit cr
 
 gen origin = "col`y'"
 lab var origin "raw data source"
 
 save "$output_data/mid`y'.dta", replace
}

*Rename mid91 col_data.dta and change cd
drop _all
cd "$output_data"

*Check for duplicates
/*foreach y in 81 82 83 84 85 86 87 88 89 90{
use mid`y', clear
tab year
duplicates report plant
}*/

shell ren "mid91.dta" "col_data.dta"
*Append all mid files
foreach y in 81 82 83 84 85 86 87 88 89 90{
 use col_data.dta, clear
 append using mid`y'.dta
 save col_data.dta, replace   
}
*duplicates report plant year
********************************************************************************	
*** Construct and label Roberts-Tybout variables
********************************************************************************
use col_data, clear

replace sic=floor(sic/10) if sic>6104
*Correct sector industrial code

label var plant "plant id"
label var sic "4 digit industry code"
label var yborn "year of establishment"

label var bdrent "rent of building"
label var mchrent "rent of machine"
label var bdpch "purchase of building"
label var mchpch "purchase of machine"
label var carpch "purchase of transportation equip"
label var offpch "purchase of office equip"

lab var omchpch "purchase of used machinery"
lab var ocarpch "purchase of used transportation"
lab var obdpch "purchase of used buildings and structures"
lab var ooffpch "purchase of used office equipment"

label var bddep "depreciation of building"
label var mchdep "depreciation of machine"
lab var cardep "depreciation of transportation"
lab var offdep "depreciation of office equipment"

label var bdsell "sales of building"
label var mchsell "sales of machine"
lab var carsell "sales of transportation"
lab var bdsell "sales of buildings"
lab var offsell "sales of office equipment"

label var bldgby "book value of building - beginning of year"
label var mchby "book value of machine - beginning of year"

label var tsales "total sales"
label var esales "export sales"

label var i17 "reappraisal of land"
label var i18 "reappraisal of buildings"
label var i19 "reappraisal of machinery"
label var i20 "reappraisal of transportation"
label var i21 "reappraisal of office equipment"
label var i22 "total reappraisal"

*Merge in industry-level price deflators
sort year sic

merge m:1 year using "$input_data/supp data/deflator.dta"
tab _merge
keep if _merge==3
drop _merge

lab var cpi "cpi base 1981"
lab var ipindx "intermediate price index base 1981"

****Construct the capital stock and investment flow using perpetual inventory method****

gen ecap_p=mchby+carby+bldgby+offby
gen ecap_b=mchby+carby+bldgby+offby
*Sum book value of machinery, transportation, buildings and office at beginning of year

gen einv=(mchpch+carpch+bdpch+offpch+omchpch+ocarpch+obdpch+ooffpch-mchsell-carsell-bdsell-offsell)/iprice
lab var einv "gross estimated investment, net of sales"
*Gross investment = Purchase of new capital + purchase of used capital - sells, in real terms

gen eret=(mchdep+cardep+bddep+offdep)/iprice
*Total depreciation of assets

sort plant year
by plant: egen minyear=min(year)
by plant: egen maxyear=max(year)
lab var minyear "first appearance in data"
lab var maxyear "last appearance in data"

by plant: replace ecap_p=ecap_p[_n-1]+einv[_n-1]-eret[_n-1] if year~=minyear
lab var ecap_p "estimated value of capital stock at beginning of year"
*K_t = K_{t-1} + I_{t-1} - delta_{t-1}

*Check consistency between book value and imputation method (corr = 0.77)
tabstat ecap_p, by (year) stat (p1 p5 p25 p50 p75 p95)
tabstat ecap_b, by (year) stat (p1 p5 p25 p50 p75 p95)
corr ecap_p ecap_b

****Construct material, labor, capital, and output measures****

*Total real revenue (gross value of production)
gen q=vq/cpi
lab var q "total real revenue"

*Inputs
gen qm=vm/cpi   /*raw matetial consumption*/
gen am=vm/vq 	/*material's expenditure share*/

*Value-added
gen vv=va
gen v=vv/cpi
lab var v "real value-added"
*sum v, d

*Labor input 
gen vl=twage+twelf
*Total salaries + Total benefits

*Capital and investment
gen qk=ecap_p+(bdrent+mchrent)/iprice/0.16            /*If 0.16 is a real rate -unable to confirm- that would be total available capital*/
lab var qk "estimated total available capital stock" 
gen qi=einv
lab var qi "real investment, net of capital sales"

****Construct firm level log(inputs) and log(output)****
gen lnv = ln(v)
lab var lnv "log real value-added"
gen lnq= ln(q)
lab var lnq "log total real revenue"

gen lnl = ln(twkr)
lab var lnl "log total employment"
gen lnk = ln(qk)
lab var lnk "log estimated capital stock with rents"
gen lnm = ln(qm)
lab var qm "log raw material consumption"

save col_raw, replace

***Checks****
*gen check = twage - wage_m - wage_s - wage_th - wage_tf - wage_u - wage_a
*summ check
*gen checki = i22 - i21 - i20 - i19 - i18 - i17
*tab checki

****Roberts-Tybout filter****
*drop anyone has nominal sales of capital>book value, nominal dep>book value, negative pch and sell
/*
gen error_sale=1 if mchsell+carsell+bdsell>mchby+carby+bldgby
replace error_sale=0 if error_sale==.

gen error_dep=1 if mchdep+cardep+bddep>mchby+carby+bldgby
replace error_dep=0 if error_dep==.

gen error_pch=1 if mchpch<0|carpch<0|bdpch<0|mchsell<0|carsell<0|bdsell<0
replace error_pch=0 if error_pch==.

*drop ones with negative capital stocks in equipment
gen error_cap=1 if qk<=0
replace error_cap=0 if error_cap==.

*drop ones with negative total revenue, total material, total labor costs
gen error_rev=1 if q<=0|vm<=0|vl<=0|twkr<=0
replace error_rev=0 if error_rev==.

gen ik=qi/qk
sum ik, d
lab var ik "investment/(1+r)K"
gen error_ik=1 if ik<-1|ik>10
replace error_ik=0 if error_ik==.

gen dumdrop=error_sale+error_dep+error_pch+error_cap+error_rev+error_ik
egen flagdrop=sum(dumdrop), by (plant)
replace flagdrop=1 if flagdrop>1
*now calculate share of output by plants that dropped each year
table year flagdrop, c(sum vq)

drop if error_sale==1|error_dep==1|error_pch==1
drop if error_cap==1|error_rev==1|error_ik==1

count
save col_data_clean, replace

****Detect firms with inconsistent birth year****
sort plant year
egen mborn=mean(yborn), by (plant)
gen dborn=(yborn-mborn)^2
egen vborn=sum(dborn), by (plant)
sum vborn, d

replace yborn=. if vborn>0

*drop if yborn==.
*3669 observations deleted

*define first year that a plant in sample
egen miny=min(year), by (plant)
egen maxy=max(year), by (plant)

*define cohort

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
*This loop gives a quick outlook on the evolution of each cohort
*/