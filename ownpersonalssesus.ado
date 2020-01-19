cap prog drop ownpersonalssesus
prog def ownpersonalssesus

	syntax varlist [if] [in], [g(name)] [df_r(integer -1)] [rss(real -1)] [all]
		
	version 13
	
	quietly {
	
		tempvar touse
		capture g `touse'= e(sample) `if' `in'
		if "`all'" == "all" {
			g `touse' = 1 `if' `in'
		}
		
		* Default
		if "`g'" == "" {
			local g = "indivF"
		}
	
		* Get regression components
		cap local nmk = e(df_r)
		if "`df_r'" != "-1" {
			local nmk = `df_r'
		}
		cap local sse0 = e(rss)
		if "`rss'" != "-1" {
			local sse0 = `rss'
		}
		
		* Get list of varying-effect variables and their individual effects
		local wc = wordcount("`varlist'")/2
		if (floor(`wc') != `wc') {
			display as error "varlist must be a list of variables with varying effects in the regression, followed by the individual-level treatment effect estimates for each, and so must be even in length."
			exit as 103
		}
		
		* Temporarily remove all these varying-effect variables from the equation
		local fxvars = ""
		forvalues i = 1(1)`wc' {
			tempvar bkup`i'
			local varn = word("`varlist'",`i')
			g `bkup`i'' = `varn'
			replace `varn' = 0
			
			local fxn = word("`varlist'",`i'+`wc')
			local fxvars = "`fxvars' `fxn'"
		}
		
		* Create prediction
		tempvar pred
		predict `pred' if `touse'
		
		* Put 'em back, and add them to the prediction
		forvalues i = 1(1)`wc' {
			local varn = word("`varlist'",`i')
			replace `varn' = `bkup`i''
		}
		
		* Get original order to re-sort
		tempvar origorder
		g `origorder' = _n
		
		* Go through one obs at a time; check if effect values match in an attempt to skip some
		gsort -`touse' `fxvars'
		tempvar runseparate
		g `runseparate' = _n == 1
		foreach x in `fxvars' {
			replace `runseparate' = 1 if `x' != `x'[_n-1]
		}
		
		* Now get individual F stat one obs at a time
		g `g' = .
		tempvar addpred
		g `addpred' = .
		count if `touse'
		local nobs = r(N)
		forvalues i = 1(1)`nobs' {
			if `runseparate'[`i'] == 1 {
				replace `addpred' = `pred'
				forvalues j = 1(1)`wc' {
					local varn = word("`varlist'",`j')
					local fxn = word("`varlist'",`j'+`wc')
					replace `addpred' = `addpred' + `varn'*`fxn'[`i']
				}
				
				replace `addpred' = (`addpred')^2
				noisily summ `addpred'
				noisily di `nmk'
				noisily di `sse0'
				replace `g' = r(N)*r(mean)*`nmk'/`sse0' in `i'
			}
		}
		* Fill in for the ones with identical effects
		replace `g' = `g'[_n-1] if `runseparate' == 0 & `touse'
		
		* Return original order
		sort `origorder'
	
	}
	
end

/*
ownPersonalSSEsus <- function(co, excl, mpred, sse0, n, k) {

  # Construct prediction with the given coefficients
  pred <- mpred +
    rowSums(t(co*
              t(excl)))

  ss1 <- sum((pred)^2)

  Fstat <- (n-k)*ss1/sse0
  return(Fstat)
}
#' Create Personalized F-Statistic
#'
#' This function creates an F-statistic of the personalized kind described in Huntington-Klein (2019).
#'
#' In particular, it calculates (N-K)*Var(x-hat | individual coefficients)/Var(x-hat).
#'
#' In Magnified IV this is raised to the power p to be used as a regression weight. This funciton is largely used internally for \code{magnifiedIV()} but it is exported here for use in case you'd like to use it to create your own weights. It is perhaps not as user-friendly as it could be, but it is largely an internal function.
#'
#' @param co This is a vector of coefficients unique to one individual, containing only the coefficients that vary across the sample. For example, if the grouped regression model contains \code{z*group}, then \code{co} would be a single value containing an individual's \code{z} effect.
#' @param excl This is a data frame containing just the variable(s) over which the effects vary. So if the regression model contains \code{z*group}, this would be a data frame containing only \code{z}.
#' @param mpred This is a vector containing the regression model prediction *if all variables in \code{excl} were set to 0*.
#' @param sse0,n,k These are the sum of squared errors, the number of observations, and the number of coefficients in the original regression model.
#' @examples
#'
#' df <- data.frame(w1 = rnorm(1000),
#'                  w2 = rnorm(1000),
#'                  e1 = rnorm(1000),
#'                  e2 = rnorm(1000),
#'                  z = rnorm(1000),
#'                  groups = factor(floor(0:999/100)))
#' df$x <- df$w1+df$w2+df$z+df$e1
#'
#' fsmodel <- lm(x ~ z*groups + w1 + w2, data = df)
#'
#' sse0 <- sum((fsmodel$residuals)^2)
#'
#' indivfx <- factorPull(fsmodel,
#'                       data = df,
#'                       factor = 'groups',
#'                       interaction = 'z',
#'                       addterm = 'z')
#'
#' # Create prediction for each observation with just the coefficients that are the
#' # same for everyone
#' mpred <- rowSums(t(coef(fsmodel)[c('(Intercept)','w1','w2')]*
#'                      t(model.matrix(fsmodel)[,c('(Intercept)','w1','w2')])))
#' # Get a data frame of just the variables with effects that vary
#' excl <- data.frame(z = df[['z']])
#'
#' # Get the relevant N and K
#' n <- nrow(df)
#' k <- length(fsmodel$coefficients)
#'
#' # And finally produce that individualized F statistic
#' indiv.F <- sapply(indivfx, function(x)
#'   ownPersonalSSEsus(x, excl, mpred, sse0, n, k))
#' @export



*/