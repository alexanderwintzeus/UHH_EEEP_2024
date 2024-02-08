/*==============================================================================
TITLE: Tutorial 3 - Solutions

AUTHOR: Alexander Wintzéus - KU Leuven, Department of Economics
DATE: 29/01/2024
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

use Lee2008-JoE.dta, clear // clear previous data in memory and load dataset

*-------------------------------------------------------------------------------
* Question 1: Scatter plots demsharenext and difdemshare
*-------------------------------------------------------------------------------

twoway (scatter demsharenext difdemshare, msize(small))

/*
[(a):]
No, this graph is not informative about the possible discontinuity at Z=0. With a Regression Discontinuity Design, we are particularly interested in the relationship
between the running variable (difdemshare) and the outcome (demsharenext) around
the cuttoff. Plotting the entire joint distribution of points obsecures a lot of what might be going on at the cutoff.
*/

generate window = (difdemshare >= -0.25 & difdemshare <= 0.25)

twoway (scatter demsharenext difdemshare, msize(small)) if window == 1, xline(0, lcolor(red))

/*
[(b):]
Restricting the range of the running variable (difdemshare; Democrat vote share margin in election year t) already provides us with a clearer picture of the relationship between running variable and outcome. From the graph, we can see that there indeed seems to be some discontinuity in the outcome (demsharenext) at Z=0.

Although it may not be super clear from this graph, there also seems to be a direct positive relationship between the running variable and the outcome. This is to be expected. Having higher vote shares in the current election (which will be reflected in the vote share margin) could attract more campaign donors for a subsequent election, and consequently, could boost the vote shares in that subsequent election.

Finally, note that, even though this graph can already tell us some meaningful aspects of the relationship between vote share margin in year t vs. vote shares in year t+1, the signal to noise ratio is still rather low. Hence, it may be a good idea to create a binned scatter plot to enhance the clarity of the graph (and the relationship it is trying to depict) even further.
*/

egen cut_0005 = cut(difdemshare), at(-1(0.005)1) // variable containing bin lower bounds (0.5 percent bins)

/*
[(c):]
The "egen" command together with the "cut" function and "at" option will create a new variable "cut_0005" that assigns to each observation the value of the lower bound associated to the interval in which that observation lies with respect to the variable "difdemshare". For example, if observation i has difdemshare equal to 0.27, the value of "cut_0005" will equal 0.25 for that observation. 

Note that observations with difdemshare equal to 1 will not get assigned a value and hence will be missing. This is because we specified the upperbound of the range to be 1. As such, all observations exactly equal to 1 will not be considered. However, this is not important, as we will only consider observations within a tighter window around Z=0.
*/

preserve // save current state of variables

collapse (mean) window demsharenext difdemshare, by(cut_0005) // collapse data on the bins and compute means within bins of the reported variables
twoway (scatter demsharenext difdemshare, msize(small)) if window == 1, xline(0, lcolor(red))  // plot the relationship between the binned demsharenext and difdemshare variables

restore // restore state of variables

/*
[(d):]
Based on this graph, we are more inclined to think that there is a discontinuity in the outcome (demsharenext) at the cutoff. However, the choice of bins was rather arbitrary. Nevertheless, the choice of bins is not trivial as we will see in the follow-up question. 
*/

* Smaller bins: Less bias, more noise

egen cut_0001 = cut(difdemshare), at(-1(0.001)1) // variable containing bin lower bounds (0.1 percent bins)

preserve // save current state of variables

collapse (mean) window demsharenext difdemshare, by(cut_0001) // collapse data on the bins and compute means within bins of the reported variables
twoway (scatter demsharenext difdemshare, msize(small)) if window == 1, xline(0, lcolor(red)) // plot the relationship between the binned demsharenext and difdemshare variables

restore // restore state of variables

* Bigger bins: More bias, less noise

egen cut_0050 = cut(difdemshare), at(-1(0.050)1) // variable containing bin lower bounds (5 percent bins)

preserve // save current state of variables

collapse (mean) window demsharenext difdemshare, by(cut_0050) // collapse data on the bins and compute means within bins of the reported variables
twoway (scatter demsharenext difdemshare, msize(small)) if window == 1, xline(0, lcolor(red)) // plot the relationship between the binned demsharenext and difdemshare variables

restore

/*
[(e):]
The choice of bins -- width of bins or number of bins -- is not trivial.

Decreasing the width of each bin, and hence, increasing the number of bins, decreases the bias in the estimate of the (conditional) mean function. However, this may come at the cost of more noise, especially if the number of observations is limited. That is, within each bin there are less observations on which to base the average, so the standard deviation around the mean within a given bin is greater.

On the other hand, increasing the width of each bin, and hence, decreasing the number of bins, will increase the bias in the estimate of the (conditional) mean function. However, as bins are wider, the noise or standard deviation around this mean will be lower.
 
In other words, the choice of bin carries an inherent bias versus noise trade-off. There are, however, optimal ways to choose the number of bins. We will (implicitly) touch upon these later.

NOTE: The choice of bins in this discussion refers to the NUMBER of bins. Implicitly, we maintained the assumption that bins are equally-spaced. It is possible, however, to choose a different TYPE of bin. With equally-spaced bins, the number of observations within a given bin could vary; however, the width was fixed. If there are not a lot of observations around the discontinuity, this could be problematic. Another option would be quantile binning. In this case, the number of observations is the same across all bins; however, the width can vary. Nevertheless, even with quantile binning, there is still a choice to be made regarding the number of bins (i.e, do we use quartiles, deciles, percentiles, ...).
*/

*-------------------------------------------------------------------------------
* Question 2: Estimating the treatment effect - Parametric techniques
*-------------------------------------------------------------------------------

generate demwin = (difdemshare >= 0)

regress demsharenext i.demwin##(c.difdemshare##c.difdemshare), robust

/*
[(a):]
The treatment effect is given by the parameter "beta1", the coefficient on D. This can easily be seen as follows. Under the assumptions of the linear model, the conditional expectation at the cutoff Z=0 is given by: 

	E[Y|D,Z=0] = E[Y|D=1,Z=0] - E[Y|D=0,Z=0] 
			   = (beta0 + beta1) - (beta0) 
			   = beta1

Performing the regression on the full sample provides us with an estimate of beta1. The value of this parameter is 0.052 and corresponds to the treatment effect if Z=0. Note, however, that we have made some implicit assumptions. Importantly, we have assumed linearity (although the polynomial terms and interactions allowed for some flexibility). As such, if the true underlying conditinal mean function is not linear (in parameters), our estimate will be biased (due to specification error).

Fitting the conditional mean function on the full set of observations arguably makes our lives more difficult, as we are using data points far away from the cutoff, and are thus relying more on extrapolation and functional form assumptions. It may therefore be better to estimate the treatment effect using only observations close to the cutoff. Of course, reducing the window around the cutoff for estimation may create additional noise as the number of observations decreases.		   
*/

generate bandwidth = (difdemshare > -0.1 & difdemshare < 0.1)

regress demsharenext i.demwin##(c.difdemshare##c.difdemshare) if bandwidth == 1, robust

/*
[(b):]
The results on the restricted sample suggest that the treatment effect is actually larger at 0.057.

Looking at the standard errors of the other estimates seems to suggest that our proposed parametric model may be overly specified. For example, an F-test for joint significance of the estimates on the polynomial terms implies that we cannot reject them to simultaneously be equal to zero (see test command).

Furthermore, performing the regression without polynomial terms provides us with an estimate of the treatment effect equal to 0.061. Clearly, we can also see that the interaction term is highly insignificant.

In other words, including the treatment dummy and running variable seems to be a rather good approximation, keeping in mind the caveats of imposing a functional form assumption and extrapolation. This can also be seen by comparing the R² across these specifications, which remain virtually unchanged. The estimate of the treatment effect in this simpler parametric model remains stable at 0.061.
*/

*-------------------------------------------------------------------------------
* Question 3: Estimating the treatment effect - Non-parametric techniques 
*-------------------------------------------------------------------------------

lpoly demsharenext difdemshare if demwin == 0, nograph gen(x0 y0) kernel(triangle) bwidth(0.1) degree(2)

lpoly demsharenext difdemshare if demwin == 1, nograph gen(x1 y1) kernel(triangle) bwidth(0.1) degree(2)

twoway (scatter y1 x1, color(blue) msize(small)) (scatter y0 x0, color(blue) msize(small)), xline(0, lcolor(red)) legend(off) xtitle(Democratic vote share margin t) ytitle(Democratic vote share t+1)

generate x0_window = (x0 >= -0.25)
generate x1_window = (x1 <= 0.25)

twoway (scatter y1 x1 if x1_window == 1, color(blue) msize(small)) (scatter y0 x0 if x0_window == 1, color(blue) msize(small)), xline(0, lcolor(red)) legend(off) xtitle(Democratic vote share margin t) ytitle(Democratic vote share t+1)

/*
[(a):]
Note that it is possible to make the graph more clear by only showing a more narrow window around the cutoff. To this end, I have created two dummy variables that I use as qualifiers in the twoway graph. Note that the window for which we plot the results does not have any effect on the estimation; i.e., it does not interfere with the chosen bandwidth.

[(b):]
It does not matter that we are performing lpoly on the full set of observations, as the method is inherently local. That is, by setting the bandwidth equal to 0.1, we are only considering values of the running variable that are in a +/- 0.1 interval from the chosen grind points (these are automatically chosen and equally spaced) for estimation. Hence, our estimate at the cutoff (see below), will only be based on those observations within a narrow bandwidth of 0.1. The method achieves this through the Kernel weighting function, which simply weights observations outside the bandwidth with 0. Note that the triangular Kernel weights observations that fall within the considered interval more the closer they are to the grid point that we are considering.
*/

generate cutoff = 0 in 1

lpoly demsharenext difdemshare if demwin == 0, nograph at(cutoff) gen(te_left) kernel(triangle) bwidth(0.1) degree(2)

lpoly demsharenext difdemshare if demwin == 1, nograph at(cutoff) gen(te_right) kernel(triangle) bwidth(0.1) degree(2)

generate cate = te_right - te_left

list te_right te_left cate in 1/1

/*
[(c):]
The estimated (conditional) average treatment effect is somewhat larger than under the parametric estimations at 0.064. You can check that if we would drop the second degree polynomial terms (i.e., using degree(1)), the treatment effect would lie more in line with the earlier estimates (at 0.059).

If anything, this suggests that the treatment effect may still be sensitive to the local approximation that is used. Furthermore, changing the bandwidth or the choice of kernel may also change the size of the estimated treatment effect. You can check this by performing the estimation again for different values of the bandwidth and for different kernel weighting functions.
*/

*-------------------------------------------------------------------------------
* Question 4: Estimating the treatment effect - rdrobust, rdplot, and rddensity
*-------------------------------------------------------------------------------

rdrobust demsharenext difdemshare, all c(0) p(2) // polynomial of degree 2
global h2_l = e(h_l) // optimal bandwidth left of cutoff
global h2_r = e(h_r) // optimal bandwidth right of cutoff

rdrobust demsharenext difdemshare, all c(0) p(1) // polynomial of degree 1
global h1_l = e(h_l) // optimal bandwidth left of cutoff
global h1_r = e(h_r) // optimal bandwidth right of cutoff

/*
[(a):]
In the first line of code, we implement rdrobust with similar options as we did with lpoly. By default, rdrobust uses a triangular kernel weighting function. We impose that rdrobust should use a second-order local polynomial approximation. 

The output of rdrobust shows some useful things:

- It shows the number of observations in the sample at each side of the cutoff.
- It shows the effective number of observations (i.e, within the bandwidth) at each side of the cutoff.
- The degree of polynomial used in the local approximation on both sides of the cutoff.
- The degree of polynomial used to estimate the bias at each grid point (see below).
- The size of the bandwidth. Note that the output also presents the method used to determine the bandwidth. By default, rdrobust chooses the bandwidth that minimizes the mean squared error (i.e., the squared bias in the estimator + variance of the estimator). In other words, it chooses, by default the optimal bandwidth in the mean squared error sense.
- The size of the bandwidth to estimate the bias at each grid point. This will typically be larger as more observations are required.

rdrobust, when combined with the all option, provides three estimates for the treatment effect at the cutoff. 
(1) The "conventional" estimate is simply the estimate that one would have obtained by using a local polynomial of the chosen degree and for the chosen kernel and with the bandwidth equal to the optimal one. However, as shown by the developers of rdrobust in their companion paper, even if one would choose the optimal bandwidth, the bias in the treatment effect does not vanish in the limit as the number of observations increases. Therefore, for inference, they propose a biased-corrected estimator and robust confidence intervals which account for the additional noise coming from the estimation of the bias. As such, rdrobust reports two additional estimates.
(2) The "bias-corrected" estimate with the conventional confidence intervals. That is, not taking into account that estimating the bias carries additional noise.
(3) The "robust" estimate, which corresponds to the bias corrected estimate, but with appropriate confidence intervals (will typically be larger).

The second line of code then repeats the exercise, but imposing a linear local approximation.

The convential estimates, in both cases, are slightly higher than those optained with lpoly. However, the bias-corrected or robust estimates are fairly similar.
*/

rdplot demsharenext difdemshare, c(0) h($h2_l $h2_r) p(2) kernel(triangular) // full set of observations

rdplot demsharenext difdemshare if (difdemshare >= -$h2_l & difdemshare <= $h2_r), c(0) h($h2_l $h2_r) p(2) kernel(triangular) // restrict set of observations to bandwidth

/*
[(b):]
One remark is in order. A downside of the rdplot command is that it cannot automatically obtain the optimal bandwidt from "rdbwselect". Hence, one should manually supply (optimal bandwidths). Note that it is possible to customize the layout of the graphs using options as with any other Stata graph.
*/

/*==============================================================================
									END
==============================================================================*/