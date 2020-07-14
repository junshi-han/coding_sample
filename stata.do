cd "C:\Users\star\Desktop\QJE"
use sample_75_02.dta,clear

* A replication for the main figures and tables in "Cash-on-hand and competing models of intertemporal behavior: New evidence from the labor market." (David Card et al., 2007)

* Question 1: merge the datasets and select observations

merge 1:1 file penr using work_history.dta
drop _merge
sort penr file

* drop unselected observations, according to the original paper (mentioned before Table 1 and in Appendix A):

keep if endy>=1981 & endy<=2001
keep if duration>=365 
keep if ustart<ne_start & ustart>end
tab industry

* No retirement information is given in the dataset
* Observations from schools, hospitals, and other public sector service industries are already dropped

drop if iconstruction==1
drop if duration>=5*365
drop if age<20 | age>49
drop if recall==1
drop if volquit==1
drop if dempl5<365 | dempl5>=5*365

di _N

* 650,922 observations -- the same as mentioned in paper.

gen duration_centered = duration-3*365
sum duration_centered
egen duration_month_centered = cut(duration_centered), at(-744(31)744)
replace duration_month_centered=duration_month_centered/31
gen duration_month=duration_month_centered+36


********************************


* Question 3 -- replicate the RD figures (Fig. 2, 3a, 3b, 4, 5, 6, 8a, 8b, 10a, 10b)

* Fig 2: Frequency of Layoffs by Job Tenure

bysort duration_month: egen total_layoff = total(i)

* generate a temp file for Fig 2:

preserve
duplicates drop duration_month, force
keep duration_month total_layoff
save "figure2.dta", replace
twoway (scatter total_layoff duration_month) (line total_layoff duration_month, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Number of Layoffs") legend(off)
gr save figure2.gph, replace
gr export figure2.png, replace
restore

* Figure 3a: Number of Jobs Held by Job Tenure

bysort duration_month: egen mean_jobs = mean(last_breaks)

* generate a temp file for figure 3a

preserve
keep mean_jobs duration_month
duplicates drop duration_month, force 
twoway (scatter mean_jobs duration_month) (lfit mean_jobs duration_month if duration_month<35.5, lp(solid)) (lfit mean_jobs duration_month if duration_month>35.5, lp(solid)) if duration_month!=12 & duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Mean Number of Jobs") legend(off)
gr save figure3a.gph, replace
gr export figure3a.png, replace
restore

* Figure 3b: Wage by Tenure
* According to Table 1, the annual wage should be based on a 14-month scale -- if it's 12-month salary, the mean annual wage of analysis sample should be 14600.31 rather than 17033.7.

gen annual_wage=wage0*14
gen annual_wage_1000=annual_wage/1000
bysort duration_month: egen mean_annual_wage_1000=mean(annual_wage_1000)

preserve
keep duration_month mean_annual_wage_1000
duplicates drop duration_month, force
save figure3b.dta, replace
twoway (scatter mean_annual_wage_1000 duration_month) (lfit mean_annual_wage_1000 duration_month if duration_month<35.5, lp(solid)) (lfit mean_annual_wage_1000 duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) ylabel(16(0.5)18.5) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Mean Annual Wage (Euro * 1000)") legend(off)
gr save figure3b.gph, replace
gr export figure3b.png, replace
restore

* Figure 4 -- Selection on Observables

* Cox proportional-hazards specification for nonemployment durations: time = nonemployment duration, failure event = find a new job, or be censored (at Jul 01, 2013).
* If people find a new job before the end of database (i.e., not censored), then it's a failure event.

sum ne_start

gen find_new_job_20wk=1 if ne_start<`r(max)'
replace find_new_job_20wk=0 if find_new_job==.

* And the authors also censor the spells at 140 days:

replace find_new_job_20wk=1 if noneduration<140
replace find_new_job_20wk=0 if noneduration>=140

* covariates -- female married austrian ibluecollar age age2 lnwage lnwage2 i.endmo i.endy dg_size experience_year experience_year2 last_job last_duration last_ibluecollar last_recall prior_unemp_dummy last_noneduration last_breaks i.education i.industry i.region


gen ibluecollar=1 if etyp==2
replace ibluecollar=0 if etyp!=2&etyp!=.
gen age2=age^2
gen lnwage=log(wage0)
gen lnwage2=lnwage^2
gen experience_year=experience/365
gen experience_year2=experience_year^2
gen last_ibluecollar=1 if last_etyp==2
replace last_ibluecollar=0 if last_etyp!=2&last_etyp!=.
gen prior_unemp_dummy=1 if last_breaks>0
replace prior_unemp_dummy=0 if last_breaks==0
la var prior_unemp_dummy "indicator for having a prior spell of nonemployment"

stset noneduration, failure(find_new_job_20wk==1)

stcox female married austrian ibluecollar age age2 lnwage lnwage2 i.endmo i.endy dg_size experience_year experience_year2 last_job last_duration last_ibluecollar last_recall prior_unemp_dummy last_noneduration last_breaks i.education i.industry i.region
predict predicted_hazard_ratio1

bysort duration_month: egen mean_predicted_hr1=mean(predicted_hazard_ratio1)

*************** And try some other centralized variables, to replicate the original paper********
* Try to centralize all non-dummy variables:

cap drop c_*

foreach var of varlist age age2 lnwage lnwage2 dg_size experience_year experience_year2 last_duration last_noneduration last_breaks{
	qui sum `var'
	gen c_`var'=`var'-`r(mean)'
}

stcox female married austrian ibluecollar c_age c_age2 c_lnwage c_lnwage2 i.endmo i.endy c_dg_size c_experience_year c_experience_year2 last_job c_last_duration last_ibluecollar last_recall prior_unemp_dummy c_last_noneduration c_last_breaks i.education i.industry i.region
predict predicted_hazard_ratio2
bysort duration_month: egen mean_predicted_hr2=mean(predicted_hazard_ratio2)

* And try to centralize all variables:

qui tab endmo, gen(endmo_dummy)
qui tab endy, gen(endy_dummy) 
qui tab education, gen(education_dummy) 
qui tab industry, gen(industry_dummy)
qui tab region, gen(region_dummy)
foreach var of varlist *_dummy* female married austrian ibluecollar last_job last_ibluecollar last_recall{
	qui sum `var'
	gen c_`var'=`var'-`r(mean)'
}
stcox c_*
predict predicted_hazard_ratio3
bysort duration_month: egen mean_predicted_hr3=mean(predicted_hazard_ratio3)
***************

preserve
keep duration_month mean_predicted_hr*
duplicates drop duration_month, force
save figure4.dta, replace
twoway (scatter mean_predicted_hr1 duration_month) (lfit mean_predicted_hr1 duration_month if duration_month<35.5, lp(solid)) (lfit mean_predicted_hr1 duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Mean Predicted Hazard Ratios") legend(off)
gr save figure4_1.gph, replace
gr export figure4_1.png, replace

twoway (scatter mean_predicted_hr2 duration_month) (lfit mean_predicted_hr2 duration_month if duration_month<35.5, lp(solid)) (lfit mean_predicted_hr2 duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Mean Predicted Hazard Ratios") legend(off)
gr save figure4_2.gph, replace
gr export figure4_2.png, replace

twoway (scatter mean_predicted_hr3 duration_month) (lfit mean_predicted_hr3 duration_month if duration_month<35.5, lp(solid)) (lfit mean_predicted_hr3 duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Mean Predicted Hazard Ratios") legend(off)
gr save figure4_3.gph, replace
gr export figure4_3.png, replace
restore

****** In fact, figure4_2.png is the most similar one (although all of these figures have the same curve shapes) -- the authors centralized some of the covariates in Cox regression.
 
* Figure 5 -- Effect of Severance Pay on Nonemployment Durations

gen included=1 if noneduration<=2*365
replace included=0 if included==.
la var included "nonemployment no longer than 2 years"
bysort duration_month: egen mean_noneduration=mean(noneduration) if included==1

preserve
keep duration_month mean_noneduration included
keep if included==1
duplicates drop duration_month, force
save figure5.dta, replace
twoway (scatter mean_noneduration duration_month) (qfit mean_noneduration duration_month if duration_month<35.5, lp(solid)) (qfit mean_noneduration duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Mean Nonemployment Duration (days)") legend(off)
gr save figure5.gph, replace
gr export figure5.png, replace
restore

* Figure 6 -- Effect of Severance Pay on Job-Finding Hazards

* firstly, generate the dummies for JT13...JT34, JT36...JT58:
* We can generate JT35 here (does no harm), but do not include JT35 in the regression:

forvalue i=13(1)58{
	gen jt_`i'= (duration_month==`i')
}

* then generate MW (months worked) in the past 5 years, to identify Extended Benefits:

gen mw = dempl5/31 - 36
la var mw "precise months worked in the past 5 years, centered"
gen mw2=mw^2
gen mw3=mw^3
gen eb=1 if dempl5>=3*365
replace eb=0 if dempl5<3*365
la var eb "availability of Extended Benefit, cutoff at 36"
gen eb_mw1=eb*mw
gen eb_mw2=eb*mw^2
gen eb_mw3=eb*mw^3

* Cox regress according to Eq. (13), and plot the coefficients:

stset noneduration, failure(find_new_job_20wk==1)

stcox jt_13-jt_34 jt_36-jt_58 eb mw mw2 mw3 eb_mw1 eb_mw2 eb_mw3 if duration_month!=12 & duration_month!=59, nohr

preserve
clear
set obs 46
gen duration_month=.
gen estimated_theta=.
local i=1
while `i'<=46{
	local j=`i'+12
	replace duration_month=`j' in `i'
	if `j'!=35{
		replace estimated_theta=_b[jt_`j'] in `i'
		local ++i
	}
	else{
		replace estimated_theta=0 in `i'
		local ++i
	}
}
* Note: for jt_35 (baseline group), all the dummies jt_13-jt_34 and jt_36-jt_58 equal 0; therefore, replace the estimated theta = 0 at i=month=35 to reflect the baseline hazard.
save figure6.dta, replace
twoway (scatter estimated_theta duration_month) (qfit estimated_theta duration_month if duration_month<35.5, lp(solid)) (qfit estimated_theta duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Average Daily Job Finding Hazard in First 20 Weeks") legend(off)
gr save figure6.gph, replace
gr export figure6.png, replace
restore

* FIgure 8a -- Effect of Benefit Extension on Nonemployment Durations

* "As in Figure 5, this figure ignores censoring and excludes observations with a nonemployment duration of more than two years." Also, exclude observations with a nonemployment duration of more than two years.

gen dempl5_centered = dempl5-3*365
sum dempl5_centered
egen mw_int_centered = cut(dempl5_centered), at(-744(31)744)
replace mw_int_centered=mw_int_centered/31
gen mw_int=mw_int_centered+36

la var mw_int "integer months worked in the past 5 years"

bysort mw_int: egen mean_noneduration_mw=mean(noneduration) if included==1

preserve
keep mw_int mean_noneduration_mw included
keep if included==1
duplicates drop mw_int, force
save figure8a.dta, replace
twoway (scatter mean_noneduration_mw mw_int) (qfit mean_noneduration_mw mw_int if mw_int<35.5, lp(solid)) (qfit mean_noneduration_mw mw_int if mw_int>35.5, lp(solid)) if mw_int!=12 & mw_int!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Months Employed in Past Five Years") ytitle("Mean Nonemployment Duration (days)") legend(off)
gr save figure8a.gph, replace
gr export figure8a.png, replace
restore

* Figure 8b -- Effect of Extended Benefits on Job-Finding Hazards

gen jt=duration/31 - 36
gen sp= (duration_month>=36)
la var sp "availability of Severance Pay, cutoff duration_month >= 36"
la var jt "precise duration month, centered"
gen jt2=jt^2
gen jt3=jt^3
gen sp_jt1=sp*jt
gen sp_jt2=sp*jt2
gen sp_jt3=sp*jt3

forvalue i=13(1)58{
	gen mw_`i'= (mw_int==`i')
}

stset noneduration, failure(find_new_job_20wk==1)

stcox mw_13-mw_34 mw_36-mw_58 sp jt jt2 jt3 sp_jt1 sp_jt2 sp_jt3 if mw_int!=12 & mw_int!=59, nohr

preserve
clear
set obs 46
gen mw_int=.
gen estimated_theta=.
local i=1
while `i'<=46{
	local j=`i'+12
	replace mw_int=`j' in `i'
	if `j'!=35{
		replace estimated_theta=_b[mw_`j'] in `i'
		local ++i
	}
	else{
		replace estimated_theta=0 in `i'
		local ++i
	}
}
save figure8b.dta, replace
twoway (scatter estimated_theta mw_int) (qfit estimated_theta mw_int if mw_int<35.5, lp(solid)) (qfit estimated_theta mw_int if mw_int>35.5, lp(solid)) if mw_int!=12 & mw_int!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Months Employed in Past Five Years") ytitle("Average Daily Job Finding Hazard in First 20 Weeks") legend(off)
gr save figure8b.gph, replace
gr export figure8b.png, replace
restore

* Figure 10a -- Effect of Severace Pay on Subsequent Wages

gen wage_growth = log(ne_wage0)-log(wage0)
bysort duration_month: egen mean_wage_growth=mean(wage_growth)

preserve
keep duration_month mean_wage_growth
duplicates drop duration_month, force
save figure10a.dta, replace
twoway (scatter mean_wage_growth duration_month) (lfit mean_wage_growth duration_month if duration_month<35.5, lp(solid)) (lfit mean_wage_growth duration_month if duration_month>35.5, lp(solid)) if duration_month!=12 & duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Wage Growth") legend(off)
gr save figure10a.gph, replace
gr export figure10a.png, replace
restore

* Figure 10b -- Effect of Severance Pay on Subsequent Job Duration
 
* for the observations who have the next job (indnempl==1), generate a "job end dummy" to mark the failure event of "new job ends in the first 5 years":

egen next_duration_month=cut(ne_duration), at(0(31)8215)
replace next_duration_month=next_duration_month/31

gen ne_end=ne_start+ne_duration
sum ne_start
gen next_job_end=1 if ne_end<`r(max)'
replace next_job_end=0 if next_job_end==.
replace next_job_end=0 if ne_duration>=5*365

stset next_duration_month if indnempl==1, failure(next_job_end==1)

stcox jt_13-jt_34 jt_36-jt_58 if duration_month!=12 & duration_month!=59, nohr

preserve
clear
set obs 46
gen duration_month=.
gen estimated_theta=.
local i=1
while `i'<=46{
	local j=`i'+12
	replace duration_month=`j' in `i'
	if `j'!=35{
	replace estimated_theta=_b[jt_`j'] in `i'
	local ++i
	}
	else{
	replace estimated_theta = 0 in `i'
	local ++i
	}
}
save figure10b.dta, replace
twoway (scatter estimated_theta duration_month) (qfit estimated_theta duration_month if duration_month<35.5, lp(solid)) (qfit estimated_theta duration_month if duration_month>35.5, lp(solid)) if duration_month!=12&duration_month!=59, scheme(s2manual) graphregion(color(white)) xlabel(12(6)60) xline(35.5) xtitle("Previous Job Tenure (Months)") ytitle("Average Monthly Job Ending Hazard in Next Job") legend(off)
gr save figure10b.gph, replace
gr export figure10b.png, replace
restore


*************************************


* Question 4 -- replicate the Cox regressions

* Table 2, column 1 -- no controls

local polynomials "sp eb jt jt2 jt3 sp_jt1 sp_jt2 sp_jt3 mw mw2 mw3 eb_mw1 eb_mw2 eb_mw3"

stset noneduration, failure(find_new_job_20wk==1)
stcox `polynomials', nohr cl(penr)
est sto t21

* Table 2, column 2 -- basic controls

local basic_controls "female married austrian ibluecollar age age2 lnwage lnwage2 i.endmo i.endy"

stcox `polynomials' `basic_controls',nohr cl(penr)
est sto t22

* Table 2, column 3 -- all controls

local other_controls "dg_size experience_year experience_year2 last_job last_duration last_ibluecollar last_recall prior_unemp_dummy last_noneduration last_breaks i.education i.industry i.region"

stcox `polynomials' `basic_controls' `other_controls',nohr cl(penr)
est sto t23

* Table 2, column 4 -- reweighted

* Weights should be constructed according to a random sample of all workers (as mentioned in Appendix C). 
* However, this sample is unavailable (the file sample_75_02.dta is "extracted from all terminations between 1981 and 2001 from jobs that ..." rather than all workers with both unemployment and non-unemployment).
* Therefore, this column has to be left blank.

* Table 2, column 5 -- >=4 layoffs in a month, by firm
* benr is the firm ID

bysort benr endy endmo: egen monthly_unemp = total(i)
la var monthly_unemp "total unemployment by a specific firm in a specific month"

stcox `polynomials' `basic_controls' if monthly_unemp>=4,nohr cl(penr)

est sto t25

* Note that Table 3 are estimated on the full sample of workers who find a new job before the sample ends (in the notes for Table 3). Different from previous Therefore, I generate an indicator for "find a new job before the sample ends":

sum ne_start
gen find_new=(ne_start<`r(max)')

* Table 3, column 1 -- OLS, change in log wage, no controls

reg wage_growth `polynomials' if find_new==1, cl(penr)
est sto t31

* Table 3, column 2 -- OLS, change in log wage, full controls

reg wage_growth `polynomials' `basic_controls' `other_controls' if find_new==1, cl(penr)
est sto t32

* Table 3, column 3 -- Hazard model, duration of next job, no controls

gen leave_job_5yrs=1 if ne_duration<5*365
replace leave_job_5yrs=0 if ne_duration>=5*365
replace leave_job_5yrs=. if find_new==0

stset ne_duration, f(leave_job_5yrs==1)

* the failure event is "leave next job within 5 years"

stcox `polynomials', nohr cl(penr)
est sto t33

* Table 3, column 4 -- Hazard model, duration of next job, full controls

stcox `polynomials' `basic_controls' `other_controls', nohr cl(penr)
est sto t34

* Export the Tables

esttab t21 t22 t23 t25 using "table2.tex", replace keep(sp eb) long ti(Table 2, month) se num
esttab t31 t32 t33 t34 using "table3.tex", replace keep(sp eb) long ti(Table 3, month) se num

********************

* Re-replicate Table 2 and 3, using year meansurements (and now cutoff = 3 years rather than 36 months):

gen jt_year=duration/365-3
gen mw_year=dempl5/365-3
gen sp_year=(jt_year>=0)
gen eb_year=(mw_year>=0)
gen jt_year2=jt_year^2
gen jt_year3=jt_year^3
gen mw_year2=mw_year^2
gen mw_year3=mw_year^3
gen sp_jt_year1=sp_year*jt_year
gen sp_jt_year2=sp_year*jt_year2
gen sp_jt_year3=sp_year*jt_year3
gen eb_mw_year1=eb_year*mw_year
gen eb_mw_year2=eb_year*mw_year2
gen eb_mw_year3=eb_year*mw_year3

local year_polynomials "sp_year eb_year jt_year jt_year2 jt_year3 mw_year mw_year2 mw_year3 sp_jt_year1 sp_jt_year2 sp_jt_year3 eb_mw_year1 eb_mw_year2 eb_mw_year3"

* Table 2

stset noneduration, failure(find_new_job_20wk==1)
stcox `year_polynomials', nohr cl(penr)
est sto t21_year
stcox `year_polynomials' `basic_controls', nohr cl(penr)
est sto t22_year
stcox `year_polynomials' `basic_controls' `other_controls', nohr cl(penr)
est sto t23_year
stcox `year_polynomials' `basic_controls' if monthly_unemp>=4, nohr cl(penr)
est sto t25_year

esttab t21_year t22_year t23_year t25_year using "table2_year.tex", replace keep(sp_year eb_year) long ti(Table 2, year) se num

* Table 3

reg wage_growth `year_polynomials' if find_new==1, cl(penr)
est sto t31_year
reg wage_growth `year_polynomials' `basic_controls' `other_controls' if find_new==1, cl(penr)
est sto t32_year

stset ne_duration, f(leave_job_5yrs==1)
stcox `year_polynomials', nohr cl(penr)
est sto t33_year
stcox `year_polynomials' `basic_controls' `other_controls', nohr cl(penr)
est sto t34_year

esttab t31_year t32_year t33_year t34_year using "table3_year.tex", replace keep(sp_year eb_year) long ti(Table 3, year) se num


**************************************

* Robustness check: re-estimate Table (2) column (1) using different bandwidths and orders; measure JT and MW by month; cutoff = 36-month

* Bandwidth1 = 5 months, i.e., include observations with either "31<= job tenure <=41" or "31<= months worked <=41":
* Bandwidth2 = 10 months, bandwidth3 = 15 months
* Polynomial order = 1, 2, and 3, respectively

local polynomials1 "sp eb jt sp_jt1 mw eb_mw1"
local polynomials2 "sp eb jt jt2 sp_jt1 sp_jt2 mw mw2 eb_mw1 eb_mw2"
local polynomials3 "sp eb jt jt2 jt3 sp_jt1 sp_jt2 sp_jt3 mw mw2 mw3 eb_mw1 eb_mw2 eb_mw3"

mat SP = J(6,3,0)
mat EB = J(6,3,0)

* The 1,3,5 rows for estimates, and 2,4,6 rows for std err; rows for order 1-3, and columns for band 5-15.

foreach order in "1" "2" "3"{
	foreach band in "5" "10" "15"{
		stset noneduration, failure(find_new_job_20wk==1)
		stcox `polynomials`order'' if (jt>=-`band' & jt<=`band')|(mw>=-`band' & mw<=`band'), nohr cl(penr)
		mat SP[2*`order'-1,`band'/5] = _b[sp]
		mat SP[2*`order',`band'/5] = _se[sp]
		mat EB[2*`order'-1,`band'/5] = _b[eb]
		mat EB[2*`order',`band'/5] = _se[eb]
	}
}

mat list SP
mat list EB

* end of do file
