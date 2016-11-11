//ZeroMQ
#include <zeromq/zmq.h>

#include <iostream>
#include <string>
#include <vector>
#include <list>
#include <map>

//boost
#include <boost/thread.hpp>

//gtest
#include <gtest/gtest.h>

//Libevent
#include <libevent/evhttp.h>

#define ARRAY_SIZE(array ) (sizeof(array) / sizeof(array[0]))

#ifdef WIN32
	#define SLEEP(ms) Sleep(ms)
#else
	#define SLEEP(ms) sleep(ms/1000)
#endif
