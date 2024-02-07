/*==============================================================================
TITLE: Tutorial 2 - Solutions

AUTHOR: Alexander Wintzéus - KU Leuven, Department of Economics
DATE: 15/01/2024
STATA VERSION: MP 16.0
==============================================================================*/

*-------------------------------------------------------------------------------
* 0. Preliminaries and loading dataset
*-------------------------------------------------------------------------------

cls // clear output window
set more off // always load full output in output window
set varabbrev off // do not allow variable abbreviations
cd "Y:\Teaching\2023-2024\UHH" // set current working directory

use AJR2001-AER.dta, clear // clear previous data in memory and load dataset

*-------------------------------------------------------------------------------
* Question 1: Conditions for a valid instrument
*-------------------------------------------------------------------------------

pwcorr setmort risk, sig // for other options, see help "pwcorr"

/*
[(a)]:
The correlation coefficient between the logarithm of the mortality rate faced by
European settlers (setmort) and the average protection against expropriation risk
(risk) is -0.52. There thus seems to be strong negative association between the 
disease environment at colonization and current institutions, in line with the
theory proposed by the authors to support their use of setmort as an instrument
for current institutions.

The relevance condition is thus likely to be met. However, in general, how do we
know whether the correlation between the endogenous independent variable and the 
instrument is "strong enough"? As a rule of thumb, a correlation coefficient lower
than |0.3| is weak. There are, however, other ways to test for so-called weak
instruments (and consequently the relevance condition); see below.
*/

twoway (scatter loggdp setmort) (lfit loggdp setmort) 

/*
[(b)]:
Alternatively, "scatter loggdp setmort || lfit loggdp setmort".

This graph CANNOT inform us about the validity of the exclusion restriction. Recall that the exclusion restriction stated that the instrument should only affect the dependent variable through the endogenous independent variable. In this graph, we plotted the reduced-form relationship between setmort and loggdp. As it turns out, there seems to be a strong negative relationship between the instrument (setmort) and dependent variable (loggdp); however, whether this relationship is solely driven by the effect of the instrument on current institutions (risk) is impossible to know from this figure. Arguably, what this figure, together with the correlation calculated above, is able to tell us, is that the instrument is relevant.

[(c)]:
Now, why is the exclusion restriction fundamentally untestable? The short answer: "Exclusion restrictions are identifying restrictions, so they cannot be tested". That is, identification of the parameters of interest relies on the exclusion restriction that we as researchers have imposed, and importantly, involve the unknown error term. 

A naive approach to test the exclusion restriction would be to perform the IV regression and check whether the instrument is uncorrelated with the residual. However, this is impossible, as by construction both will be orthogonal to each other. Another naive approach to test the exclusion restriction would be to check whether the covariance between the instrument and the dependent variable, when conditioning on the endogenous independent variable, is zero. However, again, this approach is not valid. Conditioning on the endogenous independent variable (X) may create a relationship between an omitted variable (W) and the instrument (Z) so that Cov(Z,W|X) is not zero, even though, unconditionally, they are unrelated Cov(Z,W) = 0.

In the case we have strictly more instruments than endogenous regressors, it may be possible to (partly) test for instrument validity (i.e., the exclusion restriction). See Question 6.
*/

*-------------------------------------------------------------------------------
* Question 2: OLS regressions
*-------------------------------------------------------------------------------

global controls1 latitude i.africa i.asia i.other

regress loggdp risk $controls1
estimates store reg_ols

regress loggdp risk $controls1, robust
estimates store reg_ols_robust

/*
[(c)]:
If richer countries may choose or afford better institutions, then we would expect that the OLS estimate of the effect of current institutions on income per capita may be suffering from bias stemming from reverse causality. In particular, we would assume that the true effect is more attenuated (towards zero). Hence, we could think that our IV estimate of alpha would be smaller.

On the other hand, there may be a variety of other factors that are correlated with current institutions and which may affect current income per capita. Up front, it is difficult to know what the overall effect would be on the estimate of alpha if we would be able to include (all) of these omitted factors. It would depend on the correlations with the (endogenous) independent variable and the dependent variable.
However, most possible omitted factors seems to have positive correlations with risk and loggdp, leading us to suspect that the current OLS estimate may be upward biased.

All in all, knowing beforehand how the estimate of alpha would change is difficult. Nevertheless, the problem of reverse causality would most likely inflate the OLS estimate of alpha. Furthermore, knowledge of the possible relevant omitted factors (as presented in the paper) would suggest that the true effect is smaller than the one estimated by OLS. Based on this, we would thus expect the IV estimate to be smaller.
*/

*-------------------------------------------------------------------------------
* Question 3: IV (or 2SLS) regressions
*-------------------------------------------------------------------------------

ivregress 2sls loggdp $controls1 (risk = setmort), first
estimates store reg_iv

ivregress 2sls loggdp $controls1 (risk = setmort), robust first
estimates store reg_iv_robust

/*
[(b):]
From the first stage regressions, we can see whether our instrument (setmort) is a good predictor for the endogenous dependent variable (risk). As we can see from the tables, higher settler mortality at colonization is associated with a higher risk of private property expropriation (recall, lower values of risk mean worse institutions). However, the effect is only marginally significant at the 10% level (in case of robust) standard errors.

From the first-stage regressions, we can see that our instrument may be able to predict settler mortality, but we should be cautious about the instrument being weak. Although we will not go into detail on the problems caused by weak instruments, it is worth noting that they may push the 2SLS estimate to the OLS estimate (which is biased).

Another way to check whether the instrument(s) are weak, is to look at the first-stage F statistic (standard output by Stata with option first). As a rule of thumb, a value of the F statistic lower than 10 hints at a weak instrument. Importantly, however, this rule of thumb the is valid under homoskedasticity. 
For a heteroskedasticity-robust test and appropriate F statistic and cutoff, see Olea and Pluger (2013). A Stata package to implement this test can be installed with the command "ssc install weakivtest".

[(c):]
The IV (or 2SLS) estimate of the effect of institutions on income per capita is substantially larger than the one estimated by OLS. In fact, holding all other variables fixed, a one unit increase in the risk variable (i.e., a decrease in actual expropriation risk) increases the expected income per capita by a factor of approximately 3 (i.e., exp(1.11)).

Given our answer to Question 2(c), this increase in the effect of institutions on income per capita is not expected. However, it can easily be understood in light of (classical) measurement error in the measure of current institutions (risk). We know that such measurement error attenuates the OLS estimate of alpha towards zero. Is it plausible that our measure of institutions is suffering form measurement error? Yes! "In reality the set of institutions that matter for economic performance is very complex, and any single measure is bound to capture only part of the 'true institutions', creating a typical measurement error problem.”

A valid instrumental variable can, however, solve this issue. Hence, we would expect the IV estimate to be larger than the OLS one. All in all, the IV estimate thus suggests that measurement error in the institutions variable (risk) that creates attenuation bias is likely to be more important than reverse causality and omitted variables biases.

[(d):]
In the first tutorial, we included latitude (standardized absolute distance from the equator) as a control variable to mitigate the potential of omitted variable bias. In line with our expectations, we found the estimate to be positive with a p-value between 0.1 and 0.2.

However, the 2SLS estimate is "wrong-signed" with a large p-value. This thus seem to suggest that, when we single out the "exogenous variation" in our measure of current institutions (i.e., the variation explained by settler mortality at colonization), the positive and significant effect of latitude as a determinant of economic performance found in many developmental studies may in fact have been capturing the effect of institutions on income per capita (as both are correlated).
*/

*-------------------------------------------------------------------------------
* Question 4: Robustness exercises
*-------------------------------------------------------------------------------

/*
As highlighted in the paper, there are a number of different possible channels,
other than the institutions channel, through which settler mortality may affect 
current income per capita. For example, colonial origin, legal origin, religion,
... could all be correlated with both settler mortality and economic outcomes.

A particular concern is that the the settler mortality rate may be correlated with the current disease environment. As such, the IV estimate could partly be capturing the general effect of disease on economic performance. We investigate this concern here by controlling for the variable malfal94; the share of population in a given country living in an area where Falciparum Malaria was endemic in 1994. Infant mortality and life expectancy at birth are included as well.
*/

global controls2 malfal94 imr95 leb95

ivregress 2sls loggdp latitude $controls2 (risk = setmort), robust first

/*
[(b):]
The estimate of alpha changes substantially, yet remains significant. At first glance, the estimates seem closer to the ones obtained by OLS than the ones by IV.

It is important to note that the current disease environment is also highly endogenous (as institutions). Poorer countries with worse institutions are the ones that were unable to eradicate malaria and ameliorate the general disease environment. Since malaria prevalence in 1994 may be endogenous, this would imply that controlling for it in the regression does more harm than good: It will lead us to underestimate the effect of institutions on economic performance. 

Note, on the other hand, that there is no direct effect of malaria, infant mortality, or life expectancy on economic performance. Hence, this channel is most likely not too be big of a concern.
*/

*-------------------------------------------------------------------------------
* Question 5: Durbin-Wu-Hausman test
*-------------------------------------------------------------------------------

estimates restore reg_iv // restore initial IV estimates in memory
estat endogenous // test for endogeneity of risk variable

/*
[(a):]
In our specific context, the null hypothesis can loosely be stated as: The variable risk is exogenous. The alternative hypothesis is that it is endogenous.

However, the Durbin-Wu-Hausman test applies more broadly. In fact, it can be used to evaluate the consistency of an estimator compared to an alternative, less efficient estimator which is known to be consistent under both the null and the alternative hypothesis. In the endogenous regressor case, it can be used to compare the OLS estimator, which is consistent and efficient under the null hypothesis but inconsistent under the alternative, to the IV (or 2SLS) estimator, which is consistent both under the null and the alternative (but obviously not efficient under the null). Note that this thus implies that we cannot use estimates obtained with heteroskedasticity-robust standard errors as the OLS estimator loses its efficiency if the errors are indeed not homoskedastic. Consequently, the test does not have a clean asymptotic distribution to base the test statistic on.

The test can also be used to test random effects versus fixed effects models. Hence, Stata also has a built in "hausman" command. It is nevertheless advised to use "estat endogenous" if one wants to test endogeneity of a regressor after the "ivregress" command.

[(b):]
The tests indicates that it is highly unlikely under the null hypothesis to observe
the value for their respective statistics. We thus (strongly) reject the null hypothesis that the variable risk is exogenous in favor of the alternative that it is in fact endogenous.
*/

*-------------------------------------------------------------------------------
* Question 6: Testing overidentifying restrictions
*-------------------------------------------------------------------------------

global instruments setmort euro1900 cons00a

* without continent dummies
ivregress 2sls loggdp latitude (risk = setmort euro1900), first
estat overid

ivregress 2sls loggdp latitude (risk = setmort cons00a), first
estat overid

ivregress 2sls loggdp latitude (risk = $instruments), first
estat overid // additional regression, not part of exercise

* with continent dummies (additional regressions, not part of exercise)
ivregress 2sls loggdp $controls1 (risk = setmort euro1900), first
estat overid

ivregress 2sls loggdp $controls1 (risk = setmort cons00a), first
estat overid

ivregress 2sls loggdp $controls1 (risk = $instruments), first
estat overid

/*
[(b):]
We can learn from this test whether the included instruments are jointly valid (i.e., jointly satisfy the exclusion restriction). The null hypothesis is that all included instruments are jointly valid. The alternative hypothesis is that at least one of the included instruments is invalid. Note that this test (known as the Sargan-Hansen test) can test for instrument validity as long as there are strictly more instruments included in the regression. This follows from the fact that one instrument constitutes an identifying restriction, which, by itself, cannot be tested. See also Question 1(c).

For each of the regressions, the test cannot reject the null hypothesis. Hence, this increases the validity of the authors' approach as the additional instruments where -- at least according to the authors -- more likely to violate the exclusion restriction. 

However, some caution should be taken when testing for overidentifying restrictions. First, these test have generally low power. Second, the test actually test two things simultaneously. That is, it test for instrument exogeneity AND for model misspecification (e.g., whether one of the instruments should in fact be a control in the structural equation). Finally, if all instruments are highly correlated, then even if all are invalid, the test may not reject the null!
*/

/*==============================================================================
									END
==============================================================================*/


