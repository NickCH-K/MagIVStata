cap prog drop factorpull
prog def factorpull

	syntax anything =/exp , [interaction(string)] [basevalue(real 0)] [addterm(string)] [value(string)] [includedropped]
	
	version 13
	
	if wordcount("`anything'") > 1 {
		exit 103
	}
	
	quietly {
		* Fill in defaults
		if "`value'" == "" {
			local value = "_b"
		}
		local cond = "e(sample) & "
		if "`includedropped'" == "includedropped" {
			local cond = ""
		}
		
		* Construct interior term
		local combo = ""
		if "`interaction'" != "" {
			local combo = "#`interaction'"
		}
		local addon = ""
		if "`addterm'" != "" {
			local addon = "+ `value'[`addterm']"
		}
	
		* Get levels of the factor variable to loop over
		levelsof `exp', l(levs)

		generate `anything' = .
		
		foreach x in `levs' {
			replace `anything' = `basevalue' + `value'[`x'.`exp'`combo'] `addon' if `cond' `exp' == `x'
		}
	
	}

end

