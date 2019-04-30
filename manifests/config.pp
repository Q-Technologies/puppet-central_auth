# Configuration for the central_auth  module
class central_auth::config (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Optional[String] $ad_gpo_access_control,
  String $default_domain             = '',
  String $admin_server               = lookup( 'central_auth::config::default_domain', String, 'first', '' ),
  String $ad_domain                  = '',
  String $ad_server                  = '',
  String $ad_backup_server           = '',
  String $ad_site_name               = '',
  Integer $service_ping_timeout      = 60,
  String $default_realm              = lookup( 'central_auth::config::default_domain', String, 'first', '' ),
  Collection $passwd_servers         = [],
  Boolean $dns_lookup_kdc            = true,
  Boolean $dns_lookup_realm          = true,
  Boolean $forwardable               = true,
  String $directory_type             = 'ad',
  String $ticket_lifetime            = '2d',
  String $renew_lifetime             = '30d',
  Boolean $dyndns_update             = true,
  Integer $dyndns_refresh_interval   = 43200,
  Boolean $dyndns_update_ptr         = true,
  Integer $dyndns_ttl                = 3600,

  Integer $ldap_idmap_range_size     = 200000,
  Boolean $ldap_id_mapping           = false,
  String $ldap_tls_cacert            = '',
  Boolean $cache_credentials         = true,
  Boolean $case_sensitive            = false,
  Any $override_shell                = '/bin/bash',
  Any $override_homedir              = '/home/%u',

  Integer $sssd_debug_level          = 0,
  String $ldap_uri                   = '',
  String $user_ou_path               = '',
  String $group_ou_path              = '',
  String $bind_user                  = lookup( 'central_auth::join_ad::domain_user', String, 'first', '' ),
  String $bind_pass                  = lookup( 'central_auth::join_ad::domain_pass', String, 'first', '' ),

  String $smb_template               = 'central_auth/smb.conf',
) {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  if ( $::osfamily == 'Suse' and ($::operatingsystemmajrelease + 0) < 12 )
    or ( $facts['os']['name'] == 'Ubuntu' and ($::operatingsystemmajrelease + 0) < 13 ) {
    if $directory_type == 'ad' {
      $sssd_template = 'central_auth/sssd.conf.AD_LDAP'
    } elsif $directory_type == 'openldap' {
      $sssd_template = 'central_auth/sssd.conf.OPENLDAP'
    } else{
        fail("Unknown directory type: ${directory_type}")
    }
  } else {
    $sssd_template = 'central_auth/sssd.conf.AD'
  }
  $krb5_template = 'central_auth/krb5.conf.AD'


  if $central_auth::enable_sssd {

    if ! $default_domain {
      fail('The default domain cannot be empty: central_auth::config::default_domain')
    }

    if $directory_type == 'ad' {
      # When connecting to AD, utilise Kerberos and set up Samba client
      file { '/etc/krb5.conf':
        ensure  => file,
        content => epp($krb5_template, {
                                        admin_server     => $admin_server,
                                        default_domain   => $default_domain,
                                        default_realm    => $default_realm,
                                        dns_lookup_realm => $dns_lookup_realm,
                                        dns_lookup_kdc   => $dns_lookup_kdc,
                                        ticket_lifetime  => $ticket_lifetime,
                                        renew_lifetime   => $renew_lifetime,
                                        forwardable      => $forwardable,
                                      } ),
        notify  => Service['sssd'],
      }

      file { '/etc/samba':
        ensure  => directory,
      }

      $dr_arr = split($default_realm, '\.')
      $addomain = $dr_arr[0]
      #file { '/etc/samba/smb.conf':
      #ensure  => file,
      #content => epp($smb_template, { default_realm => $default_realm, addomain => $addomain }),
      #}
      ini_setting { 'smb kerberos method':
        ensure  => present,
        path    => '/etc/samba/smb.conf',
        section => 'global',
        setting => 'kerberos method',
        value   => 'secrets and keytab',
      }
      ini_setting { 'smb workgroup':
        ensure  => present,
        path    => '/etc/samba/smb.conf',
        section => 'global',
        setting => 'workgroup',
        value   => $addomain.upcase,
      }
      ini_setting { 'smb realm':
        ensure  => present,
        path    => '/etc/samba/smb.conf',
        section => 'global',
        setting => 'realm',
        value   => $default_realm.upcase,
      }
      ini_setting { 'smb security':
        ensure  => present,
        path    => '/etc/samba/smb.conf',
        section => 'global',
        setting => 'security',
        value   => 'ADS',
      }
      if !empty($passwd_servers) {
        ini_setting { 'smb password server':
          ensure  => present,
          path    => '/etc/samba/smb.conf',
          section => 'global',
          setting => 'password server',
          value   => $passwd_servers.join(' '),
        }
      }

    }

    file { '/etc/sssd':
      ensure => directory,
      mode   => '0700',
    }

    $dc1 = split($default_domain, '\.')
    $dc2 = join($dc1,',DC=')
    $dc  = "DC=${dc2}"

    exec { 'clean_sssd_cache.sh':
      command     => 'clean_sssd_cache.sh',
      path        => '/usr/local/sbin/:/bin',
      subscribe   => File[$central_auth::install::clean_sssd_cache_script],
      refreshonly => true,
    }

    file { '/etc/sssd/sssd.conf':
      ensure  => file,
      content => epp($sssd_template, {
                                      default_domain          => $default_domain,
                                      admin_server            => $admin_server,
                                      ad_domain               => $ad_domain,
                                      ad_server               => $ad_server,
                                      ad_backup_server        => $ad_backup_server,
                                      ad_gpo_access_control   => $ad_gpo_access_control,
                                      host_fqdn               => $facts['fqdn'],
                                      ad_site_name            => $ad_site_name,
                                      timeout                 => $service_ping_timeout,
                                      ldap_idmap_range_size   => $ldap_idmap_range_size,
                                      ldap_id_mapping         => $ldap_id_mapping,
                                      ldap_tls_cacert         => $ldap_tls_cacert,
                                      cache_credentials       => $cache_credentials,
                                      case_sensitive          => $case_sensitive,
                                      override_shell          => $override_shell,
                                      override_homedir        => $override_homedir,
                                      debug_level             => $sssd_debug_level,
                                      ldap_uri                => $ldap_uri,
                                      user_ou_path            => $user_ou_path,
                                      group_ou_path           => $group_ou_path,
                                      bind_user               => $bind_user,
                                      bind_pass               => $bind_pass,
                                      dc                      => $dc,
                                      dyndns_update           => $dyndns_update,
                                      dyndns_refresh_interval => $dyndns_refresh_interval,
                                      dyndns_update_ptr       => $dyndns_update_ptr,
                                      dyndns_ttl              => $dyndns_ttl,
                                    } ),
      mode    => '0600',
      notify  => Exec['clean_sssd_cache.sh'],
    }

    if $::osfamily == 'RedHat' {
      file { '/etc/oddjobd.conf.d/oddjobd-mkhomedir.conf':
        ensure => file,
        source => 'puppet:///modules/central_auth/oddjobd-mkhomedir.conf',
        notify => Service['oddjobd'],
      }
    }

    file { '/etc/nsswitch.conf':
      ensure  => file,
      content => epp('central_auth/nsswitch.conf'),
      require => File['/etc/sssd/sssd.conf'],
    }

    # Set the authconfig settings to reflect what we are setting - even though authconfig is not being used
    if $::osfamily == 'RedHat' {
      augeas { 'sysconfig-authconfig-sssd':
        context => '/files/etc/sysconfig/authconfig',
        changes => [
          'set USEMKHOMEDIR yes',
          'set USESSSDAUTH yes',
          'set USESSSD yes',
        ],
      }
    }
  }

}
