package main

import (
	"encoding/json"
	"log"
	"net/http"
)

type Response struct {
	Message string `json:"message"`
}

func main() {
	http.HandleFunc("/", handleRequest)

	log.Println("Starting server on :8000")
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func handleRequest(w http.ResponseWriter, r *http.Request) {

	if r.Method == "GET" && r.URL.Path == "/" {
		resp := Response{
			Message: "Hello, from resilience on AWS",
		}

		w.Header().Set("Content-Type", "application/json")

		err := json.NewEncoder(w).Encode(resp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	} else {
		http.NotFound(w, r)
	}
}
