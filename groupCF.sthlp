{smcl}
{* *! version 1.2.2  15may2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Author" "examplehelpfile##author"}{...}
{viewerjumpto "References" "examplehelpfile##references"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:groupsearch}

{phang}
{bf:groupCF} {hline 2} groupCF to generate effect heterogeneity quantiles using causal forest


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:groupCF} {help depvar} {help indvar} {help varlist} [{help if}] [{help in}] [{help weight}], [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt g(name)}} create variable name. "groupCF" if not specified{p_end}
{synopt:{opt ngroups(#)}} number of groups to divide the data into, 4 by default. Note that, if you really want, you could set this to the number of observations in the analysis, {help decode} the result, and then fish the numbers out of the string variable you'll get, which will get predicted effects from causal forest without dealing with quantiles. {p_end}
{synopt:{opt CFopts(string)}} Options to pass to the R function {cmd: grf::causal_forest()}, in R syntax. See {cmd: rcall: help(causal_forest)}. Do not include {cmd: sample.weights}, instead include weights with {cmd: [weight]}. Any option other than {cmd: sample.weights} that requires a matrix or variable as input will probably not work.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed {it: but} will not be treated like Stata treats weights. Instead they will be used as the {cmd: sample.weights} argument in {cmd: grf::causal_forest}. Note that the {cmd: grf::causal_forest} weights option is experimental.


{marker description}{...}
{title:Description}

{pstd}
{cmd:groupCF} performs the Causal Forest algorithm using the {cmd: causal_forest} algorithm in R's {cmd: grf} (Athey, Tibshirani, & Wager, 2019). It then takes the predicted individual-level estimates and turns them into quantiles, and returns the quantiles as a variable to Stata. It is strongly recommended that you read the {cmd: grf::causal_forest} help file, which you can do with {cmd: rcall: help(causal_forest, package = 'grf')} after running {help groupCFsetup}.

{pstd}
Before running {cmd: groupCF}, you must install R and then set up some packages in both Stata and R. You can do this by first installing R from {browse: "R-project.org":R-Project.org}, and then running the {help groupCFsetup} command. Or if you prefer you can do this yourself, installing R, setting up {help rcall} using the instructions in {browse "https://doi.org/10.1177/1536867X19830891": Hagish (2019)}, and then installing {MagnifiedIV} in R with {cmd: rcall: install.packages('remotes')} followed by {cmd: rcall: remotes::install_github('NickCH-K/MagnifiedIV')}.

{pstd}
Syntax takes the form of {help depvar} {help indvar} {help varlist}. {help depvar} is the dependent variable being predicted ({cmd: Y} in {cmd: grf::causal_forest} syntax). {help indvar} is the treatment variable you are interested in seeing treatment effect heterogeneity for ({cmd: W}), and {help varlist} is the list of variables used to predict treatment effect heterogeneity. These should be variables in Stata and not matrices; {cmd: groupCF} will convert them to matrices for {cmd: grf::causal_forest} use.

{marker author}{...}
{title:Author}

Nick Huntington-Klein
nhuntington-klein@fullerton.edu

{marker references}{...}
{title:References}

{phang} Athey, S., Tibshirani, J., and Wager, S. (2019) Generalized Random Forests. The Annals of Statistics 47 (2), 1148-1178. {browse "https://doi.org/10.1214/18-AOS1709":Link}.

{phang} Haghish, E. F. (2019). Seamless interactive language interfacing between R and Stata. The Stata Journal, 19(1), 61–82. {browse "https://doi.org/10.1177/1536867X19830891"}.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto.dta, clear}{p_end}
{phang}{cmd:. groupCF price mpg rep78-trunk}{p_end}
{phang}{cmd:. tab groupCF}{p_end}

