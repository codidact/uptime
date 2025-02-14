# uptime
Simple self-hosted configurable up-or-down checking tool, sending updates to StatusPage.

## Install
You'll need Ruby and Bundler installed as a prerequisite.

* `git clone` this repo and `cd` into it.
* `bundle install`

## Usage
Copy the sample config file to `config.yml` and set it up. You'll need access credentials for SES,
and you'll need to configure your monitors. Follow the comments in the file and it shouldn't be too
difficult.

Once you've got it set up, use `ruby monitor.rb` to run it. It'll run forever, or until you Ctrl-C
it.

## Development & Contributing
Follow the [Install](#install) steps to set up for development. Contributions are welcome - please 
target the `master` branch for your pull request. If you intend to add significant or breaking
changes, it is encouraged to open an issue first so that your intentions can be discussed.

Contributions and contributors must follow the [Codidact Code of Conduct](?tab=coc-ov-file).

## License
MIT licensed.