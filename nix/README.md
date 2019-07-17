# Nix modules, pin, and overlay

The pin and overlay are managed by `niv`. Modules contains machine configurations.

## Usage

You will want to `import ./../nix {}`, adjusting the path as necessary, in order
to import the pin and overlay in your nix expression.

See [niv](https://github.com/nmattia/niv) for how to manage the pins.

## Modules

The modules are meant to be imported in your `configuration.nix`. There is
common configuration, along with hardware profiles for certain server types.
