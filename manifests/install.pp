# Class to install packages and scripts for central_auth module
class central_auth::install (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Collection $packages = [],
  String $renew_host_krbtgt_script = '/usr/local/sbin/renew_host_krbtgt.sh',
  String $clean_sssd_cache_script = '/usr/local/sbin/clean_sssd_cache.sh',
) {

  # make sure the required packages are installed
  package { $packages:
    ensure => present,
  }

  if $central_auth::enable_sssd {
    file { $clean_sssd_cache_script:
      ensure => 'present',
      owner  => 'root',
      group  => 'root',
      mode   => '0775',
      source => 'puppet:///modules/central_auth/clean_sssd_cache.sh',
    }
    file { $renew_host_krbtgt_script:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0744',
      source => 'puppet:///modules/central_auth/renew_host_krbtgt.sh',
    }
    #$cronhour = fqdn_rand(6) + 11 
    $cronhour = '*'
    $cronminute = fqdn_rand(60)
    cron { 'renew_host_krbtgt':
      command => $renew_host_krbtgt_script,
      user    => 'root',
      hour    => $cronhour,
      minute  => $cronminute,
      require => File[$renew_host_krbtgt_script],
    }
  }
}
