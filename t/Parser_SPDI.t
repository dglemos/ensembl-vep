# Copyright [2016-2018] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin qw($Bin);

use lib $Bin;
use VEPTestingConfig;
my $test_cfg = VEPTestingConfig->new();

my ($vf, $tmp, $expected);

## BASIC TESTS
##############

# use test
use_ok('Bio::EnsEMBL::VEP::Parser::SPDI'); # 1

# need to get a config object and DB connection for further tests
use_ok('Bio::EnsEMBL::VEP::Config'); # 2

throws_ok {
  Bio::EnsEMBL::VEP::Parser::SPDI->new({
    config => Bio::EnsEMBL::VEP::Config->new({offline => 1}),
    file => $test_cfg->create_input_file('21:25585732:C:T') # 21:g.25585733C>T
  });
} qr/Cannot use SPDI format in offline mode/, 'throw without DB'; # 3

SKIP: {
  my $db_cfg = $test_cfg->db_cfg;

  eval q{
    use Bio::EnsEMBL::Test::TestUtils;
    use Bio::EnsEMBL::Test::MultiTestDB;
    1;
  };

  my $can_use_db = $db_cfg && scalar keys %$db_cfg && !$@;

  ## REMEMBER TO UPDATE THIS SKIP NUMBER IF YOU ADD MORE TESTS!!!!
  skip 'No local database configured', 2 unless $can_use_db; # 4 - 5

  my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_vepiens');

  my $cfg = Bio::EnsEMBL::VEP::Config->new({
    %$db_cfg,
    database => 1,
    offline => 0,
    species => 'homo_vepiens',
    warning_file => 'STDERR',
  });

  my $p = Bio::EnsEMBL::VEP::Parser::SPDI->new({
    config => $cfg,
    file => $test_cfg->create_input_file('21:25585732:C:T'),
    valid_chromosomes => [21],
  });

  is(ref($p), 'Bio::EnsEMBL::VEP::Parser::SPDI', 'class ref'); # 4

  $expected = bless( {
    'source' => undef,
    'is_somatic' => undef,
    'clinical_significance' => undef,
    'display' => undef,
    'dbID' => undef,
    'minor_allele_count' => undef,
    'seqname' => undef,
    'strand' => 1,
    'evidence' => undef,
    '_variation_id' => undef,
    'class_SO_term' => undef,
    'allele_string' => 'C/T',
    'map_weight' => 1,
    'chr' => '21',
    '_source_id' => undef,
    'analysis' => undef,
    'end' => 25585733,
    'seq_region_end' => 25585733,
    'minor_allele_frequency' => undef,
    'overlap_consequences' => undef,
    'minor_allele' => undef,
    'start' => 25585733,
    'seq_region_start' => 25585733
  }, 'Bio::EnsEMBL::Variation::VariationFeature' );

  $vf = $p->next();
  delete($vf->{$_}) for qw(adaptor variation slice variation_name _line);
  is_deeply($vf, $expected, 'genomic'); # 5

  

  # capture warning
  no warnings 'once';
  open(SAVE, ">&STDERR") or die "Can't save STDERR\n";

  close STDERR;
  open STDERR, '>', \$tmp;

  1;
};




done_testing();
