global path1 "***"
global path2 "***\graphs"
global path99 "***/Temp"
*global path1 "C:\Users\tw18\Dropbox\Stats\1Thesis\publishing\UK_third_sector_on_twitter"

*use $path1/activedataset_twitter.dta, clear

*Merging
import excel using $path1\zReanalysis/twitternamesResampleFINAL.xlsx , firstrow clear
sav "$path1\zReanalysis\twitternames.dta" , replace

*
use $path1\zReanalysis\twitternames.dta, clear

tab twitter bands

*160 total
count if twitter~="."

*40 each band
forval val=2/5 {
count if twitter~="." & bands==`val'
}
*

*Valid twitter names by band
forval val=2/5 {
quietly count if bands==`val'
scalar tot=r(N)
quietly count if twitter~="." & bands==`val'
scalar valid=r(N)
di tot
di (valid/tot)*100
}
*27%
*45%
*65%
*83%

capture drop twittercount
gen twittercount=1
recode twittercount 1=0 if twitter=="."

tab twittercount bands, col V gamma chi2

*Valid twitter names total
quietly count
scalar tot=r(N)
quietly count if twitter~="."
scalar valid=r(N)
di (valid/tot)*100
*46%

*drop the invlaid for collection
drop if twitter=="."
tab twitter bands

*Sav
sav "$path1\zReanalysis\twitternamesCLEAN.dta" , replace

*Merging
use $path1\zReanalysis\twitternamesCLEAN.dta, clear

merge 1:1 ccnum using $path1/zReanalysis/activedataset_twitter.dta

sort bands rng, stable

keep if _merge==3
drop _merge

drop twittercount

gen twitlower=lower(twitter)
drop twitter
rename twitlower twitter

sav "$path1\zReanalysis\FINALdataset.dta" , replace

****************************************************
**********************ANALYSIS**********************
****************************************************

***********************Data**************************
use $path1\zReanalysis\FINALdataset.dta, clear

import excel using $path1/zReanalysis\Network_data/freinds_7.10.17FORSTATA.xlsx, ///
 firstrow sheet("Vertices") clear
 
 rename Vertex twitter
 merge 1:1 twitter using $path1\zReanalysis\FINALdataset.dta
 
 keep twitter Connected Degree Group Followed Followers Tweets JoinedTwitterDateUTC Daysince itotal InDegree OutDegree BetweennessCentrality ClosenessCentrality EigenvectorCentrality
 
 rename Daysince Dayssince
 rename twitter Vertex
 
 sav "$path1/zReanalysis\Network_data/freinds_7.10.17FORSTATA.dta", replace
 
 
******************Twitter usage metrics***************
 use $path1/zReanalysis\Network_data/freinds_7.10.17FORSTATA.dta, clear

*Tables from above now outlayers dealt with
sort Vertex

*Tweets per day
capture drop tweetsperday
gen tweetsperday=Tweets/Dayssince
label variable tweetsperday "Tweets per day"

recode Group 2=1 3=2 4=3 5=4

label define Group 1 "Small (10k-99k)" 2 "Medium (100k-999k)" 3 "Large (1M-9.9M)" 4 "Major (10M+)"
label values Group Group
label variable Group "Size group"
label variable Dayssince "Days since joined twitter"
numlabel _all, add

label variable Followed "Following"

table Group, con(median Followed median Followers median Tweets median Dayssince median tweetsperday) format(%3.2f) row
*Large are sometimes like medium (followed) simtimes like major (dayssince)

*use metrics collpase graph
{
preserve 

collapse (median) Followed Followers Tweets Dayssince, by(Group)

graph twoway (line Followed Group, yaxis(1) lcolor(black) lpattern(1) lwidth(medthick)) ///
	(line Followers Group, yaxis(1) lcolor(black) lpattern(_) lwidth(medthick)) ///
	(line Tweets Group, yaxis(1) lcolor(black) lpattern(-) lwidth(medthick)) ///
	(line Dayssince Group, yaxis(2) lcolor(black) lpattern(dot) lwidth(medthick)), ///
	title("Twitter use metrics") ///
	xtitle("Size group" , size(small)) ///
	xlabel(1 "Small" 2 "Medium" 3 "Large" 4 "Major", labsize(small)) ///
	ylabel(0(2000)10000 , axis(1) labsize(small)) ///
	ylabel(1500(500)3000 , axis(2) labsize(small)) ///
	ytitle("Following, Followers, and Tweets" , axis(1) size(small)) ///
	ytitle("Days on Twitter" , axis(2)  size(small)) ///
	legend(label(1 "Following") label(2 "Followers") label (3 "Tweets") label (4 "Days on Twitter")  order(1 2 3 4) cols(2) ) ///
	scheme(s1mono)
graph export $path2\TwitteMetricsGraph.tif , width(1400)  height(1100) replace
	
restore
}
*

*use metrics without days on
{
preserve 

collapse (median) Followed Followers Tweets, by(Group)

graph twoway (line Followed Group, yaxis(1) lcolor(black) lpattern(1) lwidth(medthick)) ///
	(line Followers Group, yaxis(1) lcolor(black) lpattern(_) lwidth(medthick)) ///
	(line Tweets Group, yaxis(1) lcolor(black) lpattern(-) lwidth(medthick)), ///
	title("Twitter use metrics") ///
	xtitle("Size group" , size(small)) ///
	xlabel(1 "Small" 2 "Medium" 3 "Large" 4 "Major", labsize(small)) ///
	ylabel(0(2000)10000 , labsize(small)) ///
	ytitle("Following, Followers, and Tweets" , size(small)) ///
	legend(label(1 "Following") label(2 "Followers") label (3 "Tweets") order(1 2 3) cols(2) ) ///
	scheme(s1mono)
graph export $path2\TwitteMetricsGraphNodayson.tif , width(1400)  height(1100) replace
	
restore
}
*

	*MAD
	foreach val in Followed Followers Tweets Dayssince tweetsperday{
	capture drop mad`val'
	capture drop mad`val'1
	bys Group: egen mad`val' = mad(`val')
	tab mad`val' Group
	egen mad`val'1 = mad(`val')
	di mad`val'1
	}
	*


*Graphs
lgraph Followers Group, statistic(median)  graphregion(color(white)) ///
ytitle("Median number of followers") xtitle("Size Group") xlabel(1 "1. Small" 2 "2. Medium" 3 "3. Large" 4 "4. Major")  bw
graph export $path2\followerslgraph.tif , width(1400)  height(1100) replace

histogram Followed, freq by(Group, graphregion(color(white))) scheme(s2mono)
graph export $path2\followedhisto.png , width(1400)  height(1100) replace

histogram Followers, freq by(Group, graphregion(color(white))) bin(20) scheme(s2mono)
graph export $path2\followerhisto.png , width(1400)  height(1100) replace

histogram Tweets, fcolor(ebblue) lcolor(ebblue*.3) freq by(Group,graphregion(color(white)))
graph export $path2\tweetshisto.png , width(1400)  height(1100) replace

histogram Dayssince, fcolor(ebblue) lcolor(ebblue*.3) freq by(Group, graphregion(color(white)))
graph save $path99\dayssince.gph, replace
graph export $path2\dayssince.png , width(1400)  height(1100) replace

histogram tweetsperday, fcolor(ebblue) lcolor(ebblue*.3) freq by(Group, graphregion(color(white)))
graph save $path99\tweetsperday.gph, replace 

grc1leg $path99\dayssince.gph $path99\tweetsperday.gph , ycommon graphregion(color(white))
graph export $path2\dayssinceperday.png , width(1600)  height(1100) replace

*are assosiated and with impressive r2
*qreg Tweets Followers
/*
bootstrap, reps(10000): qreg Followed ib3.Group
est store followed

bootstrap, reps(10000): qreg Followers ib3.Group
est store followers

bootstrap, reps(10000): qreg Tweets ib3.Group
est store tweets

bootstrap, reps(10000): qreg Dayssince ib3.Group
est store dayssince

bootstrap, reps(10000): qreg tweetsperday ib3.Group
est store tweetsperday

est table followed followers tweets dayssince tweetsperday, stats(N) b(%9.4g) star
*Small reliably less and major more follower
*On tweets dayssine and tweets per day it is as expected with all sig
*/

bootstrap, reps(10000): ologit Group Followed Followers Tweets Dayssince
*only age signifcant but lots of collinearity, factor

*Income model
bootstrap, reps(10000): qreg itotal Followed Followers Tweets Dayssince
*All insig - cpllinear

capture drop logico
gen logico=ln(itotal)

bootstrap, reps(10000): qreg logico Followed Followers Tweets Dayssince

*Factor analysis 
factor Followed Followers Tweets Dayssince, blanks(0.4)

screeplot

rotate, clear
rotate, promax blanks(0.4)
rotate, clear
*There is really just one factor

*is >.7 which is middling appropreiatness
estat kmo

capture drop fact1 
predict fact1

qreg itotal fact1

corr itotal fact1

bootstrap, reps(10000): reg fact1 ib2.Group
qv ib2.Group
di invttail(160,0.025)

bootstrap, reps(10000): reg fact1 itotal

bootstrap, reps(10000): reg fact1 logico

*This is fine as these are overall metrics and not about interdependece - but very close to breaking regression assumptions - see ERGM analysis

******************Centrality***************

 use $path1/zReanalysis\Network_data/freinds_7.10.17FORSTATA.dta, clear
 
 rename Degree degree
 
 recode Group 2=1 3=2 4=3 5=4

capture label drop group
label define Group 1 "Small (10k-99k)" 2 "Medium (100k-999k)" 3 "Large (1M-9.9M)" 4 "Major (10M+)"
label values Group Group
label variable Group "Size group"
numlabel _all, add

*Should tally to connnected 
tab degree Connected

tab Group Connected, gamma chi2 row V

 *Median table
table Group, con(median degree median InDegree median OutDegree) format(%5.0f) row 
*Small have more in than medium but the least out, lowest other metrics (on edges of network)
*Medium do better out than large but worse in and worse between - same close and eigen
*Large very balanced in and out, greater between than med/small but same close and eigen
*Major have far more in than out (more follow them than they follow) and are the highest across the board
*give these reuslts with the matrix table from below

	*MAD
	foreach val in degree InDegree OutDegree {
	capture drop mad`val'
	capture drop mad`val'1
	bys Group: egen mad`val' = mad(`val')
	tab mad`val' Group
	egen mad`val'1 = mad(`val')
	di mad`val'1
	}

table Group, con(median BetweennessCentrality median ClosenessCentrality ///
 median EigenvectorCentrality) format(%5.4f) row 
	
	foreach val in BetweennessCentrality ClosenessCentrality EigenvectorCentrality {
	capture drop mad`val'
	capture drop mad`val'1
	bys Group: egen mad`val' = mad(`val')
	tab mad`val' Group
	egen mad`val'1 = mad(`val')
	di mad`val'1
	}

*A lot less group 1 and 2 becasue they arn't in the network - for usage metrics above they all had a record
histogram InDegree, fcolor(ebblue) lcolor(ebblue*.3) xlabel(0(10)25) freq ///
 by(Group, graphregion(color(white))) discrete
 graph save $path99\histoin.gph, replace 
 
histogram OutDegree, fcolor(ebblue) lcolor(ebblue*.3) xlabel(0(10)25) freq ///
 by(Group,  graphregion(color(white))) discrete
 graph save $path99\histoout.gph, replace 
 
grc1leg $path99\histoin.gph $path99\histoout.gph , ycommon xcommon graphregion(color(white))
graph export $path2\histoInandOut.png , width(1600)  height(1100) replace
 
histogram BetweennessCentrality, fcolor(ebblue) lcolor(ebblue*.3) freq  ///
 by(Group, graphregion(color(white))) 
 graph export $path2\histoBetween.png , width(1600)  height(1100) replace
 
histogram ClosenessCentrality, fcolor(ebblue) lcolor(ebblue*.3) freq ///
 by(Group, graphregion(color(white))) 
 graph export $path2\histoClose.png , width(1600)  height(1100) replace
 
histogram EigenvectorCentrality, fcolor(ebblue) lcolor(ebblue*.3) freq  ///
 by(Group, graphregion(color(white))) 
 graph export $path2\histoEigen.png , width(1600)  height(1100) replace
 
*Looks like they are assosiated to groups, but cant use actual assosiation messures becasue the ///
*	cases are known to be interdepedent and these are actual measures of interdependence

*Sociogram
*	There are a total of 330 links amung the 103 orgaisations in the network. 3.2 links per account.
*	Links are both in and out.

*Most of the core is large and major, but there are some rogue small and med
*centrality in network doesn't sem that connected to how often they tweet (size of disk)

*There arn't really any clusters apart from a proto-cluster formed by *** which is followed by ///
* 6 org which would otherwise not be in the network (mosly museums and culture orgs)

*Group metrics
*small have no internal edges (no small org connects to another - they are connected through larger)
*internal density grows with group - particularly with major who are quite tightly intregrated ///
*	so even though less major are in the network than large (in terms of vertices) - they are better integreated in the ///
*	 core and amunst themselbes

*group send/recive table in doc is from "group edges" tab - shows the number of out links between ///
* given pairs of groups. Shows that 3 and 4 are simialr in out but 4 has far more in. ///
* 5 is most active in both but recivies more in. 2 sends slighlty more out.
*The in/out totals show most gr0ups are proactive- sending out more than they recive, apart from major

*R results

*desity is 0.0314





 *interesting cases?, triad census, e-i index, ergm
