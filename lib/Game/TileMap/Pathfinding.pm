package Game::TileMap::Pathfinding;

use v5.14;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

use Game::TileMap::Pathfinding::Result;

require XSLoader;
XSLoader::load('Game::TileMap::Pathfinding', $Game::TileMap::Pathfinding::VERSION);

sub new
{
	my ($class, %args) = @_;

	my $map = $args{map};
	blessed $map && $map->isa('Game::TileMap')
		or croak 'map argument is required to be a Game::TileMap instance';

	my $self = bless {
		map => $map,
		max_distance => $args{max_distance} // undef,
		diagonal => $args{diagonal} // !!0,
		_map_size_x => $map->size_x,
		_map_size_y => $map->size_y,
	}, $class;

	$self->_prepare;

	return $self;
}

sub DESTROY
{
	my ($self) = @_;

	$self->_cleanup;
}

sub find_path
{
	my $self = shift;

	my $result = $self->_find_path(@_);
	return undef unless defined $result;
	return Game::TileMap::Pathfinding::Result->new($result);
}

1;

__END__

=head1 NAME

Game::TileMap::Pathfinding - BFS pathfinding for Game::TileMap

=head1 SYNOPSIS

	use Game::TileMap::Pathfinding;

	my $pf = Game::TileMap::Pathfinding->new(map => $game_tilemap_object);
	my $result = $pf->find_path($start_x, $start_y, $end_x, $end_y);

	die 'no path available'
		unless defined $result;

	say 'required steps: ' . $result->step_count;
	while (my ($x, $y) = $result->next_step) {
		say "next step is $x:$y";
	}

=head1 DESCRIPTION

This module is a fast Breadth-First Search pathfinding for Game::TileMap. For
speed, the core algorithm is implemented in XS.

Pathfinding instances can be reused indefinetly, but they don't actively track
changes on a map. They also don't consider anything other than walls or voids
as unreachable terrain. Moreover, all types of terrain have the exact same
movement cost, though this may be changed in the future.

=head2 Interface

=head3 new

	$pf = $class->new(%options)

This constructs a new pathfinding instance for a L<Game::TileMap> object.
C<%options> can be any of:

=over

=item * C<map>

This is a mandatory instance of a map. Location of walls and voids should not
change after creating a pathfinding instance - if they do, it's best to get rid
of the pathfinding object and create a new one.

=item * C<max_distance>

Work in progress

=item * C<diagonal>

Work in progress

=back

=head3 find_path

	$result = $pf->find_path($start_x, $start_y, $end_x, $end_y)

This method finds the shortest valid path from start to end. If no such path is
available, C<undef> is returned. If it is, an instance of
L<Game::TileMap::Pathfinding::Result> is returned.

Path is always returned as a series of steps to take to reach the end location.
Start location coordinates are never included in this path, so if start and end
location is the same, the result will have 0 steps (but will not be an undef).
First step is always the closest to the start location.

=head1 SEE ALSO

L<Game::TileMap>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

