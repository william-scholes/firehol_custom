My firewall runs in transparent bridge mode BEHIND the router which is also on the LAN IP, the router connects to the ONT, hence firehol lists that block private IPs break my config, so I remove them, and pull a single list to ingest into the firewall.

TODO:
integrate exclusions.json into parsing, for blacklist or whitelist
