/* Ames Housing Data Analysis Uisng SAS */
/* Reading Dataset*/
libname mylib "/home/vitastasharma110/";
data mylib.AmesHousing (drop = PID);
set mylib.team1;
run;
/* 31 Variables and 800 rows of data */

proc contents data = mylib.AmesHousing varnum;
title "Contents of the given file";
run;

/* Checking for missing values in the dataset using Proc means and 
Proc univariate for Histograms */
proc means data=mylib.AmesHousing n nmiss;
title "Variables with Missing values";
run;

ods graphics;
proc univariate data=mylib.AmesHousing plot;
   title "Histogram for Variable Distribution Analysis";
run;
ods graphics off;
/********************************************************************************/
/* 1 */
/* Creating MACRO */
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
Overall_Qual;


/********************************************************************************/
/* 2 */
/*Using PROC UNIVARIATE to generate plots and descriptive statistics for continuous variables  */
ods graphics on;
ods select histogram;
proc univariate data=mylib.AmesHousing noprint;
   var &interval;
   histogram &interval / normal kernel;
   inset n mean std / position=ne;
   title "Univariate Analysis for Interval [Continuous] Variables";
run;
title;


/*Using PROC FREQ to generate plots and tables for categorical variables */
Title "Analysis for categorical variables" ;
Proc FREQ Data = mylib.AmesHousing;
tables &categorical/ CHISQ CMH plots=all;
run;
Title;
ods graphics off;

/********************************************************************************/
/* 3*/
/* One Sample TTEST*/
ods graphics on;
Proc Ttest data=mylib.AmesHousing h0=135000 alpha=0.05
        plots(only shownull)= interval;
   var SalePrice;
   Title 'Testing whether the Mean SalePrice= $135000';
Run;
Title;
ods graphics off;
/*The mean value is $138,790 with t-value associated is 2.98 and p-value is 0.0030. We reject the null hypothesis at the 0.05 level */
/*Therefore, we can say that the mean sale price of homes is statistically different from $135,000 */

/********************************************************************************/
/* 4*/
Data mylib.test2;
Set mylib.AmesHousing; 
select (Masonry_Veneer);
	  when ('Y') output mylib.test2;
	  when ('N') output mylib.test2;
	  otherwise;
   end;
Run;
/*First verify the assumptions of t-tests. There is an assumption of normality of the distribution of each group. 
This assumption can be verified with a quick check of the Summary panel and Q-Q plot */

/* Two-Sample T-TEST*/
PROC TTEST DATA= mylib.test2;
Title "Two sample T-Test";
Class Masonry_Veneer;
Var SalePrice;
RUN;
Title;

/*From the Equality of Variances table: The F test for equal variances has a p-value of 0.0725. Because this value is greater than the alpha level of 0.05, do not reject the null hypothesis of equal variances.
Based on the F test for equal variances, look in the t-Tests table at the equal variance (Pooled) t-test, reject the null hypothesis that the group means are equal. The mean difference between no masonry veneer and masonry veneer is -$17,703.0. Because the p-value is less than 0.05 (Pr>|t<.0001),
we conclude that there is a statistically significant difference in the sale price between houses with the two types of veneer.
The 95% confidence interval for the mean difference (-23162.8, -12243.2) does not include 0. This also implies statistical significance at the 0.05 alpha level*/

/********************************************************************************/
/* 5 */

/*Relationship between continuous predictors and SalePrice using Scatterplot*/
PROC sgscatter  DATA=mylib.AmesHousing;
   PLOT SalePrice*(&interval) / reg ;
   title "Interval Variables & Sales Price";
   RUN;
   
/*From the output graphs we can conclude that there seems to be some association between each of the predictor variables and SalePrice */


/*Creating Macro to run the procedure for each categorical variable automatically*/
%Macro catplot(cat);
%let nwords=%sysfunc(countw(&cat));
%DO i = 1 %TO &nwords;

/*Comparative box plots to show relationships between categorical predictors and SalePrice*/
 proc sgplot data=mylib.AmesHousing;
   vbox SalePrice/ category= %scan(&cat, &i) 
                    connect=mean;
   title "Sale Price Differences across %scan(&cat, &i)";
run;
%END;
%MEND catplot; 

%catplot(&categorical)

/* Houses with central air sell on average at higher prices than houses without central air.Hence, there is a nonzero association between Central_Air and SalePrice */
/* Houses with Concrete/Slab Foundation sell on average at higher prices than houses with Cinder Block/Brick/tile/Stone Foundation.Therefore, there is a nonzero association between Foundation and SalePrice */
/* Houses with Attached Garage_Type_2 sell on average at higher prices than houses with Detached Garage_Type_2.Therefore, there is a nonzero association between Garage_Type_2 and SalePrice */
/* Houses with Masonry_Veener sell on average at higher prices than houses without Masonry_Veener.Therefore, there is a nonzero association between Masonry_Veener and SalePrice  and so on for Houses with FullBathroom and Fireplaces */

/********************************************************************************/
/* 6 */
/* Created Output diagnostic plots */
/* Performed Levene’s test of homogeneity of variances */


ods graphics on;
proc glm data=mylib.AmesHousing plots(only)=diagnostics;
   class Heating_QC ;
   model SalePrice = Heating_QC;
   means Heating_QC / hovtest=levene;
   title "ANOVA with Heating_QC as Predictor Variable";
run;
quit;
ods graphics off;

/* The F statistic and corresponding p value are reported in the Analysis of Variance table the p value (<.0001) is less than 0.05, hence we reject the null hypothesis of no difference between the means. */
/* The SalePrice Mean is the mean of all of the data values for the variable SalePrice, without regard for Heating_QC.
The R2 value is often interpreted as the “proportion of variance accounted for by the model.” 
Hence, we can conclude that in this model, Heating_QC explains about 13% of the variability of SalePrice */
/* The residual plot in the upper left panel plots the the residuals plotted against the fitted values from the ANOVA model. To check the normality assumption, look at the residual histogram at the bottom left. The histogram is approximately symmetric.  */
/* Output from the Levene test: The null hypothesis is that the variances are equal over all Heating_QC groups. The p-value of 0.0004 is smaller than your alpha level of 0.05 and therefore, we reject the hypothesis of homogeneity of variances (equal variances across Heating_QC types). The assumption for ANOVA is not met*/

/********************************************************************************/

/* 7 */
/*Used the LSMEANS statement in PROC GLM to produce comparison information about 
the mean sale prices of the different heating system quality ratings. */

proc glm data=mylib.AmesHousing  plots(only)=intplot;
   class Heating_QC;
   model SalePrice= heating_QC;
   lsmeans Heating_QC / pdiff=all  adjust=tukey;
run;
quit;

/*From the Tukey_Kramer table we can see the means for each group. The second part of the output shows p-values 
from pairwise comparisons of all possible combinations of means. The diagonal values are blank because it does not 
make any sense to compare a mean to itself */

/********************************************************************************/
/* 8 */
/*Relationship between continuous predictors and SalePrice*/

proc corr data=mylib.AmesHousing nomiss
          plots=scatter(nvar=all ellipse=none);
   var &interval;
   with SalePrice;
   title "Correlations and Scatter Plots";
run;
/*The correlation coefficient between the sales price and Log_Price is the highest, it is natural because Log_Price is the Log of Sales price.
Now looking at other variables from the Pearson Correlation Coefficients table we have Year_Built, Basement_Area, Gr_Liv_Area. From the scatter plots 
notice that there are several houses with basements sized 0 square feet. These are houses without basements. This mixture of data can affect the 
correlation coefficient. This needs to be taken into account when build a model with basement area as a predictor variable */

/********************************************************************************/
/* 9 */
/* Before performing a regression analysis, it is a good practice to examine the correlations among the potential predictor variables . 
When we do not specify a WITH statement, we get a matrix of correlations of all VAR variables. That matrix can be very big and 
difficult to interpret. To limit the displayed output to only the strongest correlations, we use the BEST= option */
proc corr data=mylib.AmesHousing  nomiss
          best=5
          out=mylib.pearson;
   title "Correlations of Predictors";
run;  
%let big=0.7;
data mylib.bigcorr;
   set mylib.pearson;
   array vars{*} &interval;
   do i=1 to dim(vars);
      if abs(vars{i})<&big then vars{i}=.;
   end;
   if _type_="CORR";
   drop i _type_;
run;

proc print data=mylib.bigcorr;
   format &interval 5.2;
run;
/*From the Pearson Correlation Coefficients table it is clear that there is a high correlation between Sales Price and Overall_Qual, Bonus 
and Overall_Qual2 */
/* Linear Regression */
ods graphics on;
Proc reg data=mylib.AmesHousing;
   model SalePrice= Overall_Qual ;
   title "Regression of SalePrice on Overall_Qual";
run;
ods graphics off;
Title;
/*The Number of Observations Read and the Number of Observations Used are the same, 
which indicates that no missing values were detected for either SalePrice or Overall_Qual.The F value tests whether the slope of the predictor 
variable is equal to 0. The p-value is small (less than 0.05), hence we reject the null hypothesis. Thus, we can 
conclude that the simple linear regression model fits the data better than the baseline model. In other words, Overall_Qual explains a significant amount of variability in SalePrice.
The third part of the output provides summary measures of fit for the model. With R-square= 0.5 we can say that the regression line explains 5% of the total variation in the response values*/
/*Regression equation : SalePrice=$9160.04514 +$23720*(Overall_Qual) */
/* The shaded area in the Fit plot represents the confidence intervals around the means. A 95% confidence interval for the mean says that you are 95% confident that your interval contains 
the population mean of Y for a particular X. */

/********************************************************************************/
/* 10 */

ods graphics off;
proc means data=mylib.AmesHousing
           mean var std nway;
   class Season_Sold Heating_QC;
   var SalePrice;
   format Season_Sold Season.;
   title 'Selected Descriptive Statistics';
run;
/* The mean sale price is always lowest for houses with fair heating systems */

proc sgplot data=mylib.AmesHousing;
   vline Season_Sold / group=Heating_QC 
                    stat=mean 
                    response=SalePrice 
                    markers;
run;
/* Mean sale price is lowest when Season = 1 i.e. Cold */

data mylib.AmesHousing;
set mylib.AmesHousing;
if upcase(Heating_QC) = 'PO' then Heating_QC = 'Fa';
run;

proc glm data=mylib.AmesHousing plots(only)=intplot;
   class Season_Sold Heating_QC   ;
   model SalePrice=Season_Sold|Heating_QC;
   lsmeans Season_Sold*Heating_QC / slice=Heating_QC;
run;
quit;
/* The null hypothesis here is that all means are equal for all explanatory variables. The p-value is < 0.001 indicates that not all means are equal for all explanatory variables */
/*The R-Square value of 0.145305 shows that about 14% of the variability in SalePrice is explained by the two categorical predictors.*/

/********************************************************************************/

/*11*/

ods graphics on;
proc glm data=mylib.AmesHousing plots(only)=intplot;
   class Heating_QC Season_Sold  ;
   model SalePrice=Heating_QC Season_Sold Heating_QC*Season_Sold;
   lsmeans Heating_QC*Season_Sold / slice=Heating_QC;
store dt;  /*storing the result in a new dataset*/
title "Model with Heating Quality and Season Sold as Interacting "
         "Predictors";
run;
quit;
/*The SLICE= option in the LSMEANS statement enables us to look at the effect of Season_Sold at all levels of Heating_QC */
/*Adjusting p values using proc PLM*/

proc plm restore=dt plots=all;
   slice Heating_QC*Season_Sold / sliceby=Heating_QC  adjust=tukey;
   effectplot interaction(sliceby= Heating_QC ) / clm;
run;
/*With the help of PROC PLM, a source item store can be produced. The item stores and PROC PLM’s use helps us to separate common tasks after 
postprocessing, such as predicting new set of values with the model that already exists or testing for the treatment differences. A numerically 
expensive model fitting technique can be applied once to produce a source item store. We can then call the PLM procedure multiple times and analyze 
the results of the fitted model without doing model fitting again. */
/*The slice for excellent heating systems shows that there is no significant effect of season. Hence we will analyze Good heating systems */
/*For Good systems, the only statistically significant pairwise comparison is between Season 1 & 2. */

/********************************************************************************/
/* 12 */
/*Regression Modelling with with Lot_Area and Basement_Area as predictor variables*/

proc reg data=mylib.AmesHousing;
   model SalePrice= Lot_Area Basement_Area;
   title 'Regression Modelling with Lot_Area and Basement_Area';
run;
/*The model is statistically significant at the 0.05 alpha level and the R-Square value of 0.3766 . The P-value for both Lot_Area and Basement_Area is < 0.05*/

/********************************************************************************/

/* 13 */
/* Stepwise Regression -A variable selection method where various combinations of variables are tested together. */
/* Creating a macro to invoke PROC GLMSELECT five times on the SalePrice variable regressing on the interval 
variables. For each, request STEPWISE selection with the SELECTION= option and including DETAILS=STEPS to obtain 
step information and the selection summary table */

%macro modsel(mod);
proc glmselect data=mylib.AmesHousing plots=all;
   model salePrice = &interval / SELECTION= stepwise SELECT=&mod details=steps;   
run;
quit;
%mend modsel;
Title 'Select= SL with salePrice';
%modsel(SL)
Title 'Select= AIC with salePrice';
%modsel(AIC)
Title 'Select= BIC with salePrice';
%modsel(BIC)
Title 'Select= AICC with salePrice';
%modsel(AICC)
Title 'Select= SBC with salePrice';
%modsel(SBC)
 /* During each step of the selection process, there is a table and graph of the entry candidates for that individual step. In step one, there are several entry candidates whose significance level is displayed 
as <.0001. In the Coefficient Progression graph, PROC GLMSELECT displays a panel two plots showing how the standardized coefficients and the criterion are used to choose the final model
evolved as the selection progressed. Here we can monitor the change in the standardized coefficients as each effect is added to or deleted from the model*/
/* The Fit Criteria graph displays the progression of the adjusted R-square, AIC, AICC, SBC. The star denotes the best model of the eight that were tested, in this problem. The Average Square Error Plot shows the progression of the average square error (ASE) evaluated 
on the training data. As more effects are added to the model, the ASE decreases */

/********************************************************************************/

/* 14 */

%macro modsel(mod);
Proc reg data=mylib.AmesHousing plots=(&mod);
   model SalePrice= &interval/ SELECTION= &mod; 
   title "Regression of SalePrice ";
run;
quit;
%mend modsel; 
 
Title 'Regression model with selection=rsquare';
%modsel(rsquare);
Title 'Regression model with selection=adjrsq';
%modsel(adjrsq);
Title 'Regression model with selection=cp';
%modsel(cp)

/* The R-square plot compares all models based on their R-square values. As noted earlier, adding variables to a model always increases R-square, and therefore the 
full model is always best. Therefore, you can only use the R-square value to compare models of equal numbers of 
parameters. While with the Adjusted- R square plot you can compare models of different sizes */
/* The lower line is plotted to help identify which models satisfy Hocking's criterion Cp2ppfull+1 for parameter estimation */
 