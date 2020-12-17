#include <iostream>
#include <iomanip>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include "fdstream.hpp"

void write_msg(const std::string& outfile, const std::string& msg, int count)
{
    int fdout;

    fdout = open(outfile.c_str(), O_WRONLY | O_CREAT | O_TRUNC, S_IREAD | S_IWRITE );
    if (fdout == -1) {
        throw "open failed on output file";
    }
    std::cout << "open succeeded on output file\n";

    boost::fdostream out(fdout);
    for (int i = 0; i < count; i++) {
        out << std::left << std::setw(3) << i << msg << std::endl;
    }

    close (fdout);
}

int main()
{
    std::string outfile = "/tmp/tmp.out";
    try {
        std::cout << "low-level to " << outfile << std::endl;
        write_msg(outfile, "Message", 10);
    }
    catch (const char* s) {
        std::cerr << "EXCEPTION: " << s << std::endl;
    }
}
