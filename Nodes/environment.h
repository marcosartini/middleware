#ifndef __ENVIRONMENT_H
#define __ENVIRONMENT_H


enum{
	AM_AVG_MSG = 231,
	AM_COLLECT_MSG = 241,
	COL_AVG = 242,
	DIS_COLLECT = 243,
	TMILLI_PERIOD = 1024
};
/*
typedef nx_struct message_t{
	nx_uint8_t header[sizeof(message_header_t)];
	nx_uint8_t data[TOSH_DATA_LENGTH];
	nx_uint8_t footer[sizeof(message_footer_t)];
	nx_uint8_t metadata[sizeof(message_metadata_t)];
} message_t;*/

typedef nx_struct{
	nx_uint8_t root_id;
	nx_uint32_t msg_id; //+ send id
} collect_t;

typedef nx_struct{
	nx_uint8_t temperature;
	nx_uint8_t humidity;
	nx_uint8_t node_id;
} avg_t;

#endif
