use strict;
use warnings;

use Game::TileMap::Pathfinding;
use Game::TileMap;
use Benchmark::Dumb qw(timethese);

my $legend = Game::TileMap->new_legend;
$legend
	->add_wall('#')
	->add_void('.')
	->add_terrain('_' => 'pavement')
	->add_terrain('?' => 'waypoint')
	;

my $map_str = <<MAP;
	###############
	#_____######_##
	#####_#_###____
	##__________##_
	##_#######?_##_
	##_########_###
	##_______##___#
	########__###_#
	______#######_#
	_##____________
	_##_?##########
	_#______#____##
	#__####____####
	#_#####_#######
	#######______##
MAP

my $map = Game::TileMap->new(
	legend => $legend,
	map => $map_str
);

my $pf = Game::TileMap::Pathfinding->new(map => $map);
my $pf_d = Game::TileMap::Pathfinding->new(map => $map, diagonal_movement => !!1);

timethese 200.01, {
	find_path_create => sub {
		my $pf = Game::TileMap::Pathfinding->new(map => $map);
		die unless defined $pf->find_path(4, 4, 10, 10);
	},
	find_path => sub {
		die unless defined $pf->find_path(4, 4, 10, 10);
	},
	find_path_diagonal => sub {
		die unless defined $pf_d->find_path(4, 4, 10, 10);
	},
};

