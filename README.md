# Colombia-microdata
Do-files to clean and compile Colombia microdata (1981-2016). Shared work with Julio Andrés Blanco and Isaac Baley.

This 8-pack of do files features code that produces a microdata panel of Colombian industrial plants, from 1981 to 2016.

*step1_colombia.do: merges Roberts and Tybout data for 1981-1991 and constructs key variables.

*step2_colombia.do: cleans Roberts and Tybout data

*step3_colombia.do: appends, cleans, and constructs key measures for 1992-1995 data

*step4_colombia.do: appends, cleans, and constructs key measures for 1996-2016 data

*colombia_master.do: generates Colombia master panel, merging all vantages, converting monetary variables to real terms and keeping essential variables

*plots_colombia_rt: generates main plots for 1981-1991 data

*plots_for_colombia: plots main variables from the full panel

*colomiba_ciiu: matches Colombian CIIU rev. 2, 3 and 4 and generates a consistent one digit sector code
