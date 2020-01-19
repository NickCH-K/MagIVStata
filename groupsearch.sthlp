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
{bf:groupsearch} {hline 2} groupsearch to find effect heterogeneity


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:groupsearch} {help varlist} [{help if}] [{help in}] [{help weight}], [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt g(name)}} create variable name. "groupsearch" if not specified{p_end}
{synopt:{opt ngroups(#)}} number of groups to divide the data into, 4 by default{p_end}
{synopt:{opt ntries(#)}} number of different random groupings to try, 100 by default{p_end}
{synopt:{opt id(varlist)}} a list of variables that indiates that observations with the same values of id should always be in the same group{p_end}
{synopt:{opt silent}} suppress progress report{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:groupsearch} performs the GroupSearch algorithm as in Huntington-Klein (2019) "Instruments with Heterogeneous Effects: Monotonicity, Bias, and Localness."

{pstd}
The GroupSearch algorithm is naive. It simply tries a bunch of random groupings, and for each grouping attempts to predict the first variable in {varlist} with the second variable in {varlist}, after partialing out all further controls in {varlist}. It returns the grouping that produces the highest F-statistic. Be aware before using {cmd:groupsearch} that in the original paper it only did a mediocre job at picking up effect heterogeneity. You may want to use {help groupCF} instead.

{pstd}
This function is called by {help magnifiedIV}. You can also run Magnified IV by yourself without the {help magnifiedIV} function (with any estimator) by running {cmd:groupsearch}, then adding the resulting group variable as a control in both IV stages and also interacted with the instrument. Or use {help factorpull} to get the individual-level effects estimates and use those to construct a sample weight.


{marker author}{...}
{title:Author}

Nick Huntington-Klein
nhuntington-klein@fullerton.edu

{marker references}{...}
{title:References}

{phang} Huntington-Klein, N. (2019) Instruments with Heterogeneous Effects: Bias, Monotonicity, and Localness. CSU Fullerton Economics Working Paper 2019/006. {browse "https://business.fullerton.edu/department/economics/assets/CSUF_WP_6-19.pdf?_=0.4520744169447609":PDF}.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto.dta, clear}{p_end}
{phang}{cmd:. groupsearch price mpg rep78-trunk}{p_end}

