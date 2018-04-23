# == Class: central_auth
#
# A module to manage Authentication using SSSD and PAM
#
#
class central_auth (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Boolean $manage_auth                = false,
  Boolean $enable_sssd                = true,
  Boolean $enable_pam_access          = false,
) {

  case $osfamily {
    'Suse': { 
      if ($::operatingsystemmajrelease + 0) < 11 {
        fail("Wrong SLES version, should be 11 or greater than 11, not ${::operatingsystemmajrelease}")
      }
    }
    'RedHat': {
      if ($::operatingsystemmajrelease + 0) < 6 {
        fail("Wrong RedHat version, should be 6 or greater than 6, not ${::operatingsystemmajrelease}")
      }
    }
    'Debian': {
      if ($::operatingsystemmajrelease + 0) < 7 and $operatingsystem == 'Debian' {
        fail("Wrong Debian version, should be 7 or greater than 7, not ${::operatingsystemmajrelease}")
      } elsif ($::operatingsystemmajrelease + 0) < 12 and $operatingsystem == 'Ubuntu' {
        fail("Wrong Debian version, should be 12 or greater than 12, not ${::operatingsystemmajrelease}")
      }
    }
    default: { 
      fail("Wrong OS Family, should be RedHat, Debian or Suse, not ${::osfamily}") 
    }
  }

  if $manage_auth {

    class { 'central_auth::install': }

    -> class { 'central_auth::config': }

    -> class { 'central_auth::pam': }

    -> class { 'central_auth::join_ad': }

    -> class { 'central_auth::service': }

  }
}
