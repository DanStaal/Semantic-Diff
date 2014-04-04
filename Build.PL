use Module::Build;

# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name   => 'Text::SemanticDiff',
    license       => 'perl',
    dist_author   => 'Daniel Staal - <DStaal@usa.net>',
    dist_abstract => 'Create Semantic Diffs of Text Files.',
    create_readme => 1,
    requires      => {
                  perl            => 'v5.10.0',
                  Algorithm::Diff => '1.1902',
                },
    test_requires => { Test::Differences => '0', },

    # These are volatile.
    release_status => 'unstable',
                  )->create_build_script;