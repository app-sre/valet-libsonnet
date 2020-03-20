# valet-libsonnet

This work is heavily inspired in the great https://github.com/metalmatze/slo-libsonnet library

## Building the example yamls

Let's pick one as an example:

```
cd examples
jb install
jsonnet -J vendor cincinnati.jsonnet | python json2yaml.py
```

where `jb` is the [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
