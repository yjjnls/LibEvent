#include <Common.h>


namespace
{
	bool stop = false;
	std::string host("127.0.0.1");
	uint16_t port = 9000;

	void ServerRequest(evhttp_request *request, void *arg)
	{
		evhttp_cmd_type cmd = evhttp_request_get_command(request);
		if (cmd != EVHTTP_REQ_POST)
		{
			return;
		}
		struct evbuffer *buf = evhttp_request_get_input_buffer(request);
		size_t size = evbuffer_get_length(buf);

		for (int i = 0; i < 2; ++i)
		{
			evbuffer* evb = evbuffer_new();
			ASSERT_TRUE(evb != NULL);
			std::string rsp("HelloWorld");
			ASSERT_TRUE(0 == evbuffer_add(evb, rsp.c_str(), rsp.size()));
			evhttp_send_reply(request, 200, "OK", evb);
			evbuffer_free(evb);
		}
		

	}
	void HttpServer(event_base *base, evhttp *http)
	{
		ASSERT_TRUE(0 == evhttp_set_cb(http, "/pub", ServerRequest, NULL));
		ASSERT_TRUE(0 == evhttp_bind_socket(http, host.c_str(), port));

		while (!stop)
		{
			event_base_dispatch(base);
		}

		
	}
	//////////////////////////////////////////////////////////////////////////
	void RequestDone(evhttp_request *request, void *arg)
	{
		int code = evhttp_request_get_response_code(request);
		ASSERT_TRUE(code == HTTP_OK);
		evbuffer* buf = evhttp_request_get_input_buffer(request);
		size_t len = evbuffer_get_length(buf);
		std::string result;
		result.append(static_cast<char *>(static_cast<void *>(evbuffer_pullup(buf, -1))), len);
		std::cout << result.c_str() << std::endl;
	}
	void HttpClient(event_base *base, evhttp_connection *connection)
	{
		
		struct evhttp_request *request = evhttp_request_new(RequestDone, NULL);//make request by connection
		evbuffer* buf = evhttp_request_get_output_buffer(request);
		std::string req("12345");
		evbuffer_add(buf, req.c_str(), req.size());

		ASSERT_TRUE(0 == evhttp_make_request(connection, request, EVHTTP_REQ_POST, "/pub"));

		while (!stop)
		{
			event_base_dispatch(base);
		}
	}
}

/******************************************************



******************************************************/
TEST(Libevent, PUB_SUB)
{
	stop = false;
	event_base *base_server = event_base_new();
	ASSERT_TRUE(base_server != NULL);
	evhttp *http = evhttp_new(base_server);
	ASSERT_TRUE(http != NULL);

	struct event_base *base_client = event_base_new();
	ASSERT_TRUE(base_client != NULL);
	struct evhttp_connection *connection = evhttp_connection_base_new(base_client, NULL, host.c_str(), port);
	ASSERT_TRUE(connection != NULL);
	boost::thread thrd1(&HttpServer, base_server, http);
	boost::thread thrd2(&HttpClient, base_client, connection);
	
	SLEEP(2000);
	stop = true;
	
	evhttp_free(http);
	event_base_loopbreak(base_server);
	event_base_free(base_server);
	
	
	evhttp_connection_free(connection);
	event_base_loopbreak(base_client);
	event_base_free(base_client);

	thrd1.join();
	thrd2.join();
}