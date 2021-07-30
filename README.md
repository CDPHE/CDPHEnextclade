# CDPHEnextclade

WDL for running Nextclade on GCP Terra.

Terra data table should contain 2 columns
1. entity:sample_id containing the prefix that you would like for your output files (e.g. entity:sample000_id)
2. multifasta: location (google bucket path) to input your multifasta run Nextclade. 

On Terra, inputs should be specified as:
1. multifasta = this.multifasta
2. sample_id = this.sample_id (e.g. this.sample000_id depending on how you named your data table)
3. out_dir = the google bucket path where you would like your output files transferred in double quotes (e.g. "gs://my/google/bucket/path")
