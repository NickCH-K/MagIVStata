cap prog drop groupCF
prog def groupCF
	
	syntax anything [if] [in] [fw aw pw iw/], [g(string)] [ngroups(integer 4)] [cfopts(string)] [seed(integer -1)]

	version 13

	marksample touse
	
	if (_N < `ngroups') {
		display as error "Not enough observations to run. You need at least as many observations as groups."
		exit 125
	}
	if (_N/`ngroups' < 5) {
		noisily display "Warning: Each group will have fewer than five observations in it. While there isn't a specific value for too few observations per group, few observations per group may not reduce IV bias."
	}
	
	capture which rcall
	if _rc > 0 {
		display as error "The use of groupCF requires the rcall package. Run groupCFsetup first."
		exit 133
	}
	
	rcall_check MagnifiedIV>=0.1.0
	if "`r(gotMIV)'" == "FALSE" {
		display as error "groupCF requires that the R package MagnifiedIV be installed. Run groupCFsetup first."
		exit 133
	}
	
	if "`g'" == "" {
		local g = "groupCF"
	}
	if "`cfopts'" != "" {
		local cfopts = ", `cfopts'"
	}
	
	
	quietly {
		preserve
		
		local dv = word("`anything'", 1)
		fvrevar `dv'
		local dv2 = "`r(varlist)'"
		local iv = word("`anything'", 2)
		fvrevar `iv'
		local iv2 = "`r(varlist)'"
		
		local indvars = "`anything'"
		local indvars = substr("`indvars'",strpos("`indvars'"," ")+1,.)
		local indvars = substr("`indvars'",strpos("`indvars'"," ")+1,.)	
		fvrevar `indvars'
		local indvars2 = "`r(varlist)'"
		
		* Fix touse since it won't pick up all the missings from `anything'
		foreach var of varlist `dv2' `iv2' `indvars2' {
			replace `touse' = 0 if missing(`var')
		} 
		
		keep if `touse'
		
		keep `dv2' `iv2' `indvars2' `exp'
		order `dv2' `iv2' `indvars2' `exp'
		
		* R variable names can't start with _
		* Also build new varlists
		local count = 1
		local indvars = ""
		foreach var of varlist * {
			local newname = "`var'"
			if strpos("`newname'","_") == 1 {
				local newname = "X`newname'"
				rename `var' `newname'
			}
			
			if `count' == 1 {
				local dv = "`newname'"
			}
			else if `count' == 2 {
				local iv = "`newname'"
			}
			else if `count' == 3 {
				local indvars = "`newname'"
			}
			else if ("`exp'" == "") | ("`exp'" != "" & "`var'" != "`exp'") {
				local indvars = "`indvars'+`newname'"
			}
			else {
				local exp = "`var'"
			}
			
			local count = `count' + 1
		}

		* Send data over
		rcall clear
		rcall: df <- st.data()

		restore
		
		g `g' = ""
		tempvar tousecounter
		g `tousecounter' = 1
		replace `tousecounter' = `tousecounter'[_n-1] + `touse' if _n > 1
		count if `touse'
		local numtocopy = r(N)
	}	
	
	local seedn = ""
	if "`seed'" != "-1" {
		local seedn = "set.seed(`seed');"
	}
	
	if "`exp'" == "" {
		rcall: `seedn' groups <- MagnifiedIV::groupCF(`dv' ~ `iv' | `indvars', data = df, ngroups = `ngroups'`cfopts'); gn <- as.numeric(groups)
	}
	else {
		rcall: `seedn' wts <- df[,'`exp'']; groups <- MagnifiedIV::groupCF(`dv' ~ `iv' | `indvars', data = df, ngroups = `ngroups'`cfopts', sample.weights = wts); gn <- as.numeric(groups)
	}
	

	
	quietly {
		* Line up the results and store them
		forvalues i = 1(1)`numtocopy' {
			replace `g' = word("`r(gn)'", `i') if `tousecounter' == `i' & `touse'
		}
		
		destring `g', replace
		
		
		summ `g'
		local numgroups = r(max)
		
		rcall: index <- levels(groups)
		
		local apprep = "replace"
		forvalues i = 1(1)`numgroups' {
			local j = `i' - 1
			local x = word(`"`r(index)'"',`i')
			label def cf_`iv' `i' `"`x'"', `apprep'
			local apprep = "add"
		}
		
		label values `g' cf_`iv'
	}
	
	
end