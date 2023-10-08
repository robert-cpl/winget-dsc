# winget-config
Holds the winget machine configuration to be used on a brand new OS installation.

# How to use
`winget configuration -f <path-to-dsc-yaml>`
<br> **or**
<br> `winget configuration <path-to-dsc-yaml>`

# TODO
- [ ] Add a shared DSC configuration for all packages that will be installed on any machine.
- [ ] Add a PS script that will handle multiple DSC installations as `winget configuratiion` cant take a wildcard.