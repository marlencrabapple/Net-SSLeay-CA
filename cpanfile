requires 'perl', 'v5.40';
requires 'Net::SSLeay';
requires 'Data::Dumper::Names';
requires 'IPC::Nosh';
requires 'Getopt::Long';
requires 'TOML::Tiny';

on test => sub {
    requires 'Test::More', '0.96';
};
