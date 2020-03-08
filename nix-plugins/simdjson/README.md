Usage
=====
```bash
nix --plugin-files /nix/store/hl55p2i314mjzzhwymh17x7gn2dazz9x-nix-plugin-simdjson/lib/simdjson.so
```

Why
===

old, boring json parser:

```
$ time nix eval '(builtins.length (builtins.attrNames (builtins.fromJSON (builtins.readFile ./hackage.json))))' --experimental-features nix-command
14632

real 0m0.756s
user 0m0.646s
sys  0m0.109s
```

modern, fancy json parser:

```
$ time nix eval '(builtins.length (builtins.attrNames (builtins.fromJSON (builtins.readFile ./hackage.json))))' --experimental-features nix-command --plugin-files simdjson.so

real 0m0.372s
user 0m0.221s
sys  0m0.151s
```
