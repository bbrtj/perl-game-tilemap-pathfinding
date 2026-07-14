#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef true
	#include <stdbool.h>
#endif

typedef struct FIFO FIFO;

struct FIFO {
	int *buffer;
	int head;
	int tail;
	int count;
	int capacity;
};

FIFO* fifo_create (int capacity)
{
	FIFO *f = malloc(sizeof *f);

	f->buffer = malloc(capacity * sizeof *(f->buffer));
	f->capacity = capacity;
	f->head = 0;
	f->tail = 0;
	f->count = 0;

	return f;
}

void fifo_destroy (FIFO *f)
{
	free(f->buffer);
	free(f);
}

void fifo_push (FIFO *f, int value)
{
	/* NOTE: overflow is not handled - capacity must be big enough */

	f->buffer[f->tail] = value;
	f->tail = (f->tail + 1) % f->capacity;
	f->count++;
}

int fifo_pop (FIFO *f)
{
	/* NOTE: underflow is not handled - count must be checked manually */

	int value = f->buffer[f->head];
	f->head = (f->head + 1) % f->capacity;
	f->count--;

	return value;
}

bool find_path(int *costs, int *visited, int size, int size_y, int current, int end)
{

	return false;
}

AV* do_pathfinding (float *costs, int size_x, int size_y, int x1, int y1, int x2, int y2)
{
	int size = size_x * size_y;
	int start = x1 * size_y + y1;
	int end = x2 * size_y + y2;
	int i;

	if (
			x1 < 0 || y1 < 0 || x2 < 0 || y2 < 0
			|| x1 >= size_x || y1 >= size_y || x2 >= size_x || y2 >= size_y
		)
		return NULL;

	if (start == end)
		return newAV();

	float *visited = malloc(size * sizeof *visited);
	for (i = 0; i < size; ++i) {
		visited[i] = -1;
	}

	FIFO *next = fifo_create((size_x + size_y) * 2);
	AV *result = NULL;

	fifo_push(next, start);
	visited[start] = 0;

	int current;
	int sides[4];

	while (next->count > 0) {
		current = fifo_pop(next);
		float current_value = visited[current];
		sides[0] = current % size_y == size_y - 1 ? size : current + 1;
		sides[1] = current % size_y == 0 ? size : current - 1;
		sides[2] = current + size_y;
		sides[3] = current - size_y;

		for (i = 0; i < 4; ++i) {
			/* out of bounds */
			if (sides[i] >= size || sides[i] < 0)
				continue;

			/* already visited */
			if (visited[sides[i]] >= 0)
				continue;

			/* not reachable */
			if (costs[sides[i]] < 0)
				continue;

			visited[sides[i]] = current_value + costs[sides[i]];

			/* found destination */
			if (sides[i] == end) {
				break;
			}

			fifo_push(next, sides[i]);
		}

		/* backtrack to find path */
		/* TODO: find longest straight paths */
		/* TODO: find safe diagonal paths */
		if (visited[end] > 0) {
			result = newAV();
			current = end;

			while (current != start) {
				SV *val_x = newSViv(current / size_y);
				SV *val_y = newSViv(current % size_y);
				av_unshift(result, 2);
				if (av_store(result, 0, val_x) == NULL || av_store(result, 1, val_y) == NULL) {
					SvREFCNT_dec(val_x);
					SvREFCNT_dec(val_y);
					free(visited);
					fifo_destroy(next);
					croak("could not store pathfinding coordinates in an AV");
				}

				float min = visited[current];
				sides[0] = current % size_y == size_y - 1 ? size : current + 1;
				sides[1] = current % size_y == 0 ? size : current - 1;
				sides[2] = current + size_y;
				sides[3] = current - size_y;

				for (i = 0; i < 4; ++i) {
					/* out of bounds */
					if (sides[i] >= size || sides[i] < 0)
						continue;

					if (visited[sides[i]] >= 0 && visited[sides[i]] < min) {
						current = sides[i];
						min = visited[current];
					}
				}
			}

			break;
		}
	}

	free(visited);
	fifo_destroy(next);

	return result;
}

SV* get_hash_key (HV* hash, const char* key, int len)
{
	SV **value = hv_fetch(hash, key, len, 0);

	if (value == NULL) return NULL;
	return *value;
}

MODULE = Game::TileMap::Pathfinding				PACKAGE = Game::TileMap::Pathfinding

PROTOTYPES: DISABLE

void
_prepare(self)
		SV *self
	CODE:
		HV *self_hash = (HV*) SvRV(self);
		SV *map = get_hash_key(self_hash, "map", 3);
		int size_x = SvIV(get_hash_key(self_hash, "_map_size_x", 11));
		int size_y = SvIV(get_hash_key(self_hash, "_map_size_y", 11));

		dSP;

		int count;
		float *costs = malloc(size_x * size_y * sizeof *costs);
		int i, j;
		for (i = 0; i < size_x; ++i) {
			for (j = 0; j < size_y; ++j) {
				PUSHMARK(SP);
				EXTEND(SP, 3);
				PUSHs(map);
				mPUSHi(i);
				mPUSHi(j);
				PUTBACK;
				count = call_method("check_can_be_accessed", G_SCALAR);
				SPAGAIN;

				if (count != 1) {
					croak("Calling check_can_be_accessed went wrong while preparing the pathfinding");
				}

				SV *result = POPs;
				costs[i * size_y + j] = SvTRUE(result) ? 1 : -1;
			}
		}

		SV *map_data = newSViv((uintptr_t) costs);
		SvREADONLY_on(map_data);
		hv_stores(self_hash, "_map_data", map_data);

SV*
_find_path(self, x1, y1, x2, y2)
		SV *self
		int x1
		int y1
		int x2
		int y2
	CODE:
		HV *self_hash = (HV*) SvRV(self);
		int size_x = SvIV(get_hash_key(self_hash, "_map_size_x", 11));
		int size_y = SvIV(get_hash_key(self_hash, "_map_size_y", 11));

		float *costs = (float*) SvIV(get_hash_key(self_hash, "_map_data", 9));

		AV *result = do_pathfinding(costs, size_x, size_y, x1, y1, x2, y2);
		if (result != NULL)
			RETVAL = newRV_inc((SV*) result);
		else
			RETVAL = NULL;
	OUTPUT:
		RETVAL

void
_cleanup(self)
		SV *self
	CODE:
		SV *value = get_hash_key((HV*) SvRV(self), "_map_data", 9);
		if (value != NULL) {
			float *costs = (float*) SvIV(value);
			free(costs);
		}

