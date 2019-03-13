# ROSE Compiler debian package

## Generating GPG key

Run genkey.sh, choose key type and length (you can use default values for them), specify you full name and email address, and set the password (it could be empty). Generating key takes a while. After this copy printed fingerprint of the key and send it to Launchpad on this [page](https://launchpad.net/~/+editpgpkeys) and wait for verification email. This email will contain encrypted GPG message. Copy it into a file and decrypt with *gpg --decrypt <file>=*. In the bottom of the list there will be a verification link, just open it with your browser.

Generation and sending key may be done only once. After that you can simply move your key between machines with *gpg --export-secret-keys* and *gpg --import*.

## Building

To build a package simply run build.sh script. It installs all the dependencies, fetches the source code, builds it, and packs into a package.

## Publishing

```
dput <ppa path> <file with .changes extension>
```
