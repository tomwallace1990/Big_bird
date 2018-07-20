*For income bands - https://data.ncvo.org.uk/a/almanac14/how-many-voluntary-organisations-are-active-in-the-uk-3/
*Micro <10k - small 10k-100k - medium 100k-1m - large 1m-10m - major >10m - super major >100m

global path1 "***"

use $path1/CharityCaracteristics.dta, clear

set seed 564
*set seed_kiss32 564

***
***

tab account_type

tab account_year

tab financial_year

tab account_year financial_year

*If drop all previous then account and financial line up perfectly
tab account_type financial_year, col

keep if account_type=="current"

*Keep most current full year
keep if financial_year=="2012-13"

tab financial_year

*One duplicate
duplicates list ccnum

*Records are diferent - remove both cases of the duplicate
drop if charname=="***"

*All collected in the same phase
tab phase

sum itotal, detail
sum itotal if multiple==1, detail 
sum itotal if multiple==1000, detail


{
tostring ito, generate(strito)

gen thou = substr(strito,-3,3)
 
count if thou=="000"

tab financial mult if thou=="000"
}
*

sort itotal, stable

capture drop pid
gen pid=_n
*twoway (bar etotalFULL pid)

/*Clip 0 and 99% outlayers 
keep if atotalFULL>0
keep if atotalFULL<190000000

sum atotalFULL, detail
list pid if atotalFULL== 323593
list pid if atotalFULL== 1280308
list pid if atotalFULL== 5116120

sort atotalFULL, stable
capture drop pid
gen pid=_n
twoway (bar atotalFULL pid, xline(1994 3987 5980))
graph export $path1\graphs\1.tif , width(1500)  height(1200) replace

sort atotalFULL, stable
*/

***
/*{
sort atotal, stable
capture drop pid
gen pid=_n
capture drop logatotal
gen logatotal=log(atotal)
twoway (bar logatotal pid, lcolor(gs15)) ///
(bar logatotal pid if multiple==1000, lcolor(red) barwidth(1))
graph save $path1\graphs\g1.gph, replace

sort atotalFULL, stable
capture drop pid
gen pid=_n
capture drop logatotalFULL
gen logatotalFULL=log(atotalFULL)
twoway (bar logatotalFULL pid, lcolor(gs15)) ///
(bar logatotalFULL pid if multiple==1000, lcolor(red) barwidth(1))
graph save $path1\graphs\g2.gph, replace

graph combine $path1\graphs\g1.gph $path1\graphs\g2.gph, cols(1) holes(3)
graph export $path1\graphs\1000graph.tif , width(1500)  height(1200) replace
}
*/

*drop if multiple==1000

sum itotal, detail

*Bands
capture drop bands
gen bands=.
recode bands .=1 if itotal<10000
recode bands .=2 if itotal>=10000 & itotal<100000
recode bands .=3 if itotal>=100000 & itotal<1000000
recode bands .=4 if itotal>=1000000 & itotal<10000000
recode bands .=5 if itotal>=10000000



keep ccnum charname itotal bands

*Sort before RNG is applied or the way the data is loaded in is random and is not replicable
sort bands, stable

*RNG
*capture drop rng
bys bands: generate rng = runiform()
*bys bands: generate rng = runiform_kiss32()

*Sort
sort bands rng, stable

*Kull schools & unis
list charname if strpos(charname, "School")
count if strpos(charname, "School")
drop if strpos(charname, "School")

list charname if strpos(charname, "University")
count if strpos(charname, "University")
drop if strpos(charname, "University")

list charname if strpos(charname, "College")
count if strpos(charname, "College")
drop if strpos(charname, "College")

list charname if strpos(charname, "Church")
count if strpos(charname, "Church")
drop if strpos(charname, "Church")

*Didint drop but would next time (did it manually this time): playgroup, ministries

sort bands rng, stable

sav "$path1\zReanalysis/activedataset_twitter.dta", replace

use $path1\zReanalysis/activedataset_twitter.dta, clear

capture drop twitter
gen twitter=.

tostring twitter, replace

sav "$path1\zReanalysis/activedataset_twitter.dta", replace





