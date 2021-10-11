********************************************************************************
*** Match Colombian CIIU 2,3 and 4 codes
********************************************************************************
*** Main inputs: 
*** Additional inputs: 
*** Output:
*** Author: Nicolas Oviedo
*** Original: 05/07/2021
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
global input_data  "$pathinit/Data/inputs/microdata/survey/Colombia/BaleyBlanco/CIIU_classification"
global temp_file   "$pathinit/Data/Temp"
global figures 	   "$pathinit/Data/figures/colombia"

cap log close
log using "$temp_file/ciiuconverter.log", append

cd "$output_data"

********************************************************************************	
*** Import and cleanse raw data            
********************************************************************************
import excel using "$input_data/CIIU3ACvsCIIU2DANE.xls", clear
drop in 1/2
ren B seccion_ciiu3
ren C division_ciiu3
ren D grupo_ciiu3
ren E clase_ciiu3
ren F descripcion_ciiu3
ren G grandivision_ciiu2
ren H division_ciiu2
ren I agrupacion_ciiu2
ren J grupo_ciiu2
ren K actividad_ciiu2
ren L descripcion_ciiu2
drop in 1/2

replace agrupacion_ciiu2 = "311" if agrupacion_ciiu2 == "311-312*"

foreach var in grandivision_ciiu2 division_ciiu2 agrupacion_ciiu2 grupo_ciiu2 actividad_ciiu2{
	replace `var' = subinstr(`var', "*", "",.)
	destring (`var'), replace
}

replace grandivision_ciiu2 = grandivision_ciiu2[_n-1] if grandivision_ciiu2 ==.
keep if grandivision_ciiu2 == 3
compress

********************************************************************************	
*** Generate sector for CIIU 2 and 3 
********************************************************************************
/* Here we generate a sector indicator, ranging from 1 to 9, on CIIU 2 basis.
 1-Food Products, 2-Textiles, 3-Wood products (excl. furniture), 4-Paper and printing,
 5-Industrial chemicals, 6-Pottery and glass, 7-Iron and steel, 8-Metal products, 9-Miscellaneous
 CIIU 2 features different levels of aggregation of industrial activities. Thus, we generate sector codes
 to be matched at each level of CIIU code aggregation. */

*Sector by activity
gen sector = "."
replace sector = substr(string(actividad_ciiu2), 2, 1)
destring(sector), replace

*Sector by group
gen sector_grupo = .
replace sector_grupo = real(substr(string(grupo_ciiu2), 2, 1)) if grupo_ciiu2 < 4000 & grupo_ciiu2 ~=.
replace sector_grupo = 1 if grupo_ciiu2 < 2000 & grupo_ciiu2 ~= .

*Sector by macro group
gen sector_agrupacion = .
replace sector_agrupacion =  real(substr(string(agrupacion_ciiu2), 2, 1)) if agrupacion_ciiu2 > 200 & agrupacion_ciiu2 < 400
replace sector_agrupacion = 1 if agrupacion_ciiu2 < 200 & agrupacion_ciiu2 ~= .

*Sector by division
gen sector_division = .
replace sector_division = real(substr(string(division_ciiu2), 2, 1)) if division_ciiu2 > 20 & division_ciiu2 < 40

/*
replace sector = sector_agrupacion if sector == .
replace sector = sector_grupo if sector == .
replace sector = sector_division if sector == .
drop sector_*
*/

destring(clase_ciiu3), replace
gen sector_ciiu3 = cond(missing(sector), 0, sector) + cond(missing(sector_agrupacion), 0, sector_agrupacion) + cond(missing(sector_grupo), 0, sector_grupo) +  cond(missing(sector_division), 0, sector_division)
replace sector_ciiu3 = . if sector_ciiu3 == 0
move sector_ciiu3 descripcion_ciiu3

*Fix manually some sector_ciiu3 values
replace sector_ciiu3 = 3 if clase_ciiu3 == 3611
replace sector_ciiu3 = 4 if clase_ciiu3 == 2231 | clase_ciiu3 == 2234
replace sector_ciiu3 = 8 if clase_ciiu3 == 2721 | clase_ciiu3 == 3130

save col_ciiu2, replace

********************************************************************************	
*** Generate sector for CIIU 4         
********************************************************************************
import excel using "$pathinit/Data/inputs/microdata/survey/Colombia/aux_doc/ciiu3vsciiu4.xls", clear
drop in 1/5
drop A J
ren H ciiu4
replace ciiu4 = subinstr(ciiu4, "*", "",.)
ren G ciiu3
destring (ciiu*), replace
drop if ciiu4 == .
drop B-F
compress
ren ciiu3 clase_ciiu3
merge m:m clase_ciiu3 using col_ciiu2, keepusing (sector_ciiu3)
drop if _merge == 2
drop _merge
ren sector_ciiu3 sector_ciiu4
save ciiu4vciiu3, replace
