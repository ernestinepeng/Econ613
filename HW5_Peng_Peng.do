clear all
set more off, perm 

* set wd 
cd "/Users/pengpeng/Desktop/Econ613/HW"
capture log close


* Homework 2: OLS and Discrete Choice =========================================


* Exercise 1 Data Creation*********************************

set obs 10000
set seed 1
generate X1 = runiform(1, 3)
gen X2 = rgamma(3, 2)
gen X3 = rbinomial(10000, 0.3)
gen eps = rnormal(2, 1)
gen Y = 0.5 + 1.2*X1 - 0.9*X2 + 0.1*X3 + eps

egen Y_mean = mean(Y)
gen Y_dum = (Y>Y_mean)


* Exercise 2 OLS *****************************************

corr Y X1
reg Y X1 X2 X3 
eststo

bootstrap, reps(49): reg Y X1 X2 X3
eststo

bootstrap, reps(499): reg Y X1 X2 X3
eststo

esttab using hw2_e2.tex, label title(Homework 2: OLS and Boostrap) mtitle("OLS""Bootstrap 49" "Bootstrap 499")
eststo clear 

* Exercise 3 Numerical Optimization 

mlexp(Y_dum*lnnormal({b1}*X1 + {b2}*X2 + {b3}*X3 + {b0}) + (1-Y_dum)*lnnormal(-({b1}*X1 + {b2}*X2 + {b3}*X3 + {b0})))

esttab using hw2_e3.tex, label title(Homework 2: Probit MLE)
eststo clear 

* Exercise 4 Discrete Choice-*********************************

probit Y_dum X1 X2 X3
eststo

logit Y_dum X1 X2 X3
eststo

reg Y_dum X1 X2 X3
eststo

esttab using hw2_e4.tex, label title(Homework 2: Discrete Choice) mtitle("Probit""Logit""Linear Regression")
eststo clear 

* Exercise 5 Marginal Effects**********************************

probit Y_dum X1 X2 X3
margins, dydx(*)

logit Y_dum X1 X2 X3
margins, dydx(*)

esttab using hw2_e5.tex, label title(Homework 2: Marginal Effect)
eststo clear 

probit Y_dum X1 X2 X3
eststo

logit Y_dum X1 X2 X3
eststo

probit Y_dum X1 X2 X3, vce(bootstrap, reps(49) seed(1))
eststo

logit Y_dum X1 X2 X3, vce(bootstrap, reps(49) seed(1))
eststo

esttab using hw2_e5_part2.tex, label title(Homework 2: Standard Errors) mtitle("Probit_Delta Method""Logit_Delta Method""Probit_Bootstrap""Logit_Bootstrap")
eststo clear 

* Homework 3: Multinomial ===================================================


* Exercise 1 Data Description**********************************
clear
import delimited using product
save "/Users/pengpeng/Desktop/Econ613/HW/product.dta"
import delimited using demos
save "/Users/pengpeng/Desktop/Econ613/HW/demos.dta"
merge 1:m hhid using product
drop _merge
drop v1
rename (ppk_stk pbb_stk pfl_stk phse_stk pgen_stk pimp_stk pss_tub ppk_tub pfl_tub phse_tub) (price1 price2 price3 price4 price5 price6 price7 price8 price9 price10)
save "/Users/pengpeng/Desktop/Econ613/HW/merge.dta"

su
tabulate choice
tabulate choice, summarize(income)
tabulate choice, summarize(fam_size)
tabulate choice, summarize(whtcollar)
tabulate choice, summarize(retired)

* Exercise 2 Conditional Logit*******************************
clear
use product 
rename (ppk_stk pbb_stk pfl_stk phse_stk pgen_stk pimp_stk pss_tub ppk_tub pfl_tub phse_tub) (price1 price2 price3 price4 price5 price6 price7 price8 price9 price10)
gen id = _n 
gen purchase = 0
replace purchase=1 if choice==product

reshape long price, i(id choice) j(product)


asmixlogit purchase price, case(id) casevars(income) alternatives(product)
eststo

* Exercise 3 Multinomial *********************************************
use merge 
mlogit choice income
eststo 

esttab using hw3_e3.tex, label title(Homework 3: Multinomial Model) mtitle("Conditional Logit""Multinomial")
eststo clear 

* Exercise 4 Marginal Effects*******************************************


* marginal effect for multinomial 
mlogit choice income
margins, dydx(income)


*  Exercise 5 Mixed Logit********************************************

* generate unique ids 
use merge 

gen id = _n

* reshape data from wide to long, unique identifiers(id choice) 
reshape long price, i(id choice) j(product)

* generate a binary variable indicating choice
gen purchase = 0
replace purchase=1 if choice==product

* full sample mixed logit
asmixlogit purchase price, case(id) casevars(income) alternatives(product)
eststo

* drop choice=1
keep if choice>1 

* sub sample mixed logit 
asmixlogit purchase price, case(id) casevars(income) alternatives(product)
eststo 

esttab using hw3_e5.tex, label title(Homework 3: Mixed Logit) mtitle("full sample" "selected sample")
eststo clear 

* test IIA

* Homework 4: Panel Data=================================================


* Exercise 1 Data Description 

clear 
import delimited Koop-Tobias
save "/Users/pengpeng/Desktop/Econ613/HW/panel.dta"

* randomly select 5 individuals 
bsample 5, cluster(personid)

* plot logwage with time dimension for each individual
scatter timetrnd logwage, by(personid)


* Exercise 2 Random Effect******************************************
* declare panel structure

xtset personid timetrnd

* random effect model
xtreg logwage educ potexper, re
eststo

* Exercise 3 Fixed Effects 

* between estimator 
xtreg logwage educ potexper, be
eststo

* within estimator 
xtreg logwage educ potexper, fe
eststo

* first time difference
gen logwage_L = L.logwage
gen educ_L = L.educ
gen potexper_L = L.potexper

reg logwage_L educ_L potexper_L, nocons
eststo
esttab using hw4_e3.tex, label title(Homework 3: Random Effects and Fixed Effects) mtitle("Random Effects" "Between Estimator""Within Estimator""First Difference")
eststo clear

* Exercise 4 Understanding fixed effects 

* randomly select 100 individuals 
use panel
bsample 100, cluster(personid)
xtset personid timetrnd
xtreg logwage educ potexper, mle
eststo

* extract individual fixed effects
xtreg logwage educ potexper i.personid

* correct standard error 
xtreg logwage educ potexper i.personid, robust
eststo
esttab using hw4_e4.tex, label title(Homework 4: Panel Data) mtitle ("MLE" "Robust Standard Errors")


