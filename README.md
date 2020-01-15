# signing_tools: macOS Signing and Notarization Tools

This set of scripts currently provides macOS signing and notarization tools for command-line binaries. In the future it will probably include Windows signing tools as well

The macOS signing and notarization tools (macos_sign.sh and macos_notarize.sh) must be run on macOS.

Examples:

`./macos_sign.sh --signing-password="${SIGNING_TOOLS_SIGNING_PASSWORD}" --cert-file=${CERTFILE} --cert-name="${CERTNAME}" --target-binary="${TARGET_BINARY}"`

`./macos_notarize.sh  --app-specific-password=${APP_SPECIFIC_PASSWORD} --apple-id=${APPLE_ID} --primary-bundle-id=com.ddev.test-signing-tools --target-binary=${TARGET_BINARY}`

The rest of this file just explains the methods and resources for signing.

## macOS Command-line Binary Signing and Notarization

[DDEV-Local](https://github.com/drud/ddev) has a number of issues and PRs related to macOS signing and notarization ([signing PR](https://github.com/drud/ddev/pull/1727), [signing issue](https://github.com/drud/ddev/issues/1626), [notarization PR](https://github.com/drud/ddev/pull/2015)), but because it's complex and somewhat poorly documented topic, this toolset was built to capture the techniques (and to provide a central place to capture the documentation).

### Overview

Apple's ongoing initiatives at controlling what runs on their platforms took a new turn with macOS Catalina (10.15), with required app and command-line binary signing. They had threatened required notarization at the release of Catalina in November, but [delayed that to 3 Feb 2020](https://developer.apple.com/news/?id=12232019a&irgwc=1&aosid=p239&cid=aos-us-aff-ir&irchannel=13631&irpid=27795&clickid=xCbU172KJxyORV9wUx0Mo34BUknR3xW91R0sUY0&ircid=7613).

Notarization requires

* Signing the binary or app with a Developer ID Certificate (not just a distribution cert)
* Notarization (uploading the binary to Apple for approval)
* Validating code signing
* Validating notarization

### Signing a command-line binary

* Signing requires the one-time task of obtaining a doing a certificate request (and creating associated private key) and downloading the certificate. See [docs](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html).
* The *notarization* process requires that binaries be hardened and signed with a *Developer ID certificate*, so, for example, DDEV's  Apple account on developer.apple.com might have a cert called 'Developer ID Application: DRUD Technology, LLC (3BAN66AHXX)'. This cert can be used for signing multiple binaries or applications.
* Signing is done with the macOS tool `codesign`. For example,
`codesign --keychain buildagent -s 'Developer ID Application: DRUD Technology, LLC (3BAN66AG5M)' --timestamp --options runtime .gotmp/bin/darwin_amd64/ddev`. The [macos_sign.sh](macos_sign.sh) tool here just codifies that process.

#### Validating the signature on the binary

Signature validation can be done with `codesign -v`, for example, `codesign -vv -d .gotmp/bin/darwin_amd64/ddev`.

### Notarizing a binary

Notarizing a binary means

* Uploading the signed binary to Apple for its approval
* Verifying that the process completes successfully and has no warnings
* Verifying from the build process (a link given at notarization completed) that there are no warnings. (When I first got notarization to work, it reported that the package was accepted, but there was a warning that it did not have a "Developer ID" certificate, and thus was *not* successful.)
* In the case of a .app or other types of artifact, "stapling" the approval to the artifact. In the case of a command-line binary it is not possible to staple the approval. [Apple announcement](https://developer.apple.com/news/?id=06032019i) specifies that stapling is for apps, installer packages, and kernel extensions. We can expect this to be added in the future for command-line binaries, but at this time there is no place in the binary architecture for anything to be stapled. The [Apple notarizing article](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow#3087720) says
    > Although tickets are created for standalone binaries, it’s not currently possible to staple tickets to them.

#### Validating notarization

The best technique I've found for validating succesful notarization was [archichect](https://eclecticlight.co/2019/11/26/how-to-check-quarantine-64-bit-signature-and-notarization-for-almost-anything/), which validates the signing and also checks in with Apple to see if it's been notarized.

`codesign --test-requirement="=notarized" --verify --verbose ddev` was suggested as an approach, but it doesn't seem to work on a binary that can't be stapled.

### CI-based Signing and Notarization

Signing and Notarizing are implemented in [DDEV-Local's Makefile](https://github.com/drud/ddev/blob/9f43569444c9c28fbfb3bab77f35aa49a4bd6a09/Makefile#L130-L141) and `make darwin_signed` there does the whole process using the tools from this repo.

## Resources and Links

* [Basic Step-by-step Signing and Notarization Walkthrough](http://www.zarkonnen.com/signing_notarizing_catalina)
* [Testing Notarization](https://eclecticlight.co/2019/11/26/how-to-check-quarantine-64-bit-signature-and-notarization-for-almost-anything/) and [Archichect validation tool](https://eclecticlight.co/32-bitcheck-archichect/)
* [Notarization Answer on Stack Overflow](https://stackoverflow.com/questions/56890749/macos-notarize-in-script/56890758#56890758)
* [notarize-app](https://www.notion.so/randyfay/Notarization-Catalina-e8d037cb6caf44fc9eef339f092faa64#e590379f4a35498181b18554a49fac88) script for CI notarization.
* [Apple's general Notarizing article](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution)
* [Apple's Customizing the Notarization Workflow](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow) article
* [CI Signing technique](https://stackoverflow.com/a/40039594/215713) (Stack Overflow)
* [Signing without the popup password](https://stackoverflow.com/a/40039594/215713) (for CI, same SO question)
* [Apple's Code Signing docs](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html)
* [Common Code Signing Errors](https://medium.com/@SharpFive/common-code-signing-errors-codesign-failed-with-exit-code-1-1ffa5f4785c9)
