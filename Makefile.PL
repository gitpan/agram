use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'agram',
    AUTHOR              => 'Lincoln <ch.animalbar@gmail.com>',
    VERSION_FROM        => 'agram.pl',
    ABSTRACT_FROM       => 'agram.pl',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    EXE_FILES => [ 'agram.pl' ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'agram-*' },
);
