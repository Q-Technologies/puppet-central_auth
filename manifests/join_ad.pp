
class central_auth::join_ad (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  String $domain_user = '',
  String $domain_pass = '',
  String $domain_ou = '',

) {

  include stdlib;

  if $central_auth::enable_sssd and $central_auth::directory_type == 'ad' {

    # Fail if the class parameters are still empty
    if empty($domain_user) or empty($domain_pass) or empty($domain_ou) {
      fail('central_auth::join_ad needs domain_user, domain_pass and domain_ou set')
    }

    # Put the Python expect wrapper in place for kinit command
    file { "/usr/local/sbin/kinit_wrapper.py":
      ensure  => "present",
      owner   => "root",
      group   => "root",
      mode    => '0755',
      content => epp('central_auth/kinit_wrapper.py', { default_realm => $central_auth::config::default_realm } ),
    }
    # Run kinit command
    -> exec { 'first kinit':
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}" ],
      unless      => "bash -c 'id ${domain_user} && /usr/bin/klist' >/dev/null 2>&1",
      command     => '/usr/local/sbin/kinit_wrapper.py',
    }
    # Run net join command
    -> exec { 'net join':
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      unless      => '/usr/bin/net ads testjoin -k >/dev/null 2>&1',
      environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}" ],
      command     => "/usr/bin/net ads join createcomputer=\"${domain_ou}\" -U \$DOMAIN_USER%\$DOMAIN_PASS 2>&1",
      notify      => Service['sssd'],
    }
    
    # Obtain Kerboros ticket based on hostname
    [1,2,3,4,5,6,7,8,9,10].each | Integer $i | {
      exec { "try ${i} for machine ticket":
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        command     => 'sleep 5 && kinit -k $(hostname -s | tr \'[a-z]\' \'[A-Z]\')$ || bash -c "exit 0"',
        onlyif      => "klist -l | grep krb5cc_0 | grep -i ${domain_user} >/dev/null",
        environment => [ "DOMAIN_USER=${domain_user}", "DOMAIN_PASS=${domain_pass}", "KRB5CCNAME=/tmp/krb5cc_0" ],
        require     => Exec['net join'],
        notify      => Service['sssd'],
      }
    }
  }

}
