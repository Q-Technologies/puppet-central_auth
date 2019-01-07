# == Class: central_auth::pam
#
# Class to manage PAM for CrackLib and SSSD
#
class central_auth::pam (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Integer $min_user_id,
  String $access_conf,

  Integer $dcredit                   = -1,
  Integer $difok                     = 5,
  Integer $lcredit                   = -1,
  Integer $ucredit                   = -1,
  Integer $ocredit                   = -1,
  Integer $minlen                    = 17,

  Boolean $enable_sssd               = $central_auth::enable_sssd,
  Boolean $enable_pam_access         = $central_auth::enable_pam_access,

){

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  $allowed_groups = lookup('central_auth::pam::allowed_groups', Any, deep, {})
  $allowed_users = lookup('central_auth::pam::allowed_users', Any, deep, {})
  #notify { "allowed_groups: $allowed_groups": }
  #notify { "allowed_users: $allowed_users": }

  #class { 'authconfig': }

  if $::osfamily == 'RedHat' {
    file { [ '/etc/pam.d/system-auth', '/etc/pam.d/password-auth' ] :
      ensure  => file,
      content => epp('central_auth/rhel-pam-auth', {
                                                    enable_pam_access => $enable_pam_access,
                                                    enable_sssd       => $enable_sssd,
                                                    dcredit           => $dcredit,
                                                    difok             => $difok,
                                                    lcredit           => $lcredit,
                                                    ucredit           => $ucredit,
                                                    ocredit           => $ocredit,
                                                    minlen            => $minlen,
                                                    min_user_id       => $min_user_id,
                                                  } ),
    }
    if $enable_pam_access {
      file { $access_conf:
        ensure  => file,
        content => epp('central_auth/access.conf', { allowed_groups => $allowed_groups, allowed_users => $allowed_users } ),
      }
    }
  } elsif $::osfamily == 'Suse' {
    file { '/etc/pam.d/common-password':
      ensure  => file,
      content => epp('central_auth/suse-pam-password', {
                                                        enable_sssd => $enable_sssd,
                                                        dcredit     => $dcredit,
                                                        difok       => $difok,
                                                        lcredit     => $lcredit,
                                                        ucredit     => $ucredit,
                                                        ocredit     => $ocredit,
                                                        minlen      => $minlen,
                                                      } ),
    }
    file { '/etc/pam.d/common-auth':
      ensure  => file,
      content => epp('central_auth/suse-pam-auth', {
                                                    enable_sssd => $enable_sssd,
                                                    dcredit     => $dcredit,
                                                    difok       => $difok,
                                                    lcredit     => $lcredit,
                                                    ucredit     => $ucredit,
                                                    ocredit     => $ocredit,
                                                    minlen      => $minlen,
                                                    min_user_id => $min_user_id,
                                                  } ),
    }
    file { '/etc/pam.d/common-account':
      ensure  => file,
      content => epp('central_auth/suse-pam-account', {
                                                        enable_sssd => $enable_sssd,
                                                        dcredit     => $dcredit,
                                                        difok       => $difok,
                                                        lcredit     => $lcredit,
                                                        ucredit     => $ucredit,
                                                        ocredit     => $ocredit,
                                                        minlen      => $minlen,
                                                        min_user_id => $min_user_id,
                                                      } ),
    }
    file { '/etc/pam.d/common-session':
      ensure  => file,
      content => epp('central_auth/suse-pam-session', {
                                                        enable_sssd => $enable_sssd,
                                                        dcredit     => $dcredit,
                                                        difok       => $difok,
                                                        lcredit     => $lcredit,
                                                        ucredit     => $ucredit,
                                                        ocredit     => $ocredit,
                                                        minlen      => $minlen,
                                                      } ),
    }
  } elsif $::osfamily == 'Debian' {
    file { '/etc/pam.d/login':
      ensure  => file,
      content => epp('central_auth/debian-pam-login', {} ),
    }
    file { '/etc/pam.d/sshd':
      ensure  => file,
      content => epp('central_auth/debian-pam-sshd', {} ),
    }
    file { '/etc/pam.d/common-password':
      ensure  => file,
      content => epp('central_auth/debian-pam-password', { enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-auth':
      ensure  => file,
      content => epp('central_auth/debian-pam-auth', { enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-account':
      ensure  => file,
      content => epp('central_auth/debian-pam-account', {  enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-session':
      ensure  => file,
      content => epp('central_auth/debian-pam-session', {  enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-session-noninteractive':
      ensure  => file,
      content => epp('central_auth/debian-pam-session-noninteractive', {  enable_sssd => $enable_sssd } ),
    }
    if $enable_pam_access {
      file { $access_conf:
        ensure  => file,
        content => epp('central_auth/access.conf', { allowed_groups => $allowed_groups, allowed_users => $allowed_users } ),
      }
    }
  }
}
