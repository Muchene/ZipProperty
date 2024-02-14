package main

import (
	"flag"
	"os"
	"zipserver/app"

	log "github.com/sirupsen/logrus"
)

func main() {
	logger := log.New()
	logger.SetFormatter(&log.TextFormatter{})
	logger.SetOutput(os.Stdout)
	logger.SetLevel(log.InfoLevel)
	logger.Info("Starting ZipServer")

	configPath := flag.String("config", "/opt/zipproperty/config.json", "Path to config file")
	flag.Parse()

	config, err := app.ConfigFromFile(*configPath)
	if err != nil {
		log.Fatal(err)
	}
	app := app.NewZipApp(logger, config)
	app.Run()
}
