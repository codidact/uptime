# uptime
Simple self-hosted configurable up-or-down checking tool, sending updates to StatusPage.

## Install
`git clone` this repo. You'll need Ruby and Bundler installed as a prerequisite.

## Usage
Copy the sample config file to `config.yml` and set it up. You'll need access credentials for SES,
and you'll need to configure your monitors. Follow the comments in the file and it shouldn't be too
difficult.

Once you've got it set up, use `ruby monitor.rb` to run it. It'll run forever, or until you Ctrl-C
it.

## License
MIT licensed.