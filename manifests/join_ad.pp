
# Class to perform the AD join for central_auth
class central_auth::join_ad (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  String $domain_user = '',
  String $domain_pass = '',
  String $domain_ou = '',
  String $default_domain = lookup( 'central_auth::config::default_domain', String, 'first', '' ),
) {

  include stdlib;

  $domain_components = split($default_domain, '[.]')
  $full_ou = join([$domain_ou, ',DC=', join($domain_components, ',DC=')], '')

  if $central_auth::enable_sssd and $central_auth::config::directory_type == 'ad' {

    # Fail if the class parameters are still empty
    if empty($domain_user) or empty($domain_pass) or empty($domain_ou) {
      fail('central_auth::join_ad needs domain_user, domain_pass and domain_ou set')
    }

    # Put the Python expect wrapper in place for kinit command
    file { '/usr/local/sbin/kinit_wrapper.py':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => epp('central_auth/kinit_wrapper.py', { default_realm => $central_auth::config::default_realm } ),
    }

    # Run kinit command
    exec { 'first kinit':
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}" ],
      unless      => "bash -c 'id ${domain_user} && /usr/bin/klist' >/dev/null 2>&1",
      command     => '/usr/local/sbin/kinit_wrapper.py',
      require     => File['/usr/local/sbin/kinit_wrapper.py'],
    }

    # Run kinit command
    if ( $::osfamily == 'RedHat' and ($::operatingsystemmajrelease + 0) > 6 ) {
      exec { 'net join':
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        unless      => "/sbin/adcli testjoin --domain=${default_domain} >/dev/null 2>&1",
        environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}" ],
        command     => "/sbin/adcli join --login-ccache  --domain-ou=${full_ou}  ${default_domain} 2>&1",
        notify      => Service['sssd'],
        require     => Exec['first kinit'],
      }
    } else {
      # RHEL 6 and SuSE
      exec { 'net join':
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        unless      => '/usr/bin/net ads testjoin -k >/dev/null 2>&1',
        environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}" ],
        command     => "/usr/bin/net ads join createcomputer=\"${domain_ou}\" -U \$DOMAIN_USER%\$DOMAIN_PASS 2>&1",
        notify      => Service['sssd'],
        require     => Exec['first kinit'],
      }
    }

    # Obtain Kerboros ticket based on hostname
    [1,2,3,4,5,6,7,8,9,10].each | Integer $i | {
      exec { "try ${i} for machine ticket":
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        command     => 'sleep 5 && kinit -k $(hostname -s | tr \'[a-z]\' \'[A-Z]\')$ || bash -c "exit 0"',
        onlyif      => "klist -l | grep krb5cc_0 | grep -i ${domain_user} >/dev/null",
        environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}", 'KRB5CCNAME=/tmp/krb5cc_0' ],
        require     => Exec['net join'],
        notify      => Service['sssd'],
      }
    }

    if $facts['os']['family'] == 'Suse' {
      file { ['/run','/run/user','/run/user/0','/run/user/0/krb5cc']:
        ensure => directory,
        before => Exec['first kinit'],
      }
    }
  }

}
