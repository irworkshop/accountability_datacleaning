<h1 id="kentucky-contracts">Kentucky Contracts</h1>
<p>Jennifer LaFleur/Kiernan Nicholls 2022-12-04 16:46:42</p>
<ul>
<li><a href="#project">Project</a></li>
<li><a href="#objectives">Objectives</a></li>
<li><a href="#packages">Packages</a></li>
<li><a href="#data">Data</a></li>
<li><a href="#read">Read</a></li>
<li><a href="#explore">Explore</a></li>
<li><a href="#wrangle">Wrangle</a></li>
<li><a href="#conclude">Conclude</a></li>
<li><a href="#export">Export</a></li>
<li><a href="#dictionary">Dictionary</a></li>
</ul>
<!-- Place comments regarding knitting here -->

<h2 id="project">Project</h2>
<p>The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.</p>
<p>Our goal is to standardize public data on a few key fields by
thinking of each dataset row as a transaction. For each transaction
there should be (at least) 3 variables:</p>
<ol style="list-style-type: decimal">
<li>All <strong>parties</strong> to a transaction.</li>
<li>The <strong>date</strong> of the transaction.</li>
<li>The <strong>amount</strong> of money involved.</li>
</ol>
<h2 id="objectives">Objectives</h2>
<p>This document describes the process used to complete the following
objectives:</p>
<ol style="list-style-type: decimal">
<li>How many records are in the database?</li>
<li>Check for entirely duplicated records.</li>
<li>Check ranges of continuous variables.</li>
<li>Is there anything blank or missing?</li>
<li>Check for consistency issues.</li>
<li>Create a five-digit ZIP Code called <code>zip</code>.</li>
<li>Create a <code>year</code> field from the transaction date.</li>
<li>Make sure there is data on both parties to a transaction.</li>
</ol>
<h2 id="packages">Packages</h2>
<p>The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The <code>pacman</code> package
will facilitate their installation and attachment.</p>
<p>The IRW’s <code>campfin</code> package will also have to be installed
from GitHub. This package contains functions custom made to help
facilitate the processing of campaign finance data.</p>
<div class="sourceCode" id="cb1"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb1-1"><a href="#cb1-1" aria-hidden="true" tabindex="-1"></a><span class="cf">if</span> (<span class="sc">!</span><span class="fu">require</span>(<span class="st">&quot;pacman&quot;</span>)) <span class="fu">install.packages</span>(<span class="st">&quot;pacman&quot;</span>)</span>
<span id="cb1-2"><a href="#cb1-2" aria-hidden="true" tabindex="-1"></a>pacman<span class="sc">::</span><span class="fu">p_load_gh</span>(<span class="st">&quot;irworkshop/campfin&quot;</span>)</span>
<span id="cb1-3"><a href="#cb1-3" aria-hidden="true" tabindex="-1"></a>pacman<span class="sc">::</span><span class="fu">p_load</span>(</span>
<span id="cb1-4"><a href="#cb1-4" aria-hidden="true" tabindex="-1"></a>  tidyverse, <span class="co"># data manipulation</span></span>
<span id="cb1-5"><a href="#cb1-5" aria-hidden="true" tabindex="-1"></a>  lubridate, <span class="co"># datetime strings</span></span>
<span id="cb1-6"><a href="#cb1-6" aria-hidden="true" tabindex="-1"></a>  gluedown, <span class="co"># printing markdown</span></span>
<span id="cb1-7"><a href="#cb1-7" aria-hidden="true" tabindex="-1"></a>  magrittr, <span class="co"># pipe operators</span></span>
<span id="cb1-8"><a href="#cb1-8" aria-hidden="true" tabindex="-1"></a>  janitor, <span class="co"># clean data frames</span></span>
<span id="cb1-9"><a href="#cb1-9" aria-hidden="true" tabindex="-1"></a>  refinr, <span class="co"># cluster and merge</span></span>
<span id="cb1-10"><a href="#cb1-10" aria-hidden="true" tabindex="-1"></a>  scales, <span class="co"># format strings</span></span>
<span id="cb1-11"><a href="#cb1-11" aria-hidden="true" tabindex="-1"></a>  knitr, <span class="co"># knit documents</span></span>
<span id="cb1-12"><a href="#cb1-12" aria-hidden="true" tabindex="-1"></a>  vroom, <span class="co"># read files fast</span></span>
<span id="cb1-13"><a href="#cb1-13" aria-hidden="true" tabindex="-1"></a>  rvest, <span class="co"># html scraping</span></span>
<span id="cb1-14"><a href="#cb1-14" aria-hidden="true" tabindex="-1"></a>  glue, <span class="co"># combine strings</span></span>
<span id="cb1-15"><a href="#cb1-15" aria-hidden="true" tabindex="-1"></a>  here, <span class="co"># relative paths</span></span>
<span id="cb1-16"><a href="#cb1-16" aria-hidden="true" tabindex="-1"></a>  httr, <span class="co"># http requests</span></span>
<span id="cb1-17"><a href="#cb1-17" aria-hidden="true" tabindex="-1"></a>  fs, <span class="co"># local storage </span></span>
<span id="cb1-18"><a href="#cb1-18" aria-hidden="true" tabindex="-1"></a>  stringi <span class="co">#string functions</span></span>
<span id="cb1-19"><a href="#cb1-19" aria-hidden="true" tabindex="-1"></a>)</span></code></pre></div>
<p>This document should be run as part of the <code>R_campfin</code>
project, which lives as a sub-directory of the more general,
language-agnostic <a href="https://github.com/irworkshop/accountability_datacleaning"><code>irworkshop/accountability_datacleaning</code></a>
GitHub repository.</p>
<p>The <code>R_campfin</code> project uses the <a href="https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects">RStudio
projects</a> feature and should be run as such. The project also uses
the dynamic <code>here::here()</code> tool for file paths relative to
<em>your</em> machine.</p>
<div class="sourceCode" id="cb2"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb2-1"><a href="#cb2-1" aria-hidden="true" tabindex="-1"></a><span class="co"># where does this document knit?</span></span>
<span id="cb2-2"><a href="#cb2-2" aria-hidden="true" tabindex="-1"></a>here<span class="sc">::</span><span class="fu">here</span>()</span>
<span id="cb2-3"><a href="#cb2-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] &quot;C:/Users/jla/Documents/jen_transition/AU_CLASSES/AUFALL22/rdata&quot;</span></span></code></pre></div>
<h2 id="data">Data</h2>
<p>Kentucky contracts data were obtained via Public Records request by
Nami Hijikata.</p>
<h2 id="read">Read</h2>
<div class="sourceCode" id="cb3"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb3-1"><a href="#cb3-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> <span class="fu">read.csv</span>(<span class="st">&quot;KY_Contracts.csv&quot;</span>)</span>
<span id="cb3-2"><a href="#cb3-2" aria-hidden="true" tabindex="-1"></a><span class="fu">head</span>(kyc)</span>
<span id="cb3-3"><a href="#cb3-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 6 × 21</span></span>
<span id="cb3-4"><a href="#cb3-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   Link  ContractIde…¹ Class…² Class…³ Cited…⁴ Contr…⁵ DocId Branc…⁶ CabName DeptN…⁷ Reaso…⁸ Start…⁹</span></span>
<span id="cb3-5"><a href="#cb3-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   &lt;chr&gt; &lt;chr&gt;         &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt; &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;  </span></span>
<span id="cb3-6"><a href="#cb3-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 1 NULL  4A5172AE-F58… ENGINE… 925     Compet… MA      2100… Judici… NULL    Judici… NULL    7/1/20…</span></span>
<span id="cb3-7"><a href="#cb3-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 2 NULL  C0FCAC3F-7C4… NULL    NULL    Memora… PO      1900… Judici… NULL    Judici… Accoun… 7/1/20…</span></span>
<span id="cb3-8"><a href="#cb3-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 3 NULL  E6143871-8DC… COMPUT… 209     Small … PO      2200… Execut… Educat… Depart… NULL    10/1/2…</span></span>
<span id="cb3-9"><a href="#cb3-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 4 NULL  55A241F0-821… NULL    NULL    Memora… PO      1900… Judici… NULL    Judici… Accoun… 7/1/20…</span></span>
<span id="cb3-10"><a href="#cb3-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 5 NULL  289B18CE-405… MISCEL… 961     Memora… PO      1900… Judici… NULL    Judici… NULL    7/1/20…</span></span>
<span id="cb3-11"><a href="#cb3-11" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 6 NULL  434BAECA-C3E… NULL    NULL    Commer… PO      2200… Execut… Touris… Kentuc… NULL    8/17/2…</span></span>
<span id="cb3-12"><a href="#cb3-12" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # … with 9 more variables: EndDate &lt;chr&gt;, VendCustId &lt;chr&gt;, VendName &lt;chr&gt;, VendAddress1 &lt;chr&gt;,</span></span>
<span id="cb3-13"><a href="#cb3-13" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   VendCity &lt;chr&gt;, VendState &lt;chr&gt;, VendZip &lt;chr&gt;, ProcurementName &lt;chr&gt;, ContractAmount &lt;dbl&gt;,</span></span>
<span id="cb3-14"><a href="#cb3-14" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   and abbreviated variable names ¹​ContractIdentifier, ²​Classification, ³​ClassificationCode,</span></span>
<span id="cb3-15"><a href="#cb3-15" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   ⁴​CitedAuthDescription, ⁵​ContractTypeCode, ⁶​BranchName, ⁷​DeptName, ⁸​ReasonModification,</span></span>
<span id="cb3-16"><a href="#cb3-16" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   ⁹​StartDate</span></span></code></pre></div>
<p>There are two dates in the file. We used the year from start date as
a separate year column.</p>
<h3 id="dates">Dates</h3>
<div class="sourceCode" id="cb4"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb4-1"><a href="#cb4-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> <span class="fu">mutate</span>(kyc, <span class="at">year =</span> <span class="fu">stri_sub</span>(StartDate,<span class="sc">-</span><span class="dv">4</span>))</span></code></pre></div>
<div class="sourceCode" id="cb5"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb5-1"><a href="#cb5-1" aria-hidden="true" tabindex="-1"></a><span class="fu">prop_na</span>(kyc<span class="sc">$</span>StartDate)</span>
<span id="cb5-2"><a href="#cb5-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] 0</span></span>
<span id="cb5-3"><a href="#cb5-3" aria-hidden="true" tabindex="-1"></a><span class="fu">min</span>(kyc<span class="sc">$</span>date, <span class="at">na.rm =</span> <span class="cn">TRUE</span>)</span>
<span id="cb5-4"><a href="#cb5-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] Inf</span></span>
<span id="cb5-5"><a href="#cb5-5" aria-hidden="true" tabindex="-1"></a><span class="fu">sum</span>(kyc<span class="sc">$</span>year <span class="sc">&lt;</span> <span class="dv">2000</span>, <span class="at">na.rm =</span> <span class="cn">TRUE</span>)</span>
<span id="cb5-6"><a href="#cb5-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] 0</span></span>
<span id="cb5-7"><a href="#cb5-7" aria-hidden="true" tabindex="-1"></a><span class="fu">max</span>(kyc<span class="sc">$</span>date, <span class="at">na.rm =</span> <span class="cn">TRUE</span>)</span>
<span id="cb5-8"><a href="#cb5-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] -Inf</span></span>
<span id="cb5-9"><a href="#cb5-9" aria-hidden="true" tabindex="-1"></a><span class="fu">sum</span>(kyc<span class="sc">$</span>date <span class="sc">&gt;</span> <span class="fu">today</span>(), <span class="at">na.rm =</span> <span class="cn">TRUE</span>)</span>
<span id="cb5-10"><a href="#cb5-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] 0</span></span>
<span id="cb5-11"><a href="#cb5-11" aria-hidden="true" tabindex="-1"></a>kyc<span class="sc">$</span>year <span class="ot">&lt;-</span> <span class="fu">na_if</span>(kyc<span class="sc">$</span>year, <span class="dv">9999</span>)</span></code></pre></div>

<p>Contracts have both <code>StartDate</code> and <code>EndDate</code>;
we combine these two variables into a single date to represent the
transaction. We also make the headers snake case. Replace the word NULL
with actually NAs. Combine cab_name and dept_name.</p>
<div class="sourceCode" id="cb6"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb6-1"><a href="#cb6-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb6-2"><a href="#cb6-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">clean_names</span>(<span class="st">&quot;snake&quot;</span>) <span class="sc">%&gt;%</span> </span>
<span id="cb6-3"><a href="#cb6-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">replace</span>(kyc <span class="sc">==</span> <span class="st">&quot;NULL&quot;</span>, <span class="cn">NA</span>) <span class="sc">%&gt;%</span> </span>
<span id="cb6-4"><a href="#cb6-4" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(<span class="at">date =</span> <span class="fu">paste0</span>(start_date,<span class="st">&quot; to &quot;</span>, end_date)) <span class="sc">%&gt;%</span> </span>
<span id="cb6-5"><a href="#cb6-5" aria-hidden="true" tabindex="-1"></a>  <span class="fu">unite</span>(<span class="st">&quot;full_agency&quot;</span>, <span class="fu">c</span>(cab_name, dept_name), <span class="at">sep=</span><span class="st">&quot;, &quot;</span>, <span class="at">remove =</span> <span class="cn">FALSE</span>, <span class="at">na.rm =</span> <span class="cn">TRUE</span>) <span class="sc">%&gt;%</span> </span>
<span id="cb6-6"><a href="#cb6-6" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(<span class="at">vend_city=</span><span class="fu">toupper</span>(vend_city))</span></code></pre></div>
<h2 id="explore">Explore</h2>
<div class="sourceCode" id="cb7"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb7-1"><a href="#cb7-1" aria-hidden="true" tabindex="-1"></a><span class="fu">glimpse</span>(kyc)</span>
<span id="cb7-2"><a href="#cb7-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; Rows: 50,771</span></span>
<span id="cb7-3"><a href="#cb7-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; Columns: 24</span></span>
<span id="cb7-4"><a href="#cb7-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ link                   &lt;chr&gt; NA, NA, NA, NA, NA, NA, &quot;https://secure2.kentucky.gov/Transparency…</span></span>
<span id="cb7-5"><a href="#cb7-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ contract_identifier    &lt;chr&gt; &quot;4A5172AE-F580-4254-B59B-00008DE3E276&quot;, &quot;C0FCAC3F-7C48-4439-BCE9-0…</span></span>
<span id="cb7-6"><a href="#cb7-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ classification         &lt;chr&gt; &quot;ENGINEERING SERVICES, PROFESSIONAL&quot;, NA, &quot;COMPUTER SOFTWARE FOR M…</span></span>
<span id="cb7-7"><a href="#cb7-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ classification_code    &lt;chr&gt; &quot;925&quot;, NA, &quot;209&quot;, NA, &quot;961&quot;, NA, &quot;924&quot;, &quot;918&quot;, &quot;912&quot;, &quot;961&quot;, &quot;924&quot;…</span></span>
<span id="cb7-8"><a href="#cb7-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ cited_auth_description &lt;chr&gt; &quot;Competitive Sealed Bidding&quot;, &quot;Memorandum of Agreement&quot;, &quot;Small Pu…</span></span>
<span id="cb7-9"><a href="#cb7-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ contract_type_code     &lt;chr&gt; &quot;MA&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, …</span></span>
<span id="cb7-10"><a href="#cb7-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ doc_id                 &lt;chr&gt; &quot;2100001036&quot;, &quot;1900001843&quot;, &quot;2200001377&quot;, &quot;1900001881&quot;, &quot;190000189…</span></span>
<span id="cb7-11"><a href="#cb7-11" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ branch_name            &lt;chr&gt; &quot;Judicial&quot;, &quot;Judicial&quot;, &quot;Executive&quot;, &quot;Judicial&quot;, &quot;Judicial&quot;, &quot;Exec…</span></span>
<span id="cb7-12"><a href="#cb7-12" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ full_agency            &lt;chr&gt; &quot;Judicial Department&quot;, &quot;Judicial Department&quot;, &quot;Education &amp; Workfor…</span></span>
<span id="cb7-13"><a href="#cb7-13" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ cab_name               &lt;chr&gt; NA, NA, &quot;Education &amp; Workforce Development Cabinet&quot;, NA, NA, &quot;Tour…</span></span>
<span id="cb7-14"><a href="#cb7-14" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ dept_name              &lt;chr&gt; &quot;Judicial Department&quot;, &quot;Judicial Department&quot;, &quot;Department For Work…</span></span>
<span id="cb7-15"><a href="#cb7-15" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ reason_modification    &lt;chr&gt; NA, &quot;Accounting lines were not broken out by county.&quot;, NA, &quot;Accoun…</span></span>
<span id="cb7-16"><a href="#cb7-16" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ start_date             &lt;chr&gt; &quot;7/1/2021&quot;, &quot;7/1/2018&quot;, &quot;10/1/2019&quot;, &quot;7/1/2018&quot;, &quot;7/1/2018&quot;, &quot;8/17…</span></span>
<span id="cb7-17"><a href="#cb7-17" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ end_date               &lt;chr&gt; &quot;6/30/2022&quot;, &quot;6/30/2019&quot;, &quot;9/30/2020&quot;, &quot;6/30/2019&quot;, &quot;6/30/2019&quot;, &quot;…</span></span>
<span id="cb7-18"><a href="#cb7-18" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_cust_id           &lt;chr&gt; &quot;KY0023046&quot;, &quot;KY0036004&quot;, &quot;KY0028928&quot;, &quot;KY0018713&quot;, &quot;KY0028291&quot;, &quot;…</span></span>
<span id="cb7-19"><a href="#cb7-19" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_name              &lt;chr&gt; &quot;BRANDSTETTER CARROLL INC&quot;, &quot;BLUEGRASS REGIONAL MH MR&quot;, &quot;STATE OF …</span></span>
<span id="cb7-20"><a href="#cb7-20" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_address1          &lt;chr&gt; &quot;2360 CHAUVIN DR&quot;, &quot;1351 NEWTOWN PIKE&quot;, &quot;EUGENE T MAHONEY STATE PA…</span></span>
<span id="cb7-21"><a href="#cb7-21" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_city              &lt;chr&gt; &quot;LEXINGTON&quot;, &quot;LEXINGTON&quot;, &quot;ASHLAND&quot;, &quot;LOUISVILLE&quot;, &quot;CORBIN&quot;, &quot;HARR…</span></span>
<span id="cb7-22"><a href="#cb7-22" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_state             &lt;chr&gt; &quot;KY&quot;, &quot;KY&quot;, &quot;NE&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, …</span></span>
<span id="cb7-23"><a href="#cb7-23" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_zip               &lt;chr&gt; &quot;40517&quot;, &quot;40511-1277&quot;, &quot;68003&quot;, &quot;40223&quot;, &quot;40702&quot;, &quot;40330&quot;, &quot;42633&quot;…</span></span>
<span id="cb7-24"><a href="#cb7-24" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ procurement_name       &lt;chr&gt; &quot;Standard Goods and Services&quot;, &quot;Memorandum of Agreement&quot;, &quot;Standar…</span></span>
<span id="cb7-25"><a href="#cb7-25" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ contract_amount        &lt;dbl&gt; 150000.00, 216000.00, 191.67, 67000.00, 10000.00, 75000.00, 8200.0…</span></span>
<span id="cb7-26"><a href="#cb7-26" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ year                   &lt;chr&gt; &quot;2021&quot;, &quot;2018&quot;, &quot;2019&quot;, &quot;2018&quot;, &quot;2018&quot;, &quot;2021&quot;, &quot;2019&quot;, &quot;2021&quot;, &quot;2…</span></span>
<span id="cb7-27"><a href="#cb7-27" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ date                   &lt;chr&gt; &quot;7/1/2021 to 6/30/2022&quot;, &quot;7/1/2018 to 6/30/2019&quot;, &quot;10/1/2019 to 9/…</span></span>
<span id="cb7-28"><a href="#cb7-28" aria-hidden="true" tabindex="-1"></a><span class="fu">tail</span>(kyc)</span>
<span id="cb7-29"><a href="#cb7-29" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 6 × 24</span></span>
<span id="cb7-30"><a href="#cb7-30" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   link       contr…¹ class…² class…³ cited…⁴ contr…⁵ doc_id branc…⁶ full_…⁷ cab_n…⁸ dept_…⁹ reaso…˟</span></span>
<span id="cb7-31"><a href="#cb7-31" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   &lt;chr&gt;      &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;  &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;   &lt;chr&gt;  </span></span>
<span id="cb7-32"><a href="#cb7-32" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 1 &lt;NA&gt;       318535… &lt;NA&gt;    &lt;NA&gt;    Memora… PO      19000… Judici… Judici… &lt;NA&gt;    Judici… Accoun…</span></span>
<span id="cb7-33"><a href="#cb7-33" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 2 &lt;NA&gt;       483E15… MISCEL… 961     Memora… PO      19000… Judici… Judici… &lt;NA&gt;    Judici… &lt;NA&gt;   </span></span>
<span id="cb7-34"><a href="#cb7-34" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 3 &lt;NA&gt;       BF8D43… RENTAL… 981     Emerge… PO      23000… Execut… Cabine… Cabine… Depart… &lt;NA&gt;   </span></span>
<span id="cb7-35"><a href="#cb7-35" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 4 &lt;NA&gt;       CC826E… &lt;NA&gt;    &lt;NA&gt;    Memora… PO      19000… Judici… Judici… &lt;NA&gt;    Judici… &lt;NA&gt;   </span></span>
<span id="cb7-36"><a href="#cb7-36" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 5 https://s… 8EE4E5… &lt;NA&gt;    &lt;NA&gt;    Memora… PO      19000… Judici… Judici… &lt;NA&gt;    Judici… &lt;NA&gt;   </span></span>
<span id="cb7-37"><a href="#cb7-37" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 6 &lt;NA&gt;       396B1C… &lt;NA&gt;    &lt;NA&gt;    Memora… PO      19000… Judici… Judici… &lt;NA&gt;    Judici… Accoun…</span></span>
<span id="cb7-38"><a href="#cb7-38" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # … with 12 more variables: start_date &lt;chr&gt;, end_date &lt;chr&gt;, vend_cust_id &lt;chr&gt;, vend_name &lt;chr&gt;,</span></span>
<span id="cb7-39"><a href="#cb7-39" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   vend_address1 &lt;chr&gt;, vend_city &lt;chr&gt;, vend_state &lt;chr&gt;, vend_zip &lt;chr&gt;,</span></span>
<span id="cb7-40"><a href="#cb7-40" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   procurement_name &lt;chr&gt;, contract_amount &lt;dbl&gt;, year &lt;chr&gt;, date &lt;chr&gt;, and abbreviated</span></span>
<span id="cb7-41"><a href="#cb7-41" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   variable names ¹​contract_identifier, ²​classification, ³​classification_code,</span></span>
<span id="cb7-42"><a href="#cb7-42" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   ⁴​cited_auth_description, ⁵​contract_type_code, ⁶​branch_name, ⁷​full_agency, ⁸​cab_name,</span></span>
<span id="cb7-43"><a href="#cb7-43" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; #   ⁹​dept_name, ˟​reason_modification</span></span></code></pre></div>
<h3 id="missing">Missing</h3>
<p>If we count the number of missing values per column, we can see a lot
of the values from the columns found only in one type of file are
missing.</p>
<div class="sourceCode" id="cb8"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb8-1"><a href="#cb8-1" aria-hidden="true" tabindex="-1"></a><span class="fu">col_stats</span>(kyc, count_na)</span>
<span id="cb8-2"><a href="#cb8-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 24 × 4</span></span>
<span id="cb8-3"><a href="#cb8-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;    col                    class     n        p</span></span>
<span id="cb8-4"><a href="#cb8-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;    &lt;chr&gt;                  &lt;chr&gt; &lt;int&gt;    &lt;dbl&gt;</span></span>
<span id="cb8-5"><a href="#cb8-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  1 link                   &lt;chr&gt; 38607 0.760   </span></span>
<span id="cb8-6"><a href="#cb8-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  2 contract_identifier    &lt;chr&gt;     0 0       </span></span>
<span id="cb8-7"><a href="#cb8-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  3 classification         &lt;chr&gt; 17130 0.337   </span></span>
<span id="cb8-8"><a href="#cb8-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  4 classification_code    &lt;chr&gt; 17130 0.337   </span></span>
<span id="cb8-9"><a href="#cb8-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  5 cited_auth_description &lt;chr&gt;     0 0       </span></span>
<span id="cb8-10"><a href="#cb8-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  6 contract_type_code     &lt;chr&gt;     0 0       </span></span>
<span id="cb8-11"><a href="#cb8-11" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  7 doc_id                 &lt;chr&gt;     0 0       </span></span>
<span id="cb8-12"><a href="#cb8-12" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  8 branch_name            &lt;chr&gt;     0 0       </span></span>
<span id="cb8-13"><a href="#cb8-13" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  9 full_agency            &lt;chr&gt;     0 0       </span></span>
<span id="cb8-14"><a href="#cb8-14" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 10 cab_name               &lt;chr&gt; 24918 0.491   </span></span>
<span id="cb8-15"><a href="#cb8-15" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 11 dept_name              &lt;chr&gt;     0 0       </span></span>
<span id="cb8-16"><a href="#cb8-16" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 12 reason_modification    &lt;chr&gt; 30930 0.609   </span></span>
<span id="cb8-17"><a href="#cb8-17" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 13 start_date             &lt;chr&gt;     0 0       </span></span>
<span id="cb8-18"><a href="#cb8-18" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 14 end_date               &lt;chr&gt;     0 0       </span></span>
<span id="cb8-19"><a href="#cb8-19" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 15 vend_cust_id           &lt;chr&gt;     0 0       </span></span>
<span id="cb8-20"><a href="#cb8-20" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 16 vend_name              &lt;chr&gt;     0 0       </span></span>
<span id="cb8-21"><a href="#cb8-21" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 17 vend_address1          &lt;chr&gt;     0 0       </span></span>
<span id="cb8-22"><a href="#cb8-22" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 18 vend_city              &lt;chr&gt;     0 0       </span></span>
<span id="cb8-23"><a href="#cb8-23" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 19 vend_state             &lt;chr&gt;    10 0.000197</span></span>
<span id="cb8-24"><a href="#cb8-24" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 20 vend_zip               &lt;chr&gt;    14 0.000276</span></span>
<span id="cb8-25"><a href="#cb8-25" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 21 procurement_name       &lt;chr&gt;     0 0       </span></span>
<span id="cb8-26"><a href="#cb8-26" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 22 contract_amount        &lt;dbl&gt;     0 0       </span></span>
<span id="cb8-27"><a href="#cb8-27" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 23 year                   &lt;chr&gt;     0 0       </span></span>
<span id="cb8-28"><a href="#cb8-28" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 24 date                   &lt;chr&gt;     0 0</span></span></code></pre></div>
<h3 id="duplicates">Duplicates</h3>
<p>There are no duplicate records in this database.</p>
<div class="sourceCode" id="cb9"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb9-1"><a href="#cb9-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> <span class="fu">flag_dupes</span>(kyc, <span class="fu">everything</span>())</span>
<span id="cb9-2"><a href="#cb9-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; Warning in flag_dupes(kyc, everything()): no duplicate rows, column not created</span></span></code></pre></div>
<h3 id="categorical">Categorical</h3>
<div class="sourceCode" id="cb10"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb10-1"><a href="#cb10-1" aria-hidden="true" tabindex="-1"></a><span class="fu">col_stats</span>(kyc, n_distinct)</span>
<span id="cb10-2"><a href="#cb10-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 24 × 4</span></span>
<span id="cb10-3"><a href="#cb10-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;    col                    class     n         p</span></span>
<span id="cb10-4"><a href="#cb10-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;    &lt;chr&gt;                  &lt;chr&gt; &lt;int&gt;     &lt;dbl&gt;</span></span>
<span id="cb10-5"><a href="#cb10-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  1 link                   &lt;chr&gt; 11840 0.233    </span></span>
<span id="cb10-6"><a href="#cb10-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  2 contract_identifier    &lt;chr&gt; 49875 0.982    </span></span>
<span id="cb10-7"><a href="#cb10-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  3 classification         &lt;chr&gt;   202 0.00398  </span></span>
<span id="cb10-8"><a href="#cb10-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  4 classification_code    &lt;chr&gt;   207 0.00408  </span></span>
<span id="cb10-9"><a href="#cb10-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  5 cited_auth_description &lt;chr&gt;   117 0.00230  </span></span>
<span id="cb10-10"><a href="#cb10-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  6 contract_type_code     &lt;chr&gt;     2 0.0000394</span></span>
<span id="cb10-11"><a href="#cb10-11" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  7 doc_id                 &lt;chr&gt; 19819 0.390    </span></span>
<span id="cb10-12"><a href="#cb10-12" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  8 branch_name            &lt;chr&gt;     2 0.0000394</span></span>
<span id="cb10-13"><a href="#cb10-13" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  9 full_agency            &lt;chr&gt;   147 0.00290  </span></span>
<span id="cb10-14"><a href="#cb10-14" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 10 cab_name               &lt;chr&gt;    14 0.000276 </span></span>
<span id="cb10-15"><a href="#cb10-15" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 11 dept_name              &lt;chr&gt;   144 0.00284  </span></span>
<span id="cb10-16"><a href="#cb10-16" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 12 reason_modification    &lt;chr&gt;  4703 0.0926   </span></span>
<span id="cb10-17"><a href="#cb10-17" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 13 start_date             &lt;chr&gt;  1436 0.0283   </span></span>
<span id="cb10-18"><a href="#cb10-18" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 14 end_date               &lt;chr&gt;  1427 0.0281   </span></span>
<span id="cb10-19"><a href="#cb10-19" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 15 vend_cust_id           &lt;chr&gt;  6463 0.127    </span></span>
<span id="cb10-20"><a href="#cb10-20" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 16 vend_name              &lt;chr&gt;  6502 0.128    </span></span>
<span id="cb10-21"><a href="#cb10-21" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 17 vend_address1          &lt;chr&gt;  6721 0.132    </span></span>
<span id="cb10-22"><a href="#cb10-22" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 18 vend_city              &lt;chr&gt;  1286 0.0253   </span></span>
<span id="cb10-23"><a href="#cb10-23" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 19 vend_state             &lt;chr&gt;    57 0.00112  </span></span>
<span id="cb10-24"><a href="#cb10-24" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 20 vend_zip               &lt;chr&gt;  2460 0.0485   </span></span>
<span id="cb10-25"><a href="#cb10-25" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 21 procurement_name       &lt;chr&gt;    14 0.000276 </span></span>
<span id="cb10-26"><a href="#cb10-26" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 22 contract_amount        &lt;dbl&gt; 12150 0.239    </span></span>
<span id="cb10-27"><a href="#cb10-27" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 23 year                   &lt;chr&gt;     5 0.0000985</span></span>
<span id="cb10-28"><a href="#cb10-28" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 24 date                   &lt;chr&gt;  7647 0.151</span></span></code></pre></div>
<h3 id="amounts">Amounts</h3>
<div class="sourceCode" id="cb13"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb13-1"><a href="#cb13-1" aria-hidden="true" tabindex="-1"></a><span class="fu">mean</span>(kyc<span class="sc">$</span>contract_amount)</span>
<span id="cb13-2"><a href="#cb13-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] 264228.9</span></span>
<span id="cb13-3"><a href="#cb13-3" aria-hidden="true" tabindex="-1"></a><span class="fu">noquote</span>(<span class="fu">map_chr</span>(<span class="fu">summary</span>(kyc<span class="sc">$</span>contract_amount), dollar))</span>
<span id="cb13-4"><a href="#cb13-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. </span></span>
<span id="cb13-5"><a href="#cb13-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;           $0    $7,863.70      $25,000     $264,229     $113,000 $311,589,050</span></span></code></pre></div>
<h2 id="wrangle">Wrangle</h2>
<p>To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding
<code>campfin::normal_*()</code> functions are tailor made to facilitate
this process.</p>
<h3 id="address">Address</h3>
<p>For the street <code>address</code> variable, the
<code>campfin::normal_address()</code> function will force consistence
case, remove punctuation, and abbreviate official USPS suffixes.</p>
<div class="sourceCode" id="cb14"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb14-1"><a href="#cb14-1" aria-hidden="true" tabindex="-1"></a>addr_norm <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb14-2"><a href="#cb14-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">distinct</span>(vend_address1) <span class="sc">%&gt;%</span> </span>
<span id="cb14-3"><a href="#cb14-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb14-4"><a href="#cb14-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">address_norm =</span> <span class="fu">normal_address</span>(</span>
<span id="cb14-5"><a href="#cb14-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">address =</span> vend_address1,</span>
<span id="cb14-6"><a href="#cb14-6" aria-hidden="true" tabindex="-1"></a>      <span class="at">abbs =</span> usps_street,</span>
<span id="cb14-7"><a href="#cb14-7" aria-hidden="true" tabindex="-1"></a>      <span class="at">na_rep =</span> <span class="cn">TRUE</span></span>
<span id="cb14-8"><a href="#cb14-8" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb14-9"><a href="#cb14-9" aria-hidden="true" tabindex="-1"></a>  )</span></code></pre></div>
<div class="sourceCode" id="cb15"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb15-1"><a href="#cb15-1" aria-hidden="true" tabindex="-1"></a>addr_norm</span>
<span id="cb15-2"><a href="#cb15-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 6,721 × 2</span></span>
<span id="cb15-3"><a href="#cb15-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;    vend_address1                   address_norm                   </span></span>
<span id="cb15-4"><a href="#cb15-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;    &lt;chr&gt;                           &lt;chr&gt;                          </span></span>
<span id="cb15-5"><a href="#cb15-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  1 2360 CHAUVIN DR                 2360 CHAUVIN DR                </span></span>
<span id="cb15-6"><a href="#cb15-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  2 1351 NEWTOWN PIKE               1351 NEWTOWN PIKE              </span></span>
<span id="cb15-7"><a href="#cb15-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  3 EUGENE T MAHONEY STATE PARK     EUGENE T MAHONEY STATE PARK    </span></span>
<span id="cb15-8"><a href="#cb15-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  4 10101 LINN STATION RD SUITE 600 10101 LINN STATION RD SUITE 600</span></span>
<span id="cb15-9"><a href="#cb15-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  5 PO BOX 568                      PO BOX 568                     </span></span>
<span id="cb15-10"><a href="#cb15-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  6 1015 Danville Road              1015 DANVILLE RD               </span></span>
<span id="cb15-11"><a href="#cb15-11" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  7 134 COLLEGE ST                  134 COLLEGE ST                 </span></span>
<span id="cb15-12"><a href="#cb15-12" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  8 3332 NEWBURG RD                 3332 NEWBURG RD                </span></span>
<span id="cb15-13"><a href="#cb15-13" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;  9 PO BOX 4157                     PO BOX 4157                    </span></span>
<span id="cb15-14"><a href="#cb15-14" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 10 9226 MAIN STREET                9226 MAIN ST                   </span></span>
<span id="cb15-15"><a href="#cb15-15" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # … with 6,711 more rows</span></span></code></pre></div>
<div class="sourceCode" id="cb16"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb16-1"><a href="#cb16-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> <span class="fu">left_join</span>(kyc, addr_norm, <span class="at">by =</span> <span class="st">&quot;vend_address1&quot;</span>)</span></code></pre></div>
<h3 id="zip">ZIP</h3>
<p>For ZIP codes, the <code>campfin::normal_zip()</code> function will
attempt to create valid <em>five</em> digit codes by removing the ZIP+4
suffix and returning leading zeroes dropped by other programs like
Microsoft Excel.</p>
<div class="sourceCode" id="cb17"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb17-1"><a href="#cb17-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb17-2"><a href="#cb17-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb17-3"><a href="#cb17-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">zip_norm =</span> <span class="fu">normal_zip</span>(</span>
<span id="cb17-4"><a href="#cb17-4" aria-hidden="true" tabindex="-1"></a>      <span class="at">zip =</span> vend_zip,</span>
<span id="cb17-5"><a href="#cb17-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">na_rep =</span> <span class="cn">TRUE</span></span>
<span id="cb17-6"><a href="#cb17-6" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb17-7"><a href="#cb17-7" aria-hidden="true" tabindex="-1"></a>  )</span></code></pre></div>
<div class="sourceCode" id="cb18"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb18-1"><a href="#cb18-1" aria-hidden="true" tabindex="-1"></a><span class="fu">progress_table</span>(</span>
<span id="cb18-2"><a href="#cb18-2" aria-hidden="true" tabindex="-1"></a>  kyc<span class="sc">$</span>vend_zip,</span>
<span id="cb18-3"><a href="#cb18-3" aria-hidden="true" tabindex="-1"></a>  kyc<span class="sc">$</span>zip_norm,</span>
<span id="cb18-4"><a href="#cb18-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">compare =</span> valid_zip</span>
<span id="cb18-5"><a href="#cb18-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb18-6"><a href="#cb18-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 2 × 6</span></span>
<span id="cb18-7"><a href="#cb18-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   stage        prop_in n_distinct  prop_na n_out n_diff</span></span>
<span id="cb18-8"><a href="#cb18-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   &lt;chr&gt;          &lt;dbl&gt;      &lt;dbl&gt;    &lt;dbl&gt; &lt;dbl&gt;  &lt;dbl&gt;</span></span>
<span id="cb18-9"><a href="#cb18-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 1 kyc$vend_zip   0.798       2460 0.000276 10232    822</span></span>
<span id="cb18-10"><a href="#cb18-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 2 kyc$zip_norm   0.988       1944 0.000315   588    148</span></span></code></pre></div>
<h3 id="state">State</h3>
<p>Valid two digit state abbreviations can be made using the
<code>campfin::normal_state()</code> function.</p>
<div class="sourceCode" id="cb19"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb19-1"><a href="#cb19-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb19-2"><a href="#cb19-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb19-3"><a href="#cb19-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">state_norm =</span> <span class="fu">normal_state</span>(</span>
<span id="cb19-4"><a href="#cb19-4" aria-hidden="true" tabindex="-1"></a>      <span class="at">state =</span> vend_state,</span>
<span id="cb19-5"><a href="#cb19-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">abbreviate =</span> <span class="cn">TRUE</span>,</span>
<span id="cb19-6"><a href="#cb19-6" aria-hidden="true" tabindex="-1"></a>      <span class="at">na_rep =</span> <span class="cn">TRUE</span>,</span>
<span id="cb19-7"><a href="#cb19-7" aria-hidden="true" tabindex="-1"></a>      <span class="at">valid =</span> valid_state</span>
<span id="cb19-8"><a href="#cb19-8" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb19-9"><a href="#cb19-9" aria-hidden="true" tabindex="-1"></a>  )</span></code></pre></div>
<div class="sourceCode" id="cb20"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb20-1"><a href="#cb20-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="sc">%&gt;%</span> </span>
<span id="cb20-2"><a href="#cb20-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(vend_state <span class="sc">!=</span> state_norm) <span class="sc">%&gt;%</span> </span>
<span id="cb20-3"><a href="#cb20-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">count</span>(vend_state, state_norm, <span class="at">sort =</span> <span class="cn">TRUE</span>)</span>
<span id="cb20-4"><a href="#cb20-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 0 × 3</span></span>
<span id="cb20-5"><a href="#cb20-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # … with 3 variables: vend_state &lt;chr&gt;, state_norm &lt;chr&gt;, n &lt;int&gt;</span></span></code></pre></div>
<div class="sourceCode" id="cb21"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb21-1"><a href="#cb21-1" aria-hidden="true" tabindex="-1"></a><span class="fu">progress_table</span>(</span>
<span id="cb21-2"><a href="#cb21-2" aria-hidden="true" tabindex="-1"></a>  kyc<span class="sc">$</span>vend_state,</span>
<span id="cb21-3"><a href="#cb21-3" aria-hidden="true" tabindex="-1"></a>  kyc<span class="sc">$</span>state_norm,</span>
<span id="cb21-4"><a href="#cb21-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">compare =</span> valid_state</span>
<span id="cb21-5"><a href="#cb21-5" aria-hidden="true" tabindex="-1"></a>)</span>
<span id="cb21-6"><a href="#cb21-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; # A tibble: 2 × 6</span></span>
<span id="cb21-7"><a href="#cb21-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   stage          prop_in n_distinct  prop_na n_out n_diff</span></span>
<span id="cb21-8"><a href="#cb21-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt;   &lt;chr&gt;            &lt;dbl&gt;      &lt;dbl&gt;    &lt;dbl&gt; &lt;dbl&gt;  &lt;dbl&gt;</span></span>
<span id="cb21-9"><a href="#cb21-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 1 kyc$vend_state   0.999         57 0.000197    37      8</span></span>
<span id="cb21-10"><a href="#cb21-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 2 kyc$state_norm   1             50 0.000926     0      1</span></span></code></pre></div>
<h3 id="city">City</h3>
<p>Cities are the most difficult geographic variable to normalize,
simply due to the wide variety of valid cities and formats.</p>
<h4 id="normal">Normal</h4>
<p>The <code>campfin::normal_city()</code> function is a good start,
again converting case, removing punctuation, but <em>expanding</em> USPS
abbreviations. We can also remove <code>invalid_city</code> values.</p>
<div class="sourceCode" id="cb22"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb22-1"><a href="#cb22-1" aria-hidden="true" tabindex="-1"></a>norm_city <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb22-2"><a href="#cb22-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">distinct</span>(vend_city, state_norm, zip_norm) <span class="sc">%&gt;%</span> </span>
<span id="cb22-3"><a href="#cb22-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb22-4"><a href="#cb22-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">city_norm =</span> <span class="fu">normal_city</span>(</span>
<span id="cb22-5"><a href="#cb22-5" aria-hidden="true" tabindex="-1"></a>      <span class="at">city =</span> vend_city, </span>
<span id="cb22-6"><a href="#cb22-6" aria-hidden="true" tabindex="-1"></a>      <span class="at">abbs =</span> usps_city,</span>
<span id="cb22-7"><a href="#cb22-7" aria-hidden="true" tabindex="-1"></a>      <span class="at">states =</span> <span class="fu">c</span>(<span class="st">&quot;KY&quot;</span>, <span class="st">&quot;DC&quot;</span>, <span class="st">&quot;KENTUCKY&quot;</span>),</span>
<span id="cb22-8"><a href="#cb22-8" aria-hidden="true" tabindex="-1"></a>      <span class="at">na =</span> invalid_city,</span>
<span id="cb22-9"><a href="#cb22-9" aria-hidden="true" tabindex="-1"></a>      <span class="at">na_rep =</span> <span class="cn">TRUE</span></span>
<span id="cb22-10"><a href="#cb22-10" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb22-11"><a href="#cb22-11" aria-hidden="true" tabindex="-1"></a>  )</span></code></pre></div>
<h4 id="swap">Swap</h4>
<p>We can further improve normalization by comparing our normalized
value against the <em>expected</em> value for that record’s state
abbreviation and ZIP code. If the normalized value is either an
abbreviation for or very similar to the expected value, we can
confidently swap those two.</p>
<div class="sourceCode" id="cb23"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb23-1"><a href="#cb23-1" aria-hidden="true" tabindex="-1"></a>norm_city <span class="ot">&lt;-</span> norm_city <span class="sc">%&gt;%</span> </span>
<span id="cb23-2"><a href="#cb23-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rename</span>(<span class="at">city_raw =</span> vend_city) <span class="sc">%&gt;%</span> </span>
<span id="cb23-3"><a href="#cb23-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">left_join</span>(</span>
<span id="cb23-4"><a href="#cb23-4" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> zipcodes,</span>
<span id="cb23-5"><a href="#cb23-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">by =</span> <span class="fu">c</span>(</span>
<span id="cb23-6"><a href="#cb23-6" aria-hidden="true" tabindex="-1"></a>      <span class="st">&quot;state_norm&quot;</span> <span class="ot">=</span> <span class="st">&quot;state&quot;</span>,</span>
<span id="cb23-7"><a href="#cb23-7" aria-hidden="true" tabindex="-1"></a>      <span class="st">&quot;zip_norm&quot;</span> <span class="ot">=</span> <span class="st">&quot;zip&quot;</span></span>
<span id="cb23-8"><a href="#cb23-8" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb23-9"><a href="#cb23-9" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">%&gt;%</span> </span>
<span id="cb23-10"><a href="#cb23-10" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rename</span>(<span class="at">city_match =</span> city) <span class="sc">%&gt;%</span> </span>
<span id="cb23-11"><a href="#cb23-11" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb23-12"><a href="#cb23-12" aria-hidden="true" tabindex="-1"></a>    <span class="at">match_abb =</span> <span class="fu">is_abbrev</span>(city_norm, city_match),</span>
<span id="cb23-13"><a href="#cb23-13" aria-hidden="true" tabindex="-1"></a>    <span class="at">match_dist =</span> <span class="fu">str_dist</span>(city_norm, city_match),</span>
<span id="cb23-14"><a href="#cb23-14" aria-hidden="true" tabindex="-1"></a>    <span class="at">city_swap =</span> <span class="fu">if_else</span>(</span>
<span id="cb23-15"><a href="#cb23-15" aria-hidden="true" tabindex="-1"></a>      <span class="at">condition =</span> <span class="sc">!</span><span class="fu">is.na</span>(match_dist) <span class="sc">&amp;</span> (match_abb <span class="sc">|</span> match_dist <span class="sc">==</span> <span class="dv">1</span>),</span>
<span id="cb23-16"><a href="#cb23-16" aria-hidden="true" tabindex="-1"></a>      <span class="at">true =</span> city_match,</span>
<span id="cb23-17"><a href="#cb23-17" aria-hidden="true" tabindex="-1"></a>      <span class="at">false =</span> city_norm</span>
<span id="cb23-18"><a href="#cb23-18" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb23-19"><a href="#cb23-19" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">%&gt;%</span> </span>
<span id="cb23-20"><a href="#cb23-20" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(</span>
<span id="cb23-21"><a href="#cb23-21" aria-hidden="true" tabindex="-1"></a>    <span class="sc">-</span>city_match,</span>
<span id="cb23-22"><a href="#cb23-22" aria-hidden="true" tabindex="-1"></a>    <span class="sc">-</span>match_dist,</span>
<span id="cb23-23"><a href="#cb23-23" aria-hidden="true" tabindex="-1"></a>    <span class="sc">-</span>match_abb</span>
<span id="cb23-24"><a href="#cb23-24" aria-hidden="true" tabindex="-1"></a>  )</span></code></pre></div>
<div class="sourceCode" id="cb24"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb24-1"><a href="#cb24-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> <span class="fu">left_join</span>(</span>
<span id="cb24-2"><a href="#cb24-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> kyc,</span>
<span id="cb24-3"><a href="#cb24-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">y =</span> norm_city,</span>
<span id="cb24-4"><a href="#cb24-4" aria-hidden="true" tabindex="-1"></a>  <span class="at">by =</span> <span class="fu">c</span>(</span>
<span id="cb24-5"><a href="#cb24-5" aria-hidden="true" tabindex="-1"></a>    <span class="st">&quot;vend_city&quot;</span> <span class="ot">=</span> <span class="st">&quot;city_raw&quot;</span>, </span>
<span id="cb24-6"><a href="#cb24-6" aria-hidden="true" tabindex="-1"></a>    <span class="st">&quot;state_norm&quot;</span>, </span>
<span id="cb24-7"><a href="#cb24-7" aria-hidden="true" tabindex="-1"></a>    <span class="st">&quot;zip_norm&quot;</span></span>
<span id="cb24-8"><a href="#cb24-8" aria-hidden="true" tabindex="-1"></a>  )</span>
<span id="cb24-9"><a href="#cb24-9" aria-hidden="true" tabindex="-1"></a>)</span></code></pre></div>
<h4 id="refine">Refine</h4>
<p>The <a href="https://openrefine.org/">OpenRefine</a> algorithms can
be used to group similar strings and replace the less common versions
with their most common counterpart. This can greatly reduce
inconsistency, but with low confidence; we will only keep any refined
strings that have a valid city/state/zip combination.</p>
<div class="sourceCode" id="cb25"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb25-1"><a href="#cb25-1" aria-hidden="true" tabindex="-1"></a>good_refine <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb25-2"><a href="#cb25-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(</span>
<span id="cb25-3"><a href="#cb25-3" aria-hidden="true" tabindex="-1"></a>    <span class="at">city_refine =</span> city_swap <span class="sc">%&gt;%</span> </span>
<span id="cb25-4"><a href="#cb25-4" aria-hidden="true" tabindex="-1"></a>      <span class="fu">key_collision_merge</span>() <span class="sc">%&gt;%</span> </span>
<span id="cb25-5"><a href="#cb25-5" aria-hidden="true" tabindex="-1"></a>      <span class="fu">n_gram_merge</span>(<span class="at">numgram =</span> <span class="dv">1</span>)</span>
<span id="cb25-6"><a href="#cb25-6" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">%&gt;%</span> </span>
<span id="cb25-7"><a href="#cb25-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">filter</span>(city_refine <span class="sc">!=</span> city_swap) <span class="sc">%&gt;%</span> </span>
<span id="cb25-8"><a href="#cb25-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">inner_join</span>(</span>
<span id="cb25-9"><a href="#cb25-9" aria-hidden="true" tabindex="-1"></a>    <span class="at">y =</span> zipcodes,</span>
<span id="cb25-10"><a href="#cb25-10" aria-hidden="true" tabindex="-1"></a>    <span class="at">by =</span> <span class="fu">c</span>(</span>
<span id="cb25-11"><a href="#cb25-11" aria-hidden="true" tabindex="-1"></a>      <span class="st">&quot;city_refine&quot;</span> <span class="ot">=</span> <span class="st">&quot;city&quot;</span>,</span>
<span id="cb25-12"><a href="#cb25-12" aria-hidden="true" tabindex="-1"></a>      <span class="st">&quot;state_norm&quot;</span> <span class="ot">=</span> <span class="st">&quot;state&quot;</span>,</span>
<span id="cb25-13"><a href="#cb25-13" aria-hidden="true" tabindex="-1"></a>      <span class="st">&quot;zip_norm&quot;</span> <span class="ot">=</span> <span class="st">&quot;zip&quot;</span></span>
<span id="cb25-14"><a href="#cb25-14" aria-hidden="true" tabindex="-1"></a>    )</span>
<span id="cb25-15"><a href="#cb25-15" aria-hidden="true" tabindex="-1"></a>  )</span></code></pre></div>
<pre><code>#&gt; # A tibble: 3 × 5
#&gt;   state_norm zip_norm city_swap     city_refine     n
#&gt;   &lt;chr&gt;      &lt;chr&gt;    &lt;chr&gt;         &lt;chr&gt;       &lt;int&gt;
#&gt; 1 OH         44202    AUOROA        AURORA          4
#&gt; 2 IL         60585    PLAINFIELD IL PLAINFIELD      1
#&gt; 3 KY         42754    LEICHTFIELD   LEITCHFIELD     1</code></pre>
<p>Then we can join the refined values back to the database.</p>
<div class="sourceCode" id="cb27"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb27-1"><a href="#cb27-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb27-2"><a href="#cb27-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">left_join</span>(good_refine) <span class="sc">%&gt;%</span> </span>
<span id="cb27-3"><a href="#cb27-3" aria-hidden="true" tabindex="-1"></a>  <span class="fu">mutate</span>(<span class="at">city_refine =</span> <span class="fu">coalesce</span>(city_refine, city_swap))</span></code></pre></div>
<h4 id="progress">Progress</h4>
<p>Our goal for normalization was to increase the proportion of city
values known to be valid and reduce the total distinct values by
correcting misspellings.</p>
<table>
<thead>
<tr class="header">
<th align="left">stage</th>
<th align="right">prop_in</th>
<th align="right">n_distinct</th>
<th align="right">prop_na</th>
<th align="right">n_out</th>
<th align="right">n_diff</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">str_to_upper(kyc$vend_city)</td>
<td align="right">0.988</td>
<td align="right">1286</td>
<td align="right">0</td>
<td align="right">586</td>
<td align="right">143</td>
</tr>
<tr class="even">
<td align="left">kyc$city_swap</td>
<td align="right">0.997</td>
<td align="right">1213</td>
<td align="right">0</td>
<td align="right">127</td>
<td align="right">44</td>
</tr>
</tbody>
</table>
<p>You can see how the percentage of valid values increased with each
stage.</p>
5CYII=" /><!-- --></p>
<p>More importantly, the number of distinct values decreased each stage.
We were able to confidently change many distinct invalid values to their
valid equivalent.</p>
<h2 id="conclude">Conclude</h2>
<p>Before exporting, we can remove the intermediary normalization
columns and rename all added variables with the <code>_clean</code>
suffix.</p>
<div class="sourceCode" id="cb28"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb28-1"><a href="#cb28-1" aria-hidden="true" tabindex="-1"></a>kyc <span class="ot">&lt;-</span> kyc <span class="sc">%&gt;%</span> </span>
<span id="cb28-2"><a href="#cb28-2" aria-hidden="true" tabindex="-1"></a>  <span class="fu">select</span>(</span>
<span id="cb28-3"><a href="#cb28-3" aria-hidden="true" tabindex="-1"></a>    <span class="sc">-</span>city_norm,</span>
<span id="cb28-4"><a href="#cb28-4" aria-hidden="true" tabindex="-1"></a>    <span class="sc">-</span>city_swap,</span>
<span id="cb28-5"><a href="#cb28-5" aria-hidden="true" tabindex="-1"></a>    <span class="at">city_clean =</span> city_refine</span>
<span id="cb28-6"><a href="#cb28-6" aria-hidden="true" tabindex="-1"></a>  ) <span class="sc">%&gt;%</span> </span>
<span id="cb28-7"><a href="#cb28-7" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rename_all</span>(<span class="sc">~</span><span class="fu">str_replace</span>(., <span class="st">&quot;_norm&quot;</span>, <span class="st">&quot;_clean&quot;</span>)) <span class="sc">%&gt;%</span> </span>
<span id="cb28-8"><a href="#cb28-8" aria-hidden="true" tabindex="-1"></a>  <span class="fu">rename_all</span>(<span class="sc">~</span><span class="fu">str_remove</span>(., <span class="st">&quot;_raw&quot;</span>)) <span class="sc">%&gt;%</span> </span>
<span id="cb28-9"><a href="#cb28-9" aria-hidden="true" tabindex="-1"></a>  <span class="fu">relocate</span>(state_clean, zip_clean, <span class="at">.after =</span> city_clean)</span></code></pre></div>
<div class="sourceCode" id="cb29"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb29-1"><a href="#cb29-1" aria-hidden="true" tabindex="-1"></a><span class="fu">glimpse</span>(<span class="fu">sample_n</span>(kyc, <span class="dv">50</span>))</span>
<span id="cb29-2"><a href="#cb29-2" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; Rows: 50</span></span>
<span id="cb29-3"><a href="#cb29-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; Columns: 28</span></span>
<span id="cb29-4"><a href="#cb29-4" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ link                   &lt;chr&gt; NA, NA, NA, NA, &quot;https://secure2.kentucky.gov/TransparencyWebApi/v…</span></span>
<span id="cb29-5"><a href="#cb29-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ contract_identifier    &lt;chr&gt; &quot;1075F0E1-1E50-4D88-BA82-E3739C36FE73&quot;, &quot;45C78EA1-63CD-4240-96F9-5…</span></span>
<span id="cb29-6"><a href="#cb29-6" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ classification         &lt;chr&gt; NA, &quot;MISCELLANEOUS PROFESSIONAL SERVICES&quot;, NA, NA, &quot;CONSULTING SER…</span></span>
<span id="cb29-7"><a href="#cb29-7" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ classification_code    &lt;chr&gt; NA, &quot;961&quot;, NA, NA, &quot;918&quot;, &quot;912&quot;, NA, &quot;912&quot;, &quot;803&quot;, NA, &quot;961&quot;, NA, …</span></span>
<span id="cb29-8"><a href="#cb29-8" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ cited_auth_description &lt;chr&gt; &quot;Memorandum of Agreement&quot;, &quot;Memorandum of Agreement&quot;, &quot;Memorandum …</span></span>
<span id="cb29-9"><a href="#cb29-9" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ contract_type_code     &lt;chr&gt; &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, &quot;PO&quot;, …</span></span>
<span id="cb29-10"><a href="#cb29-10" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ doc_id                 &lt;chr&gt; &quot;1900001860&quot;, &quot;1900001899&quot;, &quot;1900001848&quot;, &quot;1900001862&quot;, &quot;200000272…</span></span>
<span id="cb29-11"><a href="#cb29-11" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ branch_name            &lt;chr&gt; &quot;Judicial&quot;, &quot;Judicial&quot;, &quot;Judicial&quot;, &quot;Judicial&quot;, &quot;Executive&quot;, &quot;Exec…</span></span>
<span id="cb29-12"><a href="#cb29-12" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ full_agency            &lt;chr&gt; &quot;Judicial Department&quot;, &quot;Judicial Department&quot;, &quot;Judicial Department…</span></span>
<span id="cb29-13"><a href="#cb29-13" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ cab_name               &lt;chr&gt; NA, NA, NA, NA, &quot;Education &amp; Workforce Development Cabinet&quot;, &quot;Ener…</span></span>
<span id="cb29-14"><a href="#cb29-14" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ dept_name              &lt;chr&gt; &quot;Judicial Department&quot;, &quot;Judicial Department&quot;, &quot;Judicial Department…</span></span>
<span id="cb29-15"><a href="#cb29-15" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ reason_modification    &lt;chr&gt; &quot;Accounting line was not broken out by county.&quot;, NA, NA, NA, NA, N…</span></span>
<span id="cb29-16"><a href="#cb29-16" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ start_date             &lt;chr&gt; &quot;7/1/2018&quot;, &quot;7/1/2018&quot;, &quot;7/1/2018&quot;, &quot;7/1/2018&quot;, &quot;7/1/2020&quot;, &quot;12/1/…</span></span>
<span id="cb29-17"><a href="#cb29-17" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ end_date               &lt;chr&gt; &quot;6/30/2019&quot;, &quot;6/30/2019&quot;, &quot;6/30/2019&quot;, &quot;6/30/2019&quot;, &quot;6/30/2021&quot;, &quot;…</span></span>
<span id="cb29-18"><a href="#cb29-18" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_cust_id           &lt;chr&gt; &quot;KY0036340&quot;, &quot;KY0028291&quot;, &quot;KY0035990&quot;, &quot;KY0035989&quot;, &quot;KY0035868&quot;, &quot;…</span></span>
<span id="cb29-19"><a href="#cb29-19" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_name              &lt;chr&gt; &quot;Western KY Regional Mental Health &amp; Retardation Advisory Brd&quot;, &quot;C…</span></span>
<span id="cb29-20"><a href="#cb29-20" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_address1          &lt;chr&gt; &quot;425 Braodway Street&quot;, &quot;PO BOX 568&quot;, &quot;PO BOX 790&quot;, &quot;P O BOX 2680&quot;,…</span></span>
<span id="cb29-21"><a href="#cb29-21" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_city              &lt;chr&gt; &quot;PADUCAH&quot;, &quot;CORBIN&quot;, &quot;ASHLAND&quot;, &quot;COVINGTON&quot;, &quot;GREENSBURG&quot;, &quot;EDMONT…</span></span>
<span id="cb29-22"><a href="#cb29-22" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_state             &lt;chr&gt; &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, …</span></span>
<span id="cb29-23"><a href="#cb29-23" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ vend_zip               &lt;chr&gt; &quot;42001&quot;, &quot;40702&quot;, &quot;41105-0790&quot;, &quot;41011-2680&quot;, &quot;42743&quot;, &quot;42129&quot;, &quot;4…</span></span>
<span id="cb29-24"><a href="#cb29-24" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ procurement_name       &lt;chr&gt; &quot;Memorandum of Agreement&quot;, &quot;Memorandum of Agreement&quot;, &quot;Memorandum …</span></span>
<span id="cb29-25"><a href="#cb29-25" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ contract_amount        &lt;dbl&gt; 118000.00, 10000.00, 40000.00, 3000.00, 140011.00, 1350.00, 113000…</span></span>
<span id="cb29-26"><a href="#cb29-26" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ year                   &lt;chr&gt; &quot;2018&quot;, &quot;2018&quot;, &quot;2018&quot;, &quot;2018&quot;, &quot;2020&quot;, &quot;2019&quot;, &quot;2018&quot;, &quot;2021&quot;, &quot;2…</span></span>
<span id="cb29-27"><a href="#cb29-27" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ date                   &lt;chr&gt; &quot;7/1/2018 to 6/30/2019&quot;, &quot;7/1/2018 to 6/30/2019&quot;, &quot;7/1/2018 to 6/3…</span></span>
<span id="cb29-28"><a href="#cb29-28" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ address_clean          &lt;chr&gt; &quot;425 BRAODWAY ST&quot;, &quot;PO BOX 568&quot;, &quot;PO BOX 790&quot;, &quot;P O BOX 2680&quot;, &quot;PO…</span></span>
<span id="cb29-29"><a href="#cb29-29" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ city_clean             &lt;chr&gt; &quot;PADUCAH&quot;, &quot;CORBIN&quot;, &quot;ASHLAND&quot;, &quot;COVINGTON&quot;, &quot;GREENSBURG&quot;, &quot;EDMONT…</span></span>
<span id="cb29-30"><a href="#cb29-30" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ state_clean            &lt;chr&gt; &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, &quot;KY&quot;, …</span></span>
<span id="cb29-31"><a href="#cb29-31" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; $ zip_clean              &lt;chr&gt; &quot;42001&quot;, &quot;40702&quot;, &quot;41105&quot;, &quot;41011&quot;, &quot;42743&quot;, &quot;42129&quot;, &quot;41701&quot;, &quot;41…</span></span></code></pre></div>
<h2 id="export">Export</h2>
<ol style="list-style-type: decimal">
<li>There are 50,771 records in the database.</li>
<li>There are 0 duplicate records in the database.</li>
<li>The range and distribution of <code>amount</code> and
<code>date</code> seem reasonable.</li>
<li>There are 0 records missing key variables.</li>
<li>There are no geographic variables to be normalized.</li>
<li>The 4-digit <code>year</code> variable has been created.</li>
</ol>
<p>Now the file can be saved on disk for upload to the Accountability
server.</p>
<div class="sourceCode" id="cb30"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb30-1"><a href="#cb30-1" aria-hidden="true" tabindex="-1"></a>clean_dir <span class="ot">&lt;-</span> <span class="fu">dir_create</span>(<span class="fu">here</span>(<span class="st">&quot;ky&quot;</span>, <span class="st">&quot;contracts&quot;</span>, <span class="st">&quot;data&quot;</span>, <span class="st">&quot;clean&quot;</span>))</span>
<span id="cb30-2"><a href="#cb30-2" aria-hidden="true" tabindex="-1"></a>clean_path <span class="ot">&lt;-</span> <span class="fu">path</span>(clean_dir, <span class="st">&quot;ky_contracts_clean.csv&quot;</span>)</span>
<span id="cb30-3"><a href="#cb30-3" aria-hidden="true" tabindex="-1"></a><span class="fu">write_csv</span>(kyc, clean_path, <span class="at">na =</span> <span class="st">&quot;&quot;</span>)</span>
<span id="cb30-4"><a href="#cb30-4" aria-hidden="true" tabindex="-1"></a><span class="fu">file_size</span>(clean_path)</span>
<span id="cb30-5"><a href="#cb30-5" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; 22.8M</span></span></code></pre></div>
<p>The encoding of the exported file should be UTF-8 or ASCII.</p>
<div class="sourceCode" id="cb31"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb31-1"><a href="#cb31-1" aria-hidden="true" tabindex="-1"></a>enc <span class="ot">&lt;-</span> <span class="fu">system2</span>(<span class="st">&quot;file&quot;</span>, <span class="at">args =</span> <span class="fu">paste</span>(<span class="st">&quot;-i&quot;</span>, clean_path), <span class="at">stdout =</span> <span class="cn">TRUE</span>)</span>
<span id="cb31-2"><a href="#cb31-2" aria-hidden="true" tabindex="-1"></a><span class="fu">str_replace_all</span>(enc, clean_path, basename)</span>
<span id="cb31-3"><a href="#cb31-3" aria-hidden="true" tabindex="-1"></a><span class="co">#&gt; [1] &quot;ky_contracts_clean.csv: text/csv; charset=us-ascii&quot;</span></span></code></pre></div>
<h2 id="dictionary">Dictionary</h2>
<p>The following table describes the variables in our final exported
file:</p>
<table>
<thead>
<tr class="header">
<th align="left">Column</th>
<th align="left">Type</th>
<th align="left">Overlaped</th>
<th align="left">Definition</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><code>link</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">link</td>
</tr>
<tr class="even">
<td align="left"><code>contract_identifier</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">contract_identifier</td>
</tr>
<tr class="odd">
<td align="left"><code>classification</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">classification</td>
</tr>
<tr class="even">
<td align="left"><code>classification_code</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">classification_code</td>
</tr>
<tr class="odd">
<td align="left"><code>cited_auth_description</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">cited_auth_description</td>
</tr>
<tr class="even">
<td align="left"><code>contract_type_code</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">contract_type_code</td>
</tr>
<tr class="odd">
<td align="left"><code>doc_id</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">doc_id</td>
</tr>
<tr class="even">
<td align="left"><code>branch_name</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">branch_name</td>
</tr>
<tr class="odd">
<td align="left"><code>full_agency</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">full_agency</td>
</tr>
<tr class="even">
<td align="left"><code>cab_name</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">cab_name</td>
</tr>
<tr class="odd">
<td align="left"><code>dept_name</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">dept_name</td>
</tr>
<tr class="even">
<td align="left"><code>reason_modification</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">reason_modification</td>
</tr>
<tr class="odd">
<td align="left"><code>start_date</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">start_date</td>
</tr>
<tr class="even">
<td align="left"><code>end_date</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">end_date</td>
</tr>
<tr class="odd">
<td align="left"><code>vend_cust_id</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">vend_cust_id</td>
</tr>
<tr class="even">
<td align="left"><code>vend_name</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">vend_name</td>
</tr>
<tr class="odd">
<td align="left"><code>vend_address1</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">vend_address1</td>
</tr>
<tr class="even">
<td align="left"><code>vend_city</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">vend_city</td>
</tr>
<tr class="odd">
<td align="left"><code>vend_state</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">vend_state</td>
</tr>
<tr class="even">
<td align="left"><code>vend_zip</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">vend_zip</td>
</tr>
<tr class="odd">
<td align="left"><code>procurement_name</code></td>
<td align="left"><code>character</code></td>
<td align="left">TRUE</td>
<td align="left">procurement_name</td>
</tr>
<tr class="even">
<td align="left"><code>contract_amount</code></td>
<td align="left"><code>double</code></td>
<td align="left">TRUE</td>
<td align="left">contract_amount</td>
</tr>
<tr class="odd">
<td align="left"><code>year</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">year</td>
</tr>
<tr class="even">
<td align="left"><code>date</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">date</td>
</tr>
<tr class="odd">
<td align="left"><code>address_clean</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">address_clean</td>
</tr>
<tr class="even">
<td align="left"><code>city_clean</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">city_clean</td>
</tr>
<tr class="odd">
<td align="left"><code>state_clean</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">state_clean</td>
</tr>
<tr class="even">
<td align="left"><code>zip_clean</code></td>
<td align="left"><code>character</code></td>
<td align="left">FALSE</td>
<td align="left">zip_clean</td>
</tr>
</tbody>
</table>
<div class="sourceCode" id="cb32"><pre class="sourceCode r"><code class="sourceCode r"><span id="cb32-1"><a href="#cb32-1" aria-hidden="true" tabindex="-1"></a><span class="fu">write_lines</span>(</span>
<span id="cb32-2"><a href="#cb32-2" aria-hidden="true" tabindex="-1"></a>  <span class="at">x =</span> <span class="fu">c</span>(<span class="st">&quot;# Kentucky Contracts Data Dictionary</span><span class="sc">\n</span><span class="st">&quot;</span>, dict_md),</span>
<span id="cb32-3"><a href="#cb32-3" aria-hidden="true" tabindex="-1"></a>  <span class="at">path =</span> <span class="fu">here</span>(<span class="st">&quot;ky&quot;</span>, <span class="st">&quot;contracts&quot;</span>, <span class="st">&quot;ky_contracts_dict.md&quot;</span>),</span>
<span id="cb32-4"><a href="#cb32-4" aria-hidden="true" tabindex="-1"></a>)</span></code></pre></div>

</body>
</html>
