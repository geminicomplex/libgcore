/*
 * Utility Helper Functions
 *
 */

// support for files larger than 2GB limit
#ifndef _LARGEFILE_SOURCE
#define _LARGEFILE_SOURCE
#endif
#ifndef _LARGEFILE64_SOURCE
#define _LARGEFILE64_SOURCE
#endif

#include "common.h"
#include "util.h"

#include "lib/jsmn/jsmn.h"

#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <stdbool.h>
#include <fcntl.h>
#include <inttypes.h>

/*
 * Helper file open function that performs checks.
 *
 */
int util_fopen(const char *file_path, int *fd, FILE **fp, off_t *file_size){
    int s = 0;
    struct stat st;

    if(file_path == NULL){
        perror("No path path given.");
        s = errno;
        goto error;
    }

	*fd = open(file_path, O_RDONLY);
	if (*fd == -1) {
		perror("Error opening file for reading.");
        s = errno;
        goto error;
	}

	*fp = fdopen(*fd, "r");
	if (*fp == NULL) {
		perror("Failed to open path given.");
	    s = errno;
        goto error;
	}

	// ensure that the file is a regular file
	if (fstat(*fd, &st) != 0) {
		perror("Failed to fstat");
	    s = errno;
        goto error;
	}

	if (!S_ISREG(st.st_mode)) {
		perror("File given is not a regular file");
	    s = errno;
        goto error;
	}

    if (fseeko(*fp, 0 , SEEK_END) != 0) {
		perror("Failed to seek to end of file.");
	    s = errno;
        goto error;
	}

	*file_size = ftello(*fp);
	if (*file_size == -1) {
	    perror("Failed to get file size.");
        s = errno;
        goto error;
	}

    if(fseeko(*fp, 0 , SEEK_SET) != 0) {
        s = errno;
	    goto error;
    }
error:
    return s;
}

/*
 * Returns a malloced array of 64 bit values with size num_bytes.
 *
 */
uint64_t* util_get_rand_data(size_t num_bytes){
	uint64_t num;
	uint64_t *data;

	if((data=(uint64_t*)malloc(num_bytes)) == NULL){
		return NULL;
	}

	for(uint32_t i=0; i<(num_bytes/sizeof(uint64_t)); i++) {
        num = rand();
		num = (num << 32) | rand();
		memcpy((uint8_t*)data+(i*sizeof(uint64_t)), &num, sizeof(uint64_t));
	}
	return data;
}

/*
 * Return array of 64 bit values, repeating every 16 words, up to number of
 * bytes.
 *
 */
uint64_t* util_get_static_data(size_t num_bytes, bool include_xor_data, bool clear_xor_results){
    uint64_t num;
	uint64_t *data;

	if((data=(uint64_t*)calloc(num_bytes, sizeof(uint8_t))) == NULL){
		return NULL;
	}

    const uint64_t static_data[16] = {
        0x0101020201010202,
        0x1212131312121313,
        0x2323242423232424,
        0x3434353534343535,
        0x4545464645454646,
        0x5656575756565757,
        0x6767686867676868,
        0x7878797978787979,
        0x89898a8a89898a8a,
        0x9a9a9b9b9a9a9b9b,
        0xababacacababacac,
        0xbcbcbdbdbcbcbdbd,
        0xcdcdcececdcdcece,
        0xdededfdfdededfdf,
        0xf0f0f1f1f0f0f1f1,
        0xffff0000ffff0000
    };

    const uint64_t xor_data[16] = {
        0x80335E3657B5222D,
        0x4C07BE35966A1271,
        0x028C0C3490C566DF,
        0xDD98D879E3DDE963,
        0x51B19498CF78C728,
        0x9D85749B0EA7F774,
        0x450249DAB7CFD9A8,
        0xBC56F50AA15829D4,
        0x61C62A80CFC4DEB4,
        0xADF2CA830E1BEEE8,
        0xE379788208B49A46,
        0x3C6DACCF7BAC15FA,
        0xB044E02E57093BB1,
        0x7C70002D96D60BED,
        0x5DA381BC3929D54D,
        0x7CADD7A9F10BA91D
    };

    int xor_count = 0;

	for(uint32_t i=0; i<(num_bytes/sizeof(uint64_t)); i++) {
        if(include_xor_data && ((i+32) % 128 == 0 || xor_count > 0)) {
            if(xor_count < 16 || !clear_xor_results) {
                num = xor_data[i%16];
            } else {
                num = 0x0000000000000000;
            }
            xor_count++;
            if(xor_count == 32) {
                xor_count = 0;
            }
        } else {
            num = static_data[i%16];
        }
        data[i] = num;
	}
	return data;
}

/*
 * Returns a malloced array of 64 bit values in incrementing order with 
 * size num_bytes.
 *
 */
uint64_t* util_get_inc_data(size_t num_bytes){
	uint64_t *data;

	if((data=(uint64_t*)malloc(num_bytes)) == NULL){
		return NULL;
	}

	for(uint64_t i=0; i<(num_bytes/sizeof(uint64_t)); i++) {
        data[i] = i;
	}
	return data;
}

/*
 * JSMN JSON helper function takes a json string and a jsmn token and
 * returns 0 if the string is equal to the token.
 *
 */
int util_jsmn_eq(const char *json, jsmntok_t *tok, const char *s) {
	if (tok->type == JSMN_STRING && (int) strlen(s) == tok->end - tok->start &&
			strncmp(json + tok->start, s, tok->end - tok->start) == 0) {
		return 0;
	}
	return -1;
}

/*
 * Return the file extension of the basename of the given path.
 * Just return a pointer to the extension in the same string.
 * Do not free this pointer. It is not a copy.
 *
 */
const char *util_get_file_ext_by_path(const char *path) {
    const char *base = basename((char *)path);
    const char *dot = strrchr(base, '.');
    if(!dot || dot == base) return "";
    return (dot + 1);
}


size_t util_str_split(char* a_str, const char a_delim, char*** results){
    size_t count = 0;
    char* tmp = a_str;
    char* last_delim = 0;
    char delim[2];
    size_t idx  = 0;

    delim[0] = a_delim;
    delim[1] = '\0';

    /* Count how many elements will be extracted. */
    while (*tmp){
        if (a_delim == *tmp){
            count++;
            last_delim = tmp;
        }
        tmp++;
    }

    /* Add space for trailing token. */
    count += last_delim < (a_str + strlen(a_str) - 1);

    if(((*results) = malloc(sizeof(char*) * count)) == NULL){
        die("malloc failed for count %zu\n", count);
    }

    char* token = strtok(a_str, delim);

    while(token){
        if(idx >= count){
            die("str split failed; idx %zu >= count %zu\n", idx, count);
        }
        *((*results) + idx++) = strdup(token);
        token = strtok(0, delim);
    }

    if(idx != count){
        die("str split failed; idx %zu != count - 1: %zu\n", idx, count);
    }

    return count;
}



