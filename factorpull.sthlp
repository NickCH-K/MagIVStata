{smcl}
{* *! version 1.2.2  15may2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Author" "examplehelpfile##author"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:factorpull}

{phang}
{bf:factorpull} {hline 2} factorpull to extract factor or factor-interaction coefficients as a variable


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:factorpull} {help name} = {help exp}, [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt interaction(string)}} if pulling out interaction coefficients, the variable being interacted with. Include the full term, so "c.gear_ratio" to get interactions with continuous variable gear_ratio, or "1.race" to get interactions with race = 1{p_end}
{synopt:{opt basevalue(#)}} value to add to all terms; also the value assigned to reference groups if {opt:value} is not specified{p_end}
{synopt:{opt addterm(string)}} name of a term whose coefficient is to be added to all terms, for example set to the same thing as {opt:interaction} to get total effects rather than just interaction terms {p_end}
{synopt:{opt value(string)}} the coefficient-specific regression element to be accessed, such as {it:_b} or {it:_se}. {p_end}
{synopt:{opt includedropped}} assign values for observations that have nonmissing values of {it:exp} but have been dropped from regression{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{cmd:factorpull} is a postestimation command for regressions containing dummies from a factor variable implemented with {it:i.} in the regression, or a factor variable interacted with something else using {it:#}. It will pull out those coefficients and line them up with the original data so you can store them as a variable.

{marker author}{...}
{title:Author}

Nick Huntington-Klein
nhuntington-klein@fullerton.edu


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse nlsw88.dta, clear}{p_end}
{phang}{cmd:. regress wage i.age married i.race}{p_end}
{phang}{cmd:. factorpull age_effect = age}{p_end}

{phang}{cmd:. regress wage i.age##i.married i.race}{p_end}
{phang}{cmd:. factorpull total_marriage_effect_by_age = age, interaction(1.married) addterm(1.married)}{p_end}

