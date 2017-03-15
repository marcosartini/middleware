#ifndef __AVGMESSAGE_H
#define __AVGMESSAGE_H

enum{
	AM_AVG_MSG = 231,
	TMILLI_PERIOD = 1024;
};

typedef nx_struct message_t{
	nx_uint8_t header[sizeof(message_header_t)];
	nx_uint8_t data[TOSH_DATA_LENGTH];
	nx_uint8_t footer[sizeof(message_footer_t)];
	nx_uint8_t metadata[sizeof(message_metadata_t)];
} message_t;
