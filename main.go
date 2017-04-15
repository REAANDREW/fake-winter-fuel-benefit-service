package main

import (
	"fmt"
	"net/http"

	"go.uber.org/zap"
)

var (
	//Version of the application
	Version string
	//BuildTime this application was compiled
	BuildTime string
	//CommitHash of git associated with the source of this compilation
	CommitHash string

	logger *zap.Logger
)

func main() {
	var err error

	logger, err = zap.NewProduction()

	if err != nil {
		panic(err)
	}

	logger = logger.With(zap.String("Version", Version))

	logger.Info("Starting",
		zap.String("BuildTime", BuildTime),
		zap.String("CommitHash", CommitHash),
	)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("Hello, World!")
	})

	logger.Info("Started")
	err = http.ListenAndServe(":8080", nil)
	if err != nil {
		panic(err)
	}
}
