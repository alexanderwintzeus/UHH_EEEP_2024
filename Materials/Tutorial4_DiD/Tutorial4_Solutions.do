/*==============================================================================
TITLE: Tutorial 4 - Solutions

AUTHOR: Alexander Wintzéus - KU Leuven, Department of Economics
DATE: 31/01/2024
STATA VERSION: MP 16.0
==============================================================================*/

*-------------------------------------------------------------------------------
* 0. Preliminaries and loading dataset
*-------------------------------------------------------------------------------

cls // clear output window
set more off // always load full output in output window
set varabbrev off // do not allow variable abbreviations
pause on // allow pauses
cd "Y:\Teaching\2023-2024\UHH" // set current working directory

use Wolfers2006-AER.dta, clear // clear previous data in memory and load dataset

*-------------------------------------------------------------------------------
* Question 1: Evolution divorce rate across years and types of states
*-------------------------------------------------------------------------------

preserve

collapse (mean) divrate [aweight=stpop], by(year)
twoway connect divrate year, ytitle("Divorce rate") xline(1968 1988, lcolor(red))
 
restore 

/*
[(a):]
We can see from the graph that between 1968 and 1988 (the period indicated by the red vertical lines) divorce rates rose dramatically. In particular, before 1968, divorce rates were rather stable between 0.22% and 0.25. Afterwards, however, the divorce rate increased considerably to almost 5.2 in a thousand in 1980. Note that, of the 29 states that shifted from a mutual consent regime to unilateral divorce, 28 already transitioned before 1980. From 1980 to 1988 the divorce rate decreased to around 0.48%. From then onwards, it declined further. In the short run, it thus seemed that the adoption of unilateral divorce laws indeed was accompanied by increasing divorce rates. However, in the longer run, the relationship seems to "normalize".
*/

preserve

collapse (mean) divrate [aweight=stpop], by(year reform)
twoway (connect divrate year if reform == 0, msize(small) mcolor(blue)) (connect divrate year if reform == 1, msize(small) mcolor(purple)), ytitle("Divorce rate") xline(1968 1988, lcolor(red)) legend(label (1 "Non-unilateral states") label (2 "Unilateral states"))

restore

/*
[(b):]
We can learn two things from this graph: First, states that never adopted unilateral divorce laws have lower divorce rates, on average. Second, the evolution in the divorce rate between states that never adopted unilateral divorce laws and states that did is rather similar. 

The first fact seems to hint that states that chose to change their divorce laws were charactized by higher divorce rates. If this is mainly driven by high divorce rates in early adopting states, previous research (before Friedberg, 1998) may have been suffering from an endogeneity issue (selection bias).
*/

encode st, generate(state)
bysort state: egen yearsuni = total(unilateral)
generate earlyuni = (yearsuni > 25)

preserve

collapse (mean) divrate [aweight=stpop], by(year reform earlyuni)
twoway (connect divrate year if reform == 0, msize(small) mcolor(blue)) (connect divrate year if reform == 1 & earlyuni == 0, msize(small) mcolor(purple)) (connect divrate year if reform == 1 & earlyuni == 1, msize(small) mcolor(forest_green)), ytitle("Divorce rate") xline(1968 1988, lcolor(red)) xline(1974, lcolor(green)) legend(label (1 "Non-unilateral states") label (2 "Late unilateral states") label (3 "Early unilateral states"))

restore

/*
[(d):]
Of the 31 states that adopted unilateral divorce laws over the sample period, 29 states did so between 1968 and 1988. Of those 29 states, 22 states transitioned before 1974. As we can see from the graph, these early adopting states had higher initial divorce rates compared to the later adopting states. The initial divorce rate of the latter states was still higher than that of the never adopting states. This seems to suggest that the endogeneity concerns may be valid.

However, note that the results for the evolution of the divorce rate for the late adopting states is rather sensitive to the cutoff year for being an early adopter. Nevertheless, the result that the initial divorce rates of early adopters is generally higher than those of late adopters and never adopters is rather robust to changes in the cutoff. 
*/

*-------------------------------------------------------------------------------
* Question 2: Difference-in-Differences - Friedberg (1998)
*-------------------------------------------------------------------------------

generate window = (year > 1967 & year < 1989)
regress divrate unilateral i.state i.year if window == 1 [aweight=stpop], vce(cluster state) 

/*
[(a):]
The estimate of the parameter beta should be interpreted as the average effect on the divorce rate that can be attributed to the change from a mutual consent divorce regime to a unilateral divorce regime.

In the first specification, the estimate of beta is -0.026 with a standard error 0.16. The results thus seem to suggest that the adoption of unilateral divorce laws did not increase divorce rates (if anything, the sign of estimate suggests that the divorce rate should have decreased; however, we really cannot pretend as if there is any effect based on these results). 

This result is consistent with the early research on the topic, which argued that when one controls for existing differences in state divorce propensities (captured by state fixed effects), unilateral divorce laws did not affect divorce rates.
*/

regress divrate unilateral i.state i.year i.state#c.time if window == 1 [aweight=stpop], vce(cluster state) 

/*
[(b):]
Including state-specific time trends changes the results considerably. The estimate of beta is now 0.385 with a p-value of 0.017. This suggests that, on average, adoption of unilateral divorce laws did increase divorce rates.

Including state-specific time trends may be important if the factors that influence divorce may vary over time within a given state. As noted by Friedberg "Including state-specific time trends allows unobserved state divorce propensities to trend linearly and reveals that unilateral divorce raised divorce rates significantly and strongly". Of course, these omitted factors could only bias the results if they are correlated with divorce laws; the results suggest they certainly do.
*/

*-------------------------------------------------------------------------------
* Question 3: Event-study DiD - Wolfers (2006)
*-------------------------------------------------------------------------------

bysort state: generate rel_divlaw = year - (divlaw - 1)

forvalues i = -9(1)16 {
	local k = cond(`i'<0,"minus_" + regexr("`i'","-",""),"`i'")
	generate rel_time_`k' = 0
	bysort state: replace rel_time_`k' = 1 if (rel_divlaw == `i')
	label variable rel_time_`k' "`i'"
}

bysort state: replace rel_time_minus_9 = 1 if (rel_divlaw <= -9)
bysort state: replace rel_time_16 = 1 if (rel_divlaw >= 16)

order unilateral year divlaw rel_divlaw rel_time* // check whether everything turned out as we wanted it to be

/*
[(a:)]
In a first step, we create a variable "rel_divlaw". For a given state, this variable denotes the relative time until treatment onset. In particular, it provides the number of periods relative to the period just before treatment onset (given our definitions). 

In a second step, we use the "forvalues" command to loop over the periods in our event window; i.e., from nine periods before treatment onset up until 16 periods after. For each period in the event window, we create a variable "rel_time_`k'" that equals one if for a given state the considered year corresponds to that relative time to treatment onset.

Finally, in a last step we impose endpoint binning. That is, for all years that are before K or after L, we group observations. For example, in all periods where a state has been treated for at least L periods, we put rel_time_L equal to one, rather than just putting this variable equal to one if that state was treated for exactly L periods. Note that, not imposing this endpoint binning would implicitely assume that treatment disappears after L periods, which may be unreasonable. With endpoint binning, we assume it remains constant from L onwards (and similarly for periods before K).
*/

drop rel_time_0 // drop period before treatment onset

regress divrate rel_time* i.state i.year i.state#c.time [w=stpop], vce(cluster state)
estimates store eventdd

/*
[(b:)]
The estimates show a pretty strong spike in the divorce rate immediately following the adoption of unilateral divorce laws that persists for up to 8 years. Afterwards, the effect starts to decline rapidly and even turns negative, although the standard error suggest that these longer-term dynamic effects are not statistically distinguisable from zero. 

Note that if one were to also estimate the event-study without state-specific linear time trends, the results would remain roughly the same. This is in stark contrast to the results obtained by Friedberg: Only after including state-specific time trends, did she find an effect of UDL on divorce rates. 

In her initial specification, the fact that she does not find an effect may partly be explained by a positive effect on the divorce rate in the first decade ensuing the divorce law reforms, but a declining and even negative effect in the decade afterwards, so that overall, relative to the preexisting trends, there was no effect. Including state-specific time trends does allow her to find a postive effect on the divorce rate. As her treatment dummy is supposed to capture the overall effect, any dynamic fluctuations in the effect may not be well captured by this variable. Consequently, the state-specific linear trends may not only be capturing different preexisting trends across states, but also differences in the evolution of the divorce rate between reform and control states after UDL adoption. As such, the instantaneous effect of the reform may be overestimated as part of the later decline is captured by these state-specific trends.
*/

testparm  rel_time_minus*

/*
[(c:)]
The Wald or F test for joint significance of the placebo parameters seems to suggest that the placebo parameters are jointly not different from zero. Hence, in this example, we can be confident that the no-anticipation and parallel-trends assumptions are likely to hold.
*/

coefplot eventdd, keep(rel_time*) vertical title("Effect of UDL adoption on divorce rate", color(black)) xtitle("Years relative to adoption") xscale(titlegap(2)) yline(0, lcolor(black)) ciopts(recast(rcap)) msymbol(D) graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ifcolor(white) ilcolor(white) ilwidth(vvvthin)) xline(10, lcolor(red)) xlabel(10 "0", add) relocate(rel_time_1 = 11 rel_time_2 = 12 rel_time_3 = 13 rel_time_4 = 14 rel_time_5 = 15 rel_time_6 = 16 rel_time_7 = 17 rel_time_8 = 18 rel_time_9 = 19 rel_time_10 = 20 rel_time_11 = 21 rel_time_12 = 22 rel_time_13 = 23 rel_time_14 = 24 rel_time_15 = 25 rel_time_16 = 26)

*-------------------------------------------------------------------------------
* Appendix: twowayfeweights
*-------------------------------------------------------------------------------

/*
To check whether the TWFE (ES) estimator may be estimaing a nonconvex combination of individual treatment effects (i.e., with negative weights; see de Chaisemartin and D'Haultfoeuille, 2023), you can make use of the "twowayfeweights" package. To install this package, you will first have to install the gtools package. Normally, you should be able to install these packages together in one line of code:

"ssc install twowayfeweights gtools"
*/

twowayfeweights divrate state year unilateral, type(feTR)

/*
It turns out that of the 806 individual ATTs (estimated across all treated state-year cells), 52 get weighted negatively by the TWFE estimator. The sum of these negative weights equals approx. -0.078. This is rather small. As such, the bias in the TWFE estimator induced by heterogenous treatment effects over time, may be limited in this particular application of a staggered adoption design. Nevertheless, it may still be useful to refer to the robust estimators of Callaway and Sant'anna (2021) and Sun and Abraham (2021). Note, however, that these estimators are generally less efficient (i.e., have greater variance).
*/

/*==============================================================================
									END
==============================================================================*/
