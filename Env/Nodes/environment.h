#ifndef __ENVIRONMENT_H
#define __ENVIRONMENT_H


enum{
	AM_ENV = 231,
	TMILLI_PERIOD = 1024
};


typedef nx_struct{
//	nx_uint8_t root_id;
	nx_uint32_t msg_id;
	nx_uint32_t sender_id;
} collect_t;

typedef nx_struct{
	nx_uint8_t temperature;
	nx_uint8_t humidity;
	nx_uint8_t node_id;
	nx_uint32_t local_id;
} avg_t;

#endif
