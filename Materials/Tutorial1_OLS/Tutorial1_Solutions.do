/*==============================================================================
TITLE: Tutorial 1 - Solutions

AUTHOR: Alexander Wintzéus - KU Leuven, Department of Economics
DATE: 08/01/2024
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
* Question 1: Scatter plot loggdp and risk
*-------------------------------------------------------------------------------

scatter loggdp risk // for options, see "help scatter"

/*
As can be seen from the scatterplot, the relationship between loggdp and risk is
approximately linear. The linearity assumption is therefore reasonable. One can impose a linear fit by adding "|| lfit loggdp risk" to the previous command.

Interpretation: Countries with LOWER risk of property expropriation tend to have
higher income per capita levels.
*/

*-------------------------------------------------------------------------------
* Question 2: Regression of loggdp on risk without controls
*-------------------------------------------------------------------------------

regress loggdp risk // for options, see "help regress"
estimates store reg1 // store results for later use

/*
[(a):]
Be careful about the interpretation of the coefficient given that the dependent
variable is in logs.

For small values of the estimated coefficient: A one unit increase in the variable "risk" (i.e., a lower expropriation risk) is associated with an expected increase in income per capita of approximately 52 percent!

For general values of the estimated coefficient: A one unit increase in "risk" increases the expected value of income per capita by the exponential of the estimated coefficient. In our case, this corresponds to an expected value that is 1.68 times higher.
*/

predict loggdp_hat, xb // fitted value
generate resid = loggdp - loggdp_hat // OLS residuals

scatter resid risk // residual plot

/*
[(b) and (c):]
The conditional homeskedasticity assumption implies that the variance of the residuals should be similar across values of the independent variable (risk).

From the graph, we can see that the variance is lower for both low and high values of expropriation risk. However, this may simply be a data issue. There are not a lot of observations with low or high values of expropriation risk. 

Alternatively, one could use White's test to check whether homoskedasticity is violated in the sample. In Stata, this test can be implemented using the "estat imtest, white" command. However, given the small number of observations at hand, the test will lack power. On the given sample, the maintained hypothesis of homeskedastic errors cannot be rejected.

Nevertheless, it is generally advised to allow for heteroskedastic errors using the robust option of the regress command. Even if the error terms are effectively homoskedastic, heteroskedasticity-robust errors are valid. Hence the name of the robust command: The estimated standard errors are robust to potential violations of the conditional homoskedasticity assumption.
*/

*-------------------------------------------------------------------------------
* Question 3: Omitted variable bias
*-------------------------------------------------------------------------------

pwcorr risk latitude, star(0.01) // correlation risk and absolute distance from equator

/* 
[(a):]
We see a strong and significant positive correlation between latitude and the risk variable. In other words, countries with LOWER risk of private property expropriation tend to be FURTHER away from the equator. 

On the other hand, the latitude gradient in comparative development is a well-established fact. Although this fact is not well understood, being closer to the equator tends to be associated with higher morbidity, perhaps due to climated-related factors, which could affect growth and income through numberous channels. One could correlate latitude with loggdp to see this pattern appear in the current dataset as well.

There is thus reason to believe that our simple regression may be suffering from omitted variable bias. Our current estimate may partly capture the effect of latitude on income per capita and thus be biased upwards.
*/

regress loggdp risk latitude // regression of income on risk controlling for latitude
estimates store reg2 // store results for later use

/*
[(b):]
Yes. The estimated effect of expropriation risk on income per capita is smaller when controlling for latitude implying that is was previously biased upwards. Note, furthermore, that the effect of latitude on income per capita is also significant at conventional significance levels.
*/

regress loggdp risk latitude i.africa i.asia i.other // regression of income on risk including full set of controls
estimates store reg3 // store results for later use

/*
[(c):]
Including a dummy for each continent would provide a multicollinearity problem as all variables are mutually exclusive (no country can be in two different continents at the same time). Hence, it would always be possible to write any of the dummies as linear combination of the other (i.e., one minus the sum of the others). In this case, OLS does not have a (unique) solution. Including the "america" dummy in the regression promts Stata to automatically drop one of the variables. It also tells which variable it has dropped.

Interpretation: Holding all other variables fixed, a one unit increase in the risk variable (i.e., a decrease in actual expropriation risk) is associated with an expected increase in income per capita of approximately 40%. Or, more precisely, it would increase the expected income per capita with a factor of exp(0.4).
*/


*-------------------------------------------------------------------------------
* Question 4: Compare coefficient of determination (R²) across regressions
*-------------------------------------------------------------------------------

/*
Having stored the previous regressions using the "estimates store name" command, we can now simply retrieve their outputs using the "estimates replay names" command -- i.e., without having to perform the regressions again. Note that one can simply use "_all" or "*" instead of listing all names of the stored regressions.

All outputs are shown again in the output window.
*/

estimates replay reg1 reg2 reg3
// estimates replay _all
// estimates replay *

/*
[(a):]
The coefficient of determination tells us what percent of the variation in our dependent variable can be explained by the variation in the independent variables. Hence, it is often used as a measure of LINEAR fit.

We can see from the first regression that variation in expropriation risk across countries can explain more than 50% of the variation in (log) income per capita. This is quite substantial. Including controls increases the value of the coefficient of determination and leads us to believe that the model with the full set of controls has a pretty good fit.

[(b):]
However, it is important to note that the inclusion of more right-hand side variables (i.e., regressors) mechanically increases the R². Hence, one could simply include any variable as a regressor, regardless of whether it is actually predictive of the dependent variable, to artificially inflate the R². A similar, yet slightly different measure of fit that deals with this aspect of the coefficient of determination is the adjusted-R². Finally, remark again that the R² only tells us something about the LINEAR fit of the estimated regression equation.
*/

*-------------------------------------------------------------------------------
* Question 5: Endogeneity issues
*-------------------------------------------------------------------------------

/*
We can most likely still not interpret the estimated effect of institutions on income per capita as causal for at least two reasons. First, there may still be a lot of other different reasons why countries differ both in their institutions and in their income levels which we cannot control for. Hence, we might still suffer from an omitted variables bias problem. Second, it is quite likely that richer economies can choose or afford better institutions. Hence, we might also be suffering from a problem of reverse causality.

To deal with these issues, the authors employ an instrumental variables (IV) approach. We will explore this approach and the accompanying methods in Tutorial 2.
*/

/*==============================================================================
									END
==============================================================================*/