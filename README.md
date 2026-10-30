# sway-rpm

Sway and wlroots rebuilt from Fedora Rawhide for Fedora 44, signed, rebuilt weekly by GitHub Actions.

```sh
sudo curl -o /etc/yum.repos.d/sway-rpm.repo https://musmandev092.github.io/sway-rpm/sway-rpm.repo
sudo dnf upgrade --refresh sway wlroots
```

The repo file points at `https://musmandev092.github.io/sway-rpm/fc44/x86_64` and the signing key
`RPM-GPG-KEY-sway-rpm.asc` in this repository (fingerprint below).

Fingerprint: `EF93D47772AB894B8232582B49C90DF85566D034`

Builds are unmodified Rawhide source packages. Use the Actions tab to rebuild by hand.
