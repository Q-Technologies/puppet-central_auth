
class central_auth::service (
  # Class parameters are populated from External(hiera)/Defaults/Fail
) {

  if versioncmp( $::operatingsystemrelease, '7' ) < 0 {
    $messagebus = 'messagebus'
  }
  else {
    $messagebus = 'dbus'
  }

  if $auth::enable_sssd {
    $service_state = 'running'
  } else {
    $service_state = 'stopped'
  }

  service { 'sssd':
    ensure => $service_state,
    enable => $auth::enable_sssd,
    tag    => undef,
  }

  if $::osfamily == "RedHat" and $auth::enable_sssd {
    service { 'oddjobd':
      ensure  => running,
      enable  => true,
      require => Service[$messagebus],
    }
  
    if versioncmp( $::operatingsystemrelease, '7' ) < 0 {
      service { $messagebus:
        ensure => running,
        enable => true,
      }
    }
    else {
      service { $messagebus:
        ensure => running,
      }
    }
  }

}
