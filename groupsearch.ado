cap prog drop groupsearch
prog def groupsearch

	syntax anything [if] [in] [fw iw aw pw], [g(name)] [ngroups(integer 4)] [ntries(integer 100)] [id(varlist)] [silent]

	version 13
	
	if (_N <= `ngroups') {
		display as error "Not enough observations to run. You need at least as many observations as groups."
		exit 125
	}
	if (_N/`ngroups' < 5) {
		noisily display "Warning: Each group will have fewer than five observations in it. While there isn't a specific value for too few observations per group, few observations per group may not reduce IV bias."
	}
	
	* Get the dependent variable, independent variable, and list of controls
	quietly {
	
		marksample touse
	
		local dv = word("`anything'", 1)
		local iv = word("`anything'", 2)
		
		local indvars = "`anything'"
		local indvars = substr("`indvars'",strpos("`indvars'"," ")+1,.)
		local indvars = substr("`indvars'",strpos("`indvars'"," ")+1,.)

		* Fix touse since it won't pick up all the missings from `anything'
		fvrevar `dv' `iv' `indvars'
		foreach var of varlist `r(varlist)' {
			replace `touse' = 0 if missing(`var')
		} 
		
		* Partial out if we have controls
		tempvar dvuse
		tempvar ivuse
		if (wordcount("`indvars'") > 0) {
			reg `dv' `indvars' if `touse' [`weight'`exp']
			predict `dvuse', r
			reg `iv' `indvars' if `touse' [`weight'`exp']
			predict `ivuse', r
		} 
		else {
			g `dvuse' = `dv'
			g `ivuse' = `iv'
		}
	
	
		* Do we have groups?
		local hasgroups = 0
		if (length("`id'") > 0) {
			local hasgroups = 1
		}
		* If so, store original order
		if `hasgroups' {
			tempvar origorder
			g `origorder' = _n
			
			* And sort according to group variable
			tempvar idgroup
			egen `idgroup' = group(`id')
			sort `idgroup'
		}
		
		
		* Now prepare for the loop
		local winnerF = 0
		tempvar winnergroups
		tempvar currgroups
		g `currgroups' = 0
		g `winnergroups' = 0
		
		local pctdone = 0
		
		forvalues b = 1(1)`ntries' {
		
			* Progress report
			if ("`silent'" != "silent") {
				if (`b' == 1) {
					noisily di "Starting groupsearch at $S_DATE $S_TIME"
				}
				else if (ceil(`b'/(`ntries'/10)) > ceil((`b'-1)/(`ntries'/10))) {
					local pctdone = `pctdone' + 10
					noisily di "`pctdone'% done at $S_DATE $S_TIME"
				}
			}
			
			* Build groups
			replace `currgroups' = ceil(runiform()*`ngroups')
			if `hasgroups' {
				replace `currgroups' = `currgroups'[_n-1] if `idgroup' == `idgroup'[_n-1]
			}
		
			* Run regression
			reg `dvuse' c.`ivuse'##i.`currgroups' if `touse' [`weight'`exp']
			if (e(F) > `winnerF') {
				local winnerF = e(F)
				replace `winnergroups' = `currgroups'
			}
		
		}
		
		if `hasgroups' { 
			sort `origorder'
		}
		
		if (length("`g'") > 0) {
			g `g' = `winnergroups' if `touse'
		}
		else {
			g groupsearch = `winnergroups' if `touse'
		}
		
	}
	

end

