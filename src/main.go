package main

import (
	"crypto/tls"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
)

var (
	staticEnvFile   = "/secrets/static.env"
	databaseEnvFile = "/secrets/database.env"

	tlsCertFile = "/secrets/server.crt"
	tlsKeyFile  = "/secrets/server.key"
)

func loadEnvFiles() {
	// Load environment variables from dotenv files
	err := godotenv.Overload(staticEnvFile, databaseEnvFile)
	if err != nil {
		log.Fatalf("Error loading .env files: %v", err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	// Retrieve environment variables
	data := map[string]string{
		"foo":      os.Getenv("foo"),
		"fizz":     os.Getenv("fizz"),
		"ping":     os.Getenv("ping"),
		"hello":    os.Getenv("hello"),
		"username": os.Getenv("username"),
		"password": os.Getenv("password"),
	}

	// Set response header to application/json
	w.Header().Set("Content-Type", "application/json")

	// Create a new JSON encoder
	encoder := json.NewEncoder(w)

	// Set the prefix and indent for pretty printing
	encoder.SetIndent("", "  ")

	// Encode the environment variables as JSON and write to response
	if err := encoder.Encode(data); err != nil {
		http.Error(w, "Failed to encode JSON", http.StatusInternalServerError)
	}
}

func main() {
	// Load environment variables
	loadEnvFiles()

	// Set up HTTP server
	mux := http.NewServeMux()
	mux.HandleFunc("/", handler)

	// Configure HTTP server
	srv := &http.Server{
		Addr:    ":8000",
		Handler: mux,
		TLSConfig: &tls.Config{
			GetCertificate: func(*tls.ClientHelloInfo) (*tls.Certificate, error) {
				cert, err := tls.LoadX509KeyPair(tlsCertFile, tlsKeyFile)
				if err != nil {
					return nil, err
				}
				return &cert, nil
			},
		},
	}

	// Start the HTTP server
	go func() {
		log.Println("Starting server on :8000...")
		log.Fatal(srv.ListenAndServeTLS("", ""))
	}()

	// Handle SIGHUP signal to reload environment variables
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, os.Signal(syscall.SIGHUP))

	for {
		sig := <-sigs
		switch sig {
		case syscall.SIGHUP:
			log.Println("SIGHUP: reload environment variables...")
			loadEnvFiles()
		}
	}
}
