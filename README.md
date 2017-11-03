Overview
========

circuit-oneops-1 clouds, components, packs and services


Usage
========

Install the oneops-admin gem, cd to circuit-oneops-1 and run: circuit install


Knife
=====

For a single cookbook sync, use bundle exec knife model sync <cookbook-name>


Test
=====

Local Verifier:

```
WORKORDER=<path_to_local_workorder> kitchen verify
```

```
#<% load "#{File.dirname(__FILE__)}/../../../monkey_patch.rb" %>
driver:
  name: proxy
  host: 127.0.0.1
  reset_command: "exit 0"
  port: 22
  transport: local
verifier:
  name: busser
  transport: local
  sudo: false
  busser_bin: busser
  gem_home: /opt/oneops/inductor/kitchenci/verifier/gems
  gem_path: /opt/oneops/inductor/kitchenci/verifier/gems
  gem_cache: /opt/oneops/inductor/kitchenci/verifier/gems/cache
```

Remote Verifier:

```
WORKORDER=<path_to_workorder_on_remote_host> kitchen verify
```

```
#<% load "#{File.dirname(__FILE__)}/../../../monkey_patch.rb" %>
driver:
  name: proxy
  host: <%= compute %>
  reset_command: "exit 0"
  port: 22
  username: local
  ssh_key: <%= path to private key %>
```