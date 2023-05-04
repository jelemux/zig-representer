# 📽 Zig representer

An [Exercism Representer] for the Zig programming language.

This is not (yet!) an official representer.  
I just want to see if I can build one.

[Exercism Representer]: https://github.com/exercism/docs/tree/main/building/tooling/representers

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
zig build run -- --slug "two-fer" --input-dir "./testdata/two-fer" --output-dir "./test-output" --log-level info
```

### 🐳 Container

#### Build
```shell
docker build . -t exercism/zig-representer:<version>
```

#### Run
```shell
docker run -it --rm -v "$PWD:/mnt" exercism/zig-representer:<version> "two-fer" "/mnt/testdata/two-fer" "/mnt/test-output"
```

## Current Normalizations

- Use placeholders for variable names
- Remove comments
- Apply standard formatting
- Consolidate multiple files

## Roadmap

- Sort top level declarations (imports, types, constants, variables, functions)
- Better error handling (maybe like [yazap][yazap-err]?)

[yazap-err]: https://github.com/PrajwalCH/yazap/blob/main/src/error.zig
