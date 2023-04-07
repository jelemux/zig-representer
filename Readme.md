# 📽 Zig representer

An [Exercism Representer] for the Zig programming language.

This is not (yet!) an official representer.  
I just want to see if I can build one.

## 🛠 Development

### 🏠 Locally
1. Clone this repository
2. `git submodule update --init`

#### Build
```shell
zig build
```

#### Test
```shell
zig build test
```

#### Run
```shell
zig build run
```

### 🐳 Container image
```shell
docker build . -t exercism/zig-representer:<version>
```

[Exercism Representer]: https://github.com/exercism/docs/tree/main/building/tooling/representers