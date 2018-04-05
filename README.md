# central_auth

## Overview

Module manages authentication to a centralised authentication system. It currently supports connection to
Active Directory and openLDAP from Red Hat, Suse, and Debian based systems.  It will use SSSD and 
associated services when available, but will use LDAP direct when SSSD is not available.

## Setup

Put the following into the required scope within Hiera

```
## In the hiera file that matches the scope of systems to have auth managed on
# This defaults to false if not specified
central_auth::manage_auth: true
# This defaults to true if not specified
central_auth::enable_sssd: true

# These must be specifed if manage_auth is true
central_auth::join_ad::Domain_user: domain_join_user
central_auth::join_ad::Domain_pass: password # Encrypted in Eyaml preferably
central_auth::join_ad::Domain_ou: "Clients/Unix Machines"
central_auth::config::Default_domain: example.com
```
