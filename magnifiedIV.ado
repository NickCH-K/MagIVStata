cap prog drop magnifiedIV
prog def magnifiedIV

	syntax anything [if] [in] [fw iw aw pw], grouping(string) [est(string)] [groupformula(string)] [ivfor(varlist)] [ngroups(integer 4)] [p(real .25)] [silent] [groupsearchopts(string)] [groupCFopts(string)] [ivregressopts(string)]

	if _N/`ngroups' < 5 {
		display as error "Warning: Each group will have fewer than five observations in it."
		display as text "While there isn't a specific value for too few observations per group, few observations per group may not reduce IV bias."
	}
	if "`grouping'" != "groupCF" & "`grouping'" != "groupsearch" {
		foreach x in `grouping' {
			capture summ `x'
			if _rc > 0 {
				display as error "grouping must be 'groupCF', 'groupsearch', or a list of numeric (categorical) variable names."
				exit 198
			}
		}
	}
	if "`est'" == "" {
		local est = "group"
	}
	if !inlist("`est'","group","weight","both") {
		display as error "est must be 'group', 'weight', or 'both'."
		exit 198
	}
	if inlist("`est'","weight","both") & "`weight'" != "" {
		display as error "Sample weights cannot be combined with est(weight) or est(both)."
		exit 184
	}
	if strpos("`anything'","(") == 0 | strpos("`anything'",")") == 0 {
		display as error "Syntax before the comma is similar to ivregress."
		exit 198
	}
	
	marksample touse
	
	* Parse the IV specification
	local ivtype = trim(word("`anything'",1))
	local dvname = trim(word("`anything'",2))
	local anything = substr("`anything'",strpos("`anything'"," ")+1,.)
	local anything = substr("`anything'",strpos("`anything'"," ")+1,.)
	local exonames = substr("`anything'",1,strpos("`anything'","(")-1)
	local anything = substr("`anything'",strpos("`anything'","(")+1,.)
	local anything = substr("`anything'",1,strpos("`anything'",")")-1)
	local endonames = trim(substr("`anything'",1,strpos("`anything'","=")-1))
	local exclnames = trim(substr("`anything'",strpos("`anything'","=")+1,.))
	
	
	* Fix touse since it won't pick up all the missings from `anything'
	fvrevar `dvname' `exonames' `endonames' `exclnames'
	foreach var of varlist `r(varlist)' {
		replace `touse' = 0 if missing(`var')
	} 
	
	foreach x in ivtype dvname exonames endonames exclnames {
		local x = trim("``x''")
	}

	if wordcount("`exclnames'") < wordcount("`endonames'") {
		display as error "There must be at least as many excluded instruments as endogenous variables."
		exit 102
	}
	if wordcount("`exclnames'") > wordcount("`endonames'") & wordcount("`endonames'") > 1 & "`ivfor'" == "" {
		display as error "If there is more than one endogenous variable and the model is not just-identified, ivfor() must be specified."
		exit 102
	}
	if "`ivfor'" != "" & wordcount("`ivfor'") != wordcount("`exclnames'") {
		display as error "There must be exactly one variable in ivfor() for every variable in varlist_iv."
		exit 102
	}
	if wordcount("`endonames'") > 1 & inlist("`est'","weight","both") {
		display as error "est(weight) and est(both) can only be used with a single endogenous variable."
		exit 184
	}
	if wordcount("`endonames'") > 1 {
		display as error "Warning: see help file for how magnifiedIV handles multiple endogenous variables, as behavior may not be expected."
		display as text ""
	}
	if wordcount("`exclnames'") > 1 & (strpos("`groupsearchopts'","g(") > 0 | strpos("`groupCFopts'","g(") > 0) {
		display as error "g() not allowed in groupsearchopts or groupCFopts if there is more than one instrument."
		exit 103
	}
	if strpos("`exclnames'",".") > 0 | strpos("`exclnames'","#") {
		display as error "Currently no support for i., c., ibn., L., F., or # in varlist_iv, sorry :(. Make your interaction, lag, and dummy instruments by hand."
		exit 184
	}

	* Make the instrument list explicit
	if strpos("`exclnames'","*") {
		fvunab exclrep: `exclnames'
		local exclnames = trim("`exclrep'")
	}
	
	* Get group formulae
	
	if inlist("`grouping'","groupCF","groupsearch") {
	
		if "`groupformula'" == "" {
			foreach x in `endonames' {
				local groupformula = "`groupformula', `x' `exonames'"
			}
			local groupformula = substr("`groupformula'",2,.)
		}
	
		local numform = 1 + length("`groupformula'") - length(subinstr("`groupformula'",",","",.))
		if `numform' != wordcount("`exclnames'") {
			display as error "There must be exactly one varlist in groupformula for each excluded instrumental variable."
			exit 100
		}
		local groupformula = "`groupformula',"
	
		foreach iv in `exclnames' {
			local rhs_`iv' = substr("`groupformula'",1,strpos("`groupformula'",",")-1)
			local groupformula = substr("`groupformula'",strpos("`groupformula'",",")+1,.)
		}	
	}
	
	
	local groupFE = ""
	local inx = ""
	
	quietly {
		
		* Get Groupings
		local count = 1
		foreach iv in `exclnames' {	
			if wordcount("`endonames'") == 1 {
				local endo = "`endonames'"
			}
			else if "`ivfor'" == "" {
				local endo = word("`endonames'",`count')
			}
			else {
				local endo = word("`ivfor'",`count')
			}
		
			if "`grouping'" == "groupCF" {
				if "`silent'" != "" {
					noisily display "Starting causal forest for `iv' at $S_DATE $S_TIME. This may take a moment."
				}
				
				local group_`iv' = "CF_`iv'"
				if strpos("`groupCFopts'","g(") != 0 {
					local group_`iv' = substr("`groupCFopts'",strpos("`groupCFopts'","g(")+1,.)
					local group_`iv' = substr("`group_`iv''",1,strpos("`group_`iv''",")"))
				}
				capture drop `group_`iv''
				capture drop groupCF
				
				groupCF `endo' `iv' `rhs_`iv'' if `touse' [`weight'`exp'], `groupCFopts'
				
				if strpos("`groupsearchopts'","g(") == 0 {
					rename groupCF CF_`iv'
				}
				
				local groupFE = "`groupFE' i.`group_`iv''"
				local inx = "`inx' c.`iv'#i.`group_`iv''"
				
				if "`silent'" != "" {
					noisily display "Finished causal forest for `iv' at $S_DATE $S_TIME."
				}
		
			}
			else if "`grouping'" == "groupsearch" {
				local group_`iv' = "GS_`iv'"
				if strpos("`groupsearchopts'","g(") != 0 {
					local group_`iv' = substr("`groupsearchopts'",strpos("`groupsearchopts'","g(")+1,.)
					local group_`iv' = substr("`group_`iv''",1,strpos("`group_`iv''",")"))
				}
				capture drop `group_`iv''
				capture drop groupsearch
			
				if "`silent'" == "silent" {
					groupsearch `endo' `iv' `rhs_`iv'' if `touse' [`weight'`exp'], `groupsearchopts' 
				}
				else {
					noisily groupsearch `endo' `iv' `rhs_`iv'' if `touse' [`weight'`exp'], `groupsearchopts'
				}
				
				if strpos("`groupsearchopts'","g(") == 0 {
					rename groupsearch GS_`iv'
				}
				
				local groupFE = "`groupFE' i.`group_`iv''"
				local inx = "`inx' c.`iv'#i.`group_`iv''"
			}
			else {
				local grn = word("`grouping',`count'")
				local groupFE = "`groupFE' i.`grn'"
				local inx = "`inx' c.`iv'#i.`grn'"
			}
			
			local count = `count' + 1
		}

		* If we need weights, get 'em
		if inlist("`est'","weight","both") {
			
			* Get SSE for first stage for personalized F statistic construction
			reg `endonames' `inx' `groupFE' `exonames' if `touse' [`weight'`exp']
			local sse0 = r(rss)
			
			tempvar indfx
			factorpull `indfx' = `group_`exclnames'', interaction(c.`exclnames')
			
			tempvar myF
			ownpersonalssesus `exclnames' `indfx', g(`myF')
			
			tempvar magweight
			g `magweight' = 0 if `myF' == 0
			replace `magweight' = `myF'^`p' if `myF' != 0
			
			local weight = "iw"
			local exp = "=`magweight'"
		}
	}
	
	* Now run IV!!
	ivregress `ivtype' `dvname' `exonames' `groupFE' (`endonames' = `inx') if `touse' [`weight'`exp'], `ivregressopts'
end
