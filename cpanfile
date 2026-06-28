requires 'perl', 'v5.40';

requires 'meta';
requires 'Path::Tiny';
requires 'Const::Fast';
requires 'Object::Pad';
requires 'List::Util';
requires 'TOML::Tiny';
requires 'Net::SSLeay';
requires 'Syntax::Keyword::Dynamically';
requires 'Time::Piece';
requires 'Time::Moment';
requires 'Const::Fast::Exporter';
requires 'File::chdir';
requires 'IPC::Nosh';
requires 'IO::Handle::Common';
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
