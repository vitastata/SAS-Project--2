/* Reading Dataset*/
libname mylib "/home/vitastasharma110/";

data mylib.AmesHousing (drop = PID);
set mylib.team1;
run;

/* MACRO */
%let interval = 
Basement_Area 
Deck_Porch_Area
Garage_Area 
Gr_Liv_Area 
Log_Price 
Age_Sold  
Lot_Area 
Year_Built;
%let categorical = Season_Sold 
Total_Bathroom 
Yr_Sold 
Central_Air 
Foundation_2 
Garage_Type_2
Heating_QC
House_Style
House_Style2
Lot_Shape_2
Masonry_Veneer
Bedroom_AbvGr
Fireplaces 
Full_Bathroom 
Half_Bathroom 
Mo_Sold
Overall_Cond 
Overall_Cond2 
Overall_Qual 
Bonus;

/* 30 Variables and 800 rows of data */

proc contents data = mylib.AmesHousing varnum;
title "Contents of the given file";
run;

/* Checking for missing values in the dataset using Proc means and 
Proc univariate for Histograms */
proc means data=mylib.AmesHousing n nmiss;
title "Variables with Missing values";
run;

ods graphics on;
proc univariate data=mylib.AmesHousing plot;
   title "Histogram for Variable Distribution Analysis";
run;
ods graphics off;

/* Problem 15 */
/* One-way Frequency table for Bonus, Fireplaces, and Lot_Shape_2 */
/* Two-way Frequency tables for the variables Bonus by Fireplaces, and Bonus by Lot_Shape_2 */
Proc format;
value BonEl 
1="Bonus Eligible"
0="Not Bonus Eligible"
;
run;
Proc Freq data= mylib.AmesHousing;
tables Bonus Fireplaces Lot_Shape_2 Fireplaces*Bonus Lot_Shape_2*Bonus /
          plots(only)=freqplot(scale=percent);
format Bonus BonEl. ;
run;
/* From the frrequency table for Bonuses it is clear that 85.50% of the people are not 
eligible for Bonus and 63.75% of the Houses do not have Fireplaces, while 68.71% of the 
houses have regular Lot_shape*/

/* Creating Histogram*/
/*Basement_Area: Square footage of included basement*/
ods graphics on;
proc univariate data=mylib.AmesHousing;
   title "Histogram for Basement_Area,for each level of Bonus";
   var Basement_Area;
   class Bonus;
   histogram Basement_Area;
   inset mean std median min max / format=5.2 position=nw;
   format Bonus BonEl.;
run;
ods graphics off;
/*The output tells us that the average ("Mean") for Bonus= 0 is 843.53655 of the 684 subjects ("N") 
with a standard deviation of 298.434044. The median ("50% Median") is 864.0. 
The smallest Basement area in square feet in the data set is 0 (observation #762), while the 
largest is 1495 (observation #434).*/
/*The output tells us that the average ("Mean") for Bonus= 1 is 1218.48276 of the 116 subjects ("N") 
with a standard deviation of 298.434044. The median ("50% Median") is 1295.0. 
The smallest Basement area in square feet in the data set is 384 (observation #14), while the 
largest is 1500 (observation #245).*/
/*The distribution of houses that are not bonus eligible appears to be more variable as evident by the larger standard deviation. 
The mean of not bonus eligible houses is over 400 square feet smaller than houses that are bonus eligible.  */

/* Two-way frequency table Bonus by Fireplaces, and Bonus by Lot_Shape_2*/
/*Fireplaces: # fireplaces within house (0, 1, 2, 3) 
Lot_Shape_2: Orientation of lot shape (Irregular, Regular)
Bonus: Bonus eligibility status (1=Bonus Eligible, 0=Not Bonus Eligible)*/
Proc Freq data= mylib.AmesHousing;
tables (Fireplaces Lot_Shape_2)*Bonus / chisq expected cellchi2 nocol nopercent
           relrisk;
format Bonus BonEl. ;
run;
/* Part b: From the Table of Bonus by Fireplaces we can see that maximum 92.75% of the houses 
have 0 number of fireplaces that are not eligible for the Bonus while from the second table- 
Table of Bonus by Lot_Shape_2, 91.99% of the houses have regular Lot shape and were not eligible 
for the Bonus.Part a: Table of Bonus by Lot_Shape_2 has Frequency Missing = 1 */

/*Because the p value for the chi-square statistic is <.0001, which is below 0.05, you reject the null hypothesis at the 0.05 level and 
conclude that there is evidence of an association between Lot_Shape_2 and Bonus. Cramer’s V of -0.2736 indicates that the association 
detected with the chi square test is relatively weak */

/*Odds Ratio and Relative Risk table shows another measure of strength of association. The top row (Irregular, 
in this case) is the numerator of the ratio while the bottom row (Regular) is the denominator. The interpretation is stated in relation to the left column of the contingency table (Not Bonus Eligible). 
The value of 0.2154 says that an irregular lot has about 21.5% of the odds of not being bonus eligible, compared with a regular lot. This is equivalent to saying that a regular lot has about 21.5% of the odds 
of being bonus eligible, compared with an irregular lot*/

/* The 95% odds ratio confidence interval goes from 0.1426 to 0.3253. That interval does not include 1. 
This confirms the statistically significant (at alpha=0.05) result of the Pearson chi-square test of association. 
A confidence interval that included the value 1 (equality of odds) would be a non-significant result.*/

/* Relative Risk estimates for each column are interpreted as probability ratios, rather than odds ratios. 
You get a choice of assessing probabilities of the left column (Column1) or the right column (Column2). i.e. Relative Risk (Column 1)=0.7740= 71.20/91.99= (Irregular row Pct/Regular row pct) for "Not Bonus Eligible" */

/* There also seems to be an association between Fireplaces and Bonus (Chi-Square(df=3)=64.9399, p <0.0001). Because the p value for the chi-square statistic is <.0001, which is below 0.05, 
we reject the null hypothesis at the 0.05 level and conclude that there is evidence of an association. Cramer’s V for that association is 0.2849 indicates that the association detected with the chi square test is relatively weak. */

/* Mantel Haenszel chi square test */

ods graphics off;
proc freq data=mylib.AmesHousing;
   tables Fireplaces*Bonus / chisq measures cl;
   format Bonus BonEl.;
   title 'Verfying Ordinal Association between FIREPLACES and BONUS';
run;
ods graphics on;

/* The Spearman Correlation = 0.2772 indicates that there is a moderate, positive ordinal relationship between Fireplaces and Bonus (that is, as Fireplaces levels increase, Bonus tends to increase).
The ASE is the asymptotic standard error of 0.0360, which is an appropriate measure of the standard error for larger samples. Because the 95% confidence interval lies between 0.2066 and 
0.3477 for the Spearman correlation statistic does not contain 0, the relationship is significant at the 0.05 significance level. */


/* Binary logistic regression model with Outcome variable = Bonus and Variable = Basement_Area. Alpha =0.10 */

PROC LOGISTIC DATA=mylib.AmesHousing DESCENDING
   plots(only)=(effect oddsratio);
   model Bonus(event='1')=Basement_Area / clodds=pl Alpha=.10 ;     
    TITLE "Logistic Model";
RUN;
QUIT;
/* Because the EVENT=option in this example, the model is based on the probability of being bonus eligible (Bonus=1).  */
/* Model Convergence Status table specifies that the convergence criterion was met. The Model Fit Statistics table provides the 3 measures AIC, SC, -2Log L are goodness of fit measures that you can use to compare one model to another. 
These statistics measure relative fit among models, but they do not measure absolute fit of any single model. Smaller values for all of these measures indicate better fit. However, -2 Log L can be reduced 
by simply adding more regression parameters to the model. Therefore, it is not used to compare the fit of models that use different numbers of parameters except for comparisons of nested models via likelihood ratio tests.
AIC adjusts for the number of predictor variables, and SCs adjust for the number of predictor variables and the number of observations. SC uses a bigger penalty for extra variables. */

/* The Testing Global Null Hypothesis: BETA=0 table provides three statistics to test the null hypothesis that all regression coefficients of the model are 0. The Score and Wald tests are also used to test whether all the regression coefficients are 0. The likelihood ratio test is the most reliable, 
especially for small sample sizes.  */
/* The Analysis of Maximum Likelihood Estimates table lists the estimated model parameters, their standard errors, Wald Chi-Square values, and p-values.
The parameter estimates are the estimated coefficients of the fitted logistic regression model. The logistic regression equation is
LOG(p) = -7.7969 + 0.00573 (Basement_Area) */


