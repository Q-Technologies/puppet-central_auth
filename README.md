# central_auth


<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [Setup](#setup)
  * [What central_auth affects](#what-central_auth-affects)
  * [Setup Requirements](#setup-requirements)
  * [Beginning with central_auth](#beginning-with-central_auth)
* [Usage](#usage)
  * [General](#general)
  * [SSSD](#sssd)
  * [PAM Access](#pam-access)
  * [PAM Files](#pam-files)
* [Reference](#reference)
  * [SSSD](#sssd-1)
  * [PAM Access](#pam-access-1)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

## Description

This module manages authentication to a centralised authentication system. It currently supports connection to
Active Directory and openLDAP from Red Hat, Suse, and Debian based systems.  It will use SSSD and 
associated services when available, but will use LDAP direct when SSSD is not available.  It can also restrict
access by group or user.

Technically it can also be used to just restrict access by group or user without connecting to a central auth system.

It is designed to be driven by Hiera data - not by code.

It installs a couple of temporary script files to perform the AD join and also to renew certificates.  These have 
been found to be the most reliable approach in complex environments.


## Setup

### What central_auth affects

It  modifies the following files:

When SSSD is activated:

* `/etc/samba/smb.conf` - ensures certain entries exist
* `/etc/krb5.conf` - replaces file
* `/etc/sssd/sssd.conf` - replaces file
* `/etc/nsswitch.conf` - replaces file
* SSSD service is set to enabled/running

When PAM access is activated:

* `/etc/security/access.conf` - replaces file when PAM access enabled

When managing PAM files:

* `/etc/pam.d/*` - full manages some files (depends on OS)

It also installs all the packages required for all functionality

### Setup Requirements

An OS install repository needs to be configured correctly so the packages will successfully install.

When joining to AD, a service account (and password) with sufficient permissions to add mchines
into the required OU.

### Beginning with central_auth

Include the class in your code:

```
include central_auth
```

Put the following into the required scope within Hiera

```
central_auth::manage_auth: true
central_auth::enable_sssd: true
central_auth::join_ad::Domain_user: domain_join_user
central_auth::join_ad::Domain_pass: password # Encrypted in Eyaml preferably
central_auth::join_ad::Domain_ou: "Clients/Unix Machines"
central_auth::config::Default_domain: example.com
```

## Usage

### General

All functionality within the module can be disable with this parameter:

```
# This defaults to false if not specified
central_auth::manage_auth: true
```

It allows the module to be enabled easily across the vast majority, but disabled
on some exceptions.

### SSSD

The SSSD functionality can be enabled/disabled from hiera (this applies also when direct
LDAP has to be used when SSSD is not available):

```
# This defaults to true if not specified
central_auth::enable_sssd: true
```

These settings are required to get authentication functional:

```
# These must be specifed if manage_auth is true
central_auth::join_ad::Domain_user: domain_join_user
central_auth::join_ad::Domain_pass: password # Encrypted in Eyaml preferably
central_auth::join_ad::Domain_ou: "Clients/Unix Machines"
central_auth::config::Default_domain: example.com
```

Here are some optional settings:
```
# Other sample settings
central_auth::pam::min_user_id: 400
central_auth::config::override_homedir: false
central_auth::config::override_shell: false

```
### PAM Access

If PAM access is enabled, then the `pam_access.so` PAM module is activated
and `/etc/security/access.conf` is populated according to the Hiera data in scope.

```
# This defaults to false if not specified
central_auth::enable_pam_access: true
# This defaults to true if not specified - required for PAM access to work reliably
central_auth::manage_pam_files: true
# Restrict access to the system by AD/LDAP/local group
central_auth::pam::allowed_groups:
  - unix_admins
  - unix_users
# Restrict access to the system by AD/LDAP/local user
central_auth::pam::allowed_users:
  'root':
    - 'cron'
    - 'crond'
    - 'tty1'
    - 'tty2'
    - 'tty3'
    - 'tty4'
    - 'tty5'
    - 'tty6'
    - 'LOCAL'
  matt: ALL
```

### PAM Files

Most PAM files are normally managed, but can be turned off with the `manage_pam_files` option.

```
# This defaults to true if not specified
central_auth::manage_pam_files: true
```

## Reference

### SSSD

These settings are required to get authentication functional.  No defaults
are provided, so must be specified when SSSD is enabled (some exampes shown):

```
central_auth::join_ad::Domain_user: domain_join_user
central_auth::join_ad::Domain_pass: password # Encrypted in Eyaml preferably
central_auth::join_ad::Domain_ou: "Clients/Unix Machines"
central_auth::config::Default_domain: example.com
```

The following settings can be modified through this module (defaults also shown):

```
central_auth::config::passwd_servers: []
central_auth::config::dns_lookup_kdc: true
central_auth::config::dns_lookup_realm: true
central_auth::config::forwardable: true
central_auth::config::directory_type: 'ad'
central_auth::config::ticket_lifetime: '2d'
central_auth::config::renew_lifetime: '30d'

central_auth::config::ldap_idmap_range_size: 200000
central_auth::config::ldap_id_mapping: false
central_auth::config::cache_credentials: true
central_auth::config::case_sensitive: false
central_auth::config::override_shell: '/bin/bash'
central_auth::config::override_homedir: '/home/%u'

central_auth::config::sssd_debug_level: 0
central_auth::config::ldap_uri: ''
central_auth::config::user_ou_path: ''
central_auth::config::group_ou_path: ''
central_auth::config::bind_user: ''
central_auth::config::bind_pass: ''
```


### PAM Access

The `central_auth::pam` takes the following parameters for password aging (defaults also shown):

```
central_auth::pam::dcredit: -1
central_auth::pam::difok: 5
central_auth::pam::lcredit: -1
central_auth::pam::ucredit: -1
central_auth::pam::ocredit: -1
central_auth::pam::minlen: 17
central_auth::pam::min_user_id: 500
```

The `central_auth::pam` takes the following parameters for controlling login access:

```
central_auth::pam::allowed_groups: {}
central_auth::pam::allowed_users: {}
```

These are a list of groups or users in the format or PAM `access.conf`.  Anything specified
for these parameters are granted access - everyone else is denied.  The parameters can be specified as
Data or Collections.  If a Collection, then all users/groups are given access from all origins.  If Data, 
then the origins can be specified.  See the Usage section for examples.


## Limitations

This module is successfully working in multiple environments, but every environment is different, so
there may be issues that are not uncovered yet.

As it is designed to be driven entirely by Hiera (once called in by code), it will not be easy to manipulate in code.

## Development

Feel free to improve any functionality that is limited/broken in certain situations.  You can submit
a PR on GitHub, but be mindful that the code needs to be flexible enough to run in different environments.
