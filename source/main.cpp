#include <Common.h>

#ifdef _MSC_VER
#pragma comment(lib,"ws2_32.lib") 
#endif

int main(int argc, char* argv[])
{
#ifdef _WIN32
	WORD wVersionRequested;
	WSADATA wsaData;

	wVersionRequested = MAKEWORD(2, 2);
	(void)WSAStartup(wVersionRequested, &wsaData);
#endif

	//-----------------------------------
	//  Startup test
	//-----------------------------------
	testing::InitGoogleTest(&argc, argv);

	int result = RUN_ALL_TESTS();

// 	std::cout << "\n Test complete, press any key to exit!" << ::std::endl;
// 	getchar();

	return result;
}