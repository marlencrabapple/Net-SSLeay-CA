requires 'perl', 'v5.40';
requires 'overload';
requires 'meta';
requires 'Exporter::Tiny';
requires 'Exporter::Shiny';
requires 'Path::Tiny';
requires 'Const::Fast';
requires 'Object::Pad';
requires 'List::Util';
requires 'Net::SSLeay';
requires 'IPC::Run3';
requires 'Syntax::Keyword::Dynamically';
requires 'Syntax::Keyword::Defer';
requires 'Syntax::Keyword::MultiSub';
requires 'Devel::StackTrace::WithLexicals';
requires 'Time::Piece';
requires 'Time::Moment';
requires 'Const::Fast::Exporter';

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
    requires 'Perl::Tidy';
    requires 'Minilla';
    requires 'App::FatPacker';
    requires 'inc::latest';
    requires 'Software::License';
    requires 'Module::Build';
    requires 'Module::Build::Tiny';
    requires 'Module::Signature';
}
