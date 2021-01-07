# Content supply chain security
C7N's supply chain attack vectors can be divided into two major categories: Software and Content.

* The Software vector concerns all C7N direct dependencies of code and platform. All of the libraries consumed, all of the OS run on.
* The Content vector concerns user authored policy content exeecuted by C7N

Only the Content vector is in scope for this discussion.

## What and Why

* C7N is a domain specific scripting language sourced through yaml policy elements
* All modern scripting languages require a method to protect script source against tampering
* C7N has no intrinsic tamper protection for policy elements

Assuming a basic source controlled setup. The current policy chain of custody is:

``` engineer -> PR -> master -> pull -xx-> execute ```

After the pull link, you can no longer prove the origin or authenticity of the policy using C7N directly. All content security is assumed to be provided by the platform C7N is running on. In the common case, this is just the ACL on the directory containing the policy files. Advanced cases may be doing their own signing/hashing verification scheme using platform tools.

proposed policy chain of custody:

``` engineer -> PR -> sign -> master -> pull -> load -> verify -> execute ```

The policy chain of custody is maintained from creation to execution. The platform security requirements for content are reduced to securing the public key and commandline arguments going into C7N execution.

## How 

The user interface would look something like the following commands:
```
# Generate key pair
openssl genrsa -des3 -out foo.pem 4096
openssl rsa -in foo.pem -outform PEM -pubout -out foo-public.pem

# Sign a policy
custodian sign --signed foo.pem foo.yaml

# Require a policy being ran is signed by a known public key
custodian run -s foo --signed foo-public.pem foo.yaml

# Verify a policy's signature
custodian validate --signed foo-public.pem foo.yaml

```

The signature goes into the policy as a watermark:
```
# Policy-Signature: <SOME SIGNATURE>
policies:
  - name: offhours-stop
    resource: ec2
    filters:
      - type: offhour
        weekends: false
        default_tz: pt
        tag: downtime
        opt-out: true
        onhour: 8
        offhour: 20
```

Implementation outside of commandline stuff. No new deps are added. RSA support comes from the existing cryptography reference.
* utils.load_file()
  * gets a new argument named keys which is an array of paths to public keys used for verification.
  * if keys are supplied and the file being loaded is yaml, check signature and raise an error if invalid.
* cli._default_options
  * adds --signing <keyfile> to options
* policy.load()
  * sends the keys specified in options to the updated utils.load_file()
* sign_file() added to utils and plumbed through to cli
* verify_file() added to utils and plumbed through to cli

## When
Now :)


## Notes

* Tamper protection enforcement has to be optional
* Policy signing would be done by a CI task with access to protected signing keys
* Signing keys should also be loadable from env variable directly. Enables secrets manager scenarios that eliminates most security concerns around key handling.
* Policy signing might be part of a CI's logical publish step
* Signing might need an interactive path for PEM password entry
* Runtime supports multiple keys for transparent key rotation
* Some enveloping with key identification would make it nicer


