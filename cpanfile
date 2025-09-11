requires 'perl', 'v5.40';

requires 'Object::Pad';
requires 'IPC::Run3';
requires 'Path::Tiny';
requires 'Cwd';
requires 'File::chdir';
requires 'Net::SSLeay';
requires 'List::Util';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

