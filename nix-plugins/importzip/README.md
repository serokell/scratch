Usage
=====
```bash
export NIX_PATH=hackage=$PWD/hackage.nix.zip
nix --plugin-files /nix/store/l3sns5vcj5paxx1hvwvwzjvysyn8qhgp-nix-plugin-importzip/lib/importzip.so build -f your-fancy-hs.nix
```

Why
===

```bash
❯ du -hs hackage.nix/ hackage.nix.zip
829M	hackage.nix/
195M	hackage.nix.zip
```
