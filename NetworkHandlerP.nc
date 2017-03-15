#include "message.h"

module NetworkHandlerP{
	uses interface Boot;
	uses interface Receive;
	
	provides interface AMSend;
	
}

implementation {
	
	command error_t send(am_addr_t addr, message_t * msg, uint8_t len){
	
	
}

	
}