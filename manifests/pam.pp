# == Class: auth::pam
#
# Class to manage PAM for CrackLib and SSSD
#
class auth::pam (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Integer $dcredit                   = -1,
  Integer $difok                     = 5,
  Integer $lcredit                   = -1,
  Integer $ucredit                   = -1,
  Integer $ocredit                   = -1,
  Integer $minlen                    = 17,

  Boolean $enable_sssd                = $auth::enable_sssd,

){

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  #class { 'authconfig': }

  if $::osfamily == 'RedHat' {
    file { [ '/etc/pam.d/system-auth', '/etc/pam.d/password-auth' ] :
      ensure  => file,
      content => epp('auth/rhel-pam-auth', { enable_sssd => $enable_sssd,
                                             dcredit     => $dcredit,
                                             difok       => $difok,
                                             lcredit     => $lcredit,
                                             ucredit     => $ucredit,
                                             ocredit     => $ocredit,
                                             minlen      => $minlen,
                                         } ),
    }
  } elsif $::osfamily == 'Suse' {
    file { '/etc/pam.d/common-password':
      ensure  => file,
      content => epp('auth/suse-pam-password', { enable_sssd => $enable_sssd,
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
      content => epp('auth/suse-pam-auth', { enable_sssd => $enable_sssd,
                                             dcredit     => $dcredit,
                                             difok       => $difok,
                                             lcredit     => $lcredit,
                                             ucredit     => $ucredit,
                                             ocredit     => $ocredit,
                                             minlen      => $minlen,
                                               } ),
    }
    file { '/etc/pam.d/common-account':
      ensure  => file,
      content => epp('auth/suse-pam-account', {  enable_sssd => $enable_sssd,
                                                 dcredit     => $dcredit,
                                                 difok       => $difok,
                                                 lcredit     => $lcredit,
                                                 ucredit     => $ucredit,
                                                 ocredit     => $ocredit,
                                                 minlen      => $minlen,
                                               } ),
    }
    file { '/etc/pam.d/common-session':
      ensure  => file,
      content => epp('auth/suse-pam-session', {  enable_sssd => $enable_sssd,
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
      content => epp('auth/debian-pam-login', {} ),
    }
    file { '/etc/pam.d/sshd':
      ensure  => file,
      content => epp('auth/debian-pam-sshd', {} ),
    }
    file { '/etc/pam.d/common-password':
      ensure  => file,
      content => epp('auth/debian-pam-password', { enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-auth':
      ensure  => file,
      content => epp('auth/debian-pam-auth', { enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-account':
      ensure  => file,
      content => epp('auth/debian-pam-account', {  enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-session':
      ensure  => file,
      content => epp('auth/debian-pam-session', {  enable_sssd => $enable_sssd } ),
    }
    file { '/etc/pam.d/common-session-noninteractive':
      ensure  => file,
      content => epp('auth/debian-pam-session-noninteractive', {  enable_sssd => $enable_sssd } ),
    }
    
  }

}
