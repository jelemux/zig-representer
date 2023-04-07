# 📽 Zig representer

An [Exercism Representer] for the Zig programming language.

This is not (yet!) an official representer.  
I just want to see if I can build one.

## 🛠 Build

### Locally
1. Clone this repository
2. `git submodule update --init`
3. `zig build`

### Container image
```shell
docker build . -t exercism/zig-representer:0.0.0
```

[Exercism Representer]: https://github.com/exercism/docs/tree/main/building/tooling/representers