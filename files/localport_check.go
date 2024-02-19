package main

import (
	"net"
	"time"
	"flag"
	"os"
)

func scanPort(protocol string, port string) int {
	address :=  "localhost:" + port
	conn, err := net.DialTimeout(protocol, address, 10*time.Second)

	if err != nil {
		return 1
	}
	defer conn.Close()
	return 0
}

func main() {
	port := flag.String("port", "9000", "check port number")
	protocol := flag.String("protocol", "tcp", "check protocol(tcp or udp)")
	flag.Parse()
	opend := scanPort(*protocol, *port)
	os.Exit(opend)
}