requires 'perl', 'v5.40';

requires 'meta';
requires 'Path::Try', '0.01_1', dist => 'CRABAPP/Path-Try-0.01_1-TRIAL.tar.gz';
requires 'Const::Fast';
requires 'Object::Pad';
requires 'List::Util';
requires 'TOML::Tiny';
requires 'Net::SSLeay';
requires 'Syntax::Keyword::Try';
requires 'Syntax::Keyword::Dynamically';
requires 'Time::Piece';
requires 'Time::Moment';
requires 'File::chdir';

requires 'IO::Handle::Common', '0.01.1',
  dist => "CRABAPP/IO-Handle-Common-0.01.1-TRIAL.tar.gz";
  
requires 'IPC::Nosh', '0.01.4',
  dist => "CRABAPP/IO-Nosh-0.01.4-TRIAL.tar.gz";

requires 'Text::Xslate';
requires 'File::XDG';
requires 'File::HomeDir';

on 'test' => sub {
    requires 'Module::Build::Tiny';
    requires 'Test::More', '0.98';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::Pod';
    requires 'Test::Spellunker';
};

on 'develop' => sub {
    requires 'Perl::Critic';
    requires 'Perl::Critic::Community';
    requires 'Devel::Trace';
    requires 'Perl::Tidy';
    requires 'Minilla';
    requires 'App::FatPacker';
    requires 'inc::latest';
    requires 'Software::License';
    requires 'Module::Build';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build::Tiny';
    requires 'Module::Signature';
}
